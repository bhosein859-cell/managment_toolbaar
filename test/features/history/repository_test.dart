import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/core/storage/toolbox_database.dart';
import 'package:management_toolbox/features/history/data/calculation_snapshot_codec.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';
import 'package:management_toolbox/features/history/domain/tool_repository.dart';

import 'fixtures.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
  late DriftToolRepository repo;
  setUp(() => repo = DriftToolRepository.memory());
  tearDown(() => repo.close());
  test('fresh SQLite has no fabricated favorites or history', () async {
    final s = await repo.load();
    expect(s.favorites, isEmpty);
    expect(s.recent, isEmpty);
  });
  test('favorite add/remove is idempotent as toggle parity, primary key prevents duplicates', () async {
    expect((await repo.toggleFavorite('oee', clock)).favorites, {'oee'});
    expect((await repo.toggleFavorite('npv', clock)).favorites, {'oee', 'npv'});
    expect((await repo.toggleFavorite('oee', clock)).favorites, {'npv'});
    await expectLater(
      repo.database.customStatement('INSERT INTO favorites VALUES (?,?)', [
        'npv',
        0,
      ]),
      throwsA(anything),
    );
    expect((await repo.load()).favorites, {'npv'});
  });
  test(
    'favorite identity validation prevents arbitrary SQL or empty names',
    () async {
      for (final id in ['', "oee'; DROP TABLE favorites;--", 'x' * 129]) {
        expect(() => repo.toggleFavorite(id, clock), throwsArgumentError);
        expect(
          () => repo.record(id, input, result, clock),
          throwsArgumentError,
        );
      }
      expect((await repo.load()).favorites, isEmpty);
    },
  );
  test('one through eleven inserts retain exactly min(count,10), same timestamps do not collide', () async {
    for (var i = 1; i <= 11; i++) {
      final s = await repo.record('oee', input, result, clock);
      expect(s.recent.length, i < 10 ? i : 10);
      expect(s.recent.first.sequence, i);
      expect(s.recent.last.sequence, i <= 10 ? 1 : 2);
    }
    final rows = await repo.database
        .customSelect('SELECT id FROM calculation_history ORDER BY id')
        .get();
    expect(rows.map((r) => r.read<int>('id')), List.generate(10, (i) => i + 2));
  });
  test(
    'history cap is global across calculators, not ten per calculator',
    () async {
      for (var i = 0; i < 23; i++) {
        await repo.record(i.isEven ? 'oee' : 'npv', input, result, clock);
      }
      final s = await repo.load();
      expect(s.recent.map((r) => r.sequence), List.generate(10, (i) => 23 - i));
      expect(s.recent.map((r) => r.calculatorId).toSet(), {'oee', 'npv'});
    },
  );
  test('insertion sequence determines recent order even if system clock moves backward', () async {
    await repo.record('oee', input, result, clock);
    await repo.record(
      'npv',
      input,
      result,
      clock.subtract(const Duration(days: 10)),
    );
    final s = await repo.load();
    expect(s.recent.first.calculatorId, 'npv');
    expect(s.recent.first.createdAt, clock.subtract(const Duration(days: 10)));
  });
  test('rapid concurrent inserts on one Drift connection are serialized and retain final ten', () async {
    await Future.wait([
      for (var i = 0; i < 35; i++) repo.record('oee', input, result, clock),
    ]);
    final s = await repo.load();
    expect(s.recent.map((r) => r.sequence), List.generate(10, (i) => 35 - i));
  });
  test('rapid concurrent toggles preserve parity and uniqueness', () async {
    await Future.wait([
      for (var i = 0; i < 11; i++) repo.toggleFavorite('oee', clock),
    ]);
    expect((await repo.load()).favorites, {'oee'});
    await Future.wait([
      for (var i = 0; i < 10; i++) repo.toggleFavorite('oee', clock),
    ]);
    expect((await repo.load()).favorites, {'oee'});
  });
  test(
    'snapshot is immutable and retains exact text/result/timestamp',
    () async {
      final s = await repo.record('oee', input, result, clock),
          r = s.recent.single;
      expect(r.createdAt, clock);
      expect(
        CalculationSnapshotCodec.encodeInputs(r.inputs),
        CalculationSnapshotCodec.encodeInputs(input),
      );
      expect(
        CalculationSnapshotCodec.encodeResult(r.result),
        CalculationSnapshotCodec.encodeResult(result),
      );
      expect(() => s.favorites.clear(), throwsUnsupportedError);
      expect(() => s.recent.clear(), throwsUnsupportedError);
    },
  );
  test('failed retention delete rolls back insertion, pruning and autoincrement sequence', () async {
    for (var i = 0; i < 10; i++) {
      await repo.record('oee', input, result, clock);
    }
    await repo.database.customStatement(
      "CREATE TRIGGER simulate_disk_failure BEFORE DELETE ON calculation_history BEGIN SELECT RAISE(ABORT,'simulated storage failure'); END",
    );
    await expectLater(
      repo.record('oee', input, result, clock),
      throwsA(anything),
    );
    expect(
      (await repo.load()).recent.map((r) => r.sequence),
      List.generate(10, (i) => 10 - i),
    );
    await repo.database.customStatement('DROP TRIGGER simulate_disk_failure');
    expect(
      (await repo.record('oee', input, result, clock)).recent.first.sequence,
      11,
    );
  });
  test('failed favorite write is not reported as committed', () async {
    await repo.database.customStatement(
      "CREATE TRIGGER simulate_write_failure BEFORE INSERT ON favorites BEGIN SELECT RAISE(ABORT,'failure'); END",
    );
    await expectLater(repo.toggleFavorite('oee', clock), throwsA(anything));
    expect((await repo.load()).favorites, isEmpty);
  });
  test('unknown payload versions and malformed JSON fail read without resetting DB', () async {
    await repo.record('oee', input, result, clock);
    await repo.database.customStatement(
      'UPDATE calculation_history SET payload_version = 999',
    );
    await expectLater(repo.load(), throwsA(isA<StorageReadException>()));
    await repo.database.customStatement(
      "UPDATE calculation_history SET payload_version = 1, inputs_json = '{broken'",
    );
    await expectLater(repo.load(), throwsA(isA<StorageReadException>()));
    final count = await repo.database
        .customSelect('SELECT count(*) AS n FROM calculation_history')
        .getSingle();
    expect(count.read<int>('n'), 1);
  });
  test('failed snapshot decode rolls back favorite changes as well', () async {
    await repo.record('oee', input, result, clock);
    await repo.database.customStatement(
      'UPDATE calculation_history SET result_json = ?',
      ['[]'],
    );
    await expectLater(
      repo.toggleFavorite('oee', clock),
      throwsA(isA<StorageReadException>()),
    );
    final rows = await repo.database
        .customSelect('SELECT * FROM favorites')
        .get();
    expect(rows, isEmpty);
  });
  test(
    'close is safe twice and does not silently reopen a closed repository',
    () async {
      await repo.load();
      await repo.close();
      await repo.close();
      await expectLater(repo.load(), throwsA(anything));
    },
  );
  test('file survives close/reopen, history evictions persist and IDs are not reused', () async {
    final directory = Directory.systemTemp.createTempSync('toolbox-persist-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/toolbox.sqlite');
    var disk = DriftToolRepository(
      ToolboxDatabase.file(file, background: false),
    );
    await disk.toggleFavorite('oee', clock);
    for (var i = 0; i < 11; i++) {
      await disk.record('oee', input, result, clock);
    }
    await disk.close();
    disk = DriftToolRepository(ToolboxDatabase.file(file, background: false));
    final saved = await disk.load();
    expect(saved.favorites, {'oee'});
    expect(
      saved.recent.map((r) => r.sequence),
      List.generate(10, (i) => 11 - i),
    );
    expect(saved.recent.first.createdAt, clock);
    expect(
      (await disk.record('npv', input, result, clock)).recent.first.sequence,
      12,
    );
    await disk.toggleFavorite('oee', clock);
    await disk.close();
    disk = DriftToolRepository(ToolboxDatabase.file(file, background: false));
    expect((await disk.load()).favorites, isEmpty);
    await disk.close();
  });
  test('separate background isolate connection persists actual file', () async {
    final directory = Directory.systemTemp.createTempSync('toolbox-isolate-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/toolbox.sqlite');
    var disk = DriftToolRepository(ToolboxDatabase.file(file));
    await disk.toggleFavorite('npv', clock);
    await disk.record('oee', input, result, clock);
    await disk.close();
    disk = DriftToolRepository(ToolboxDatabase.file(file));
    expect((await disk.load()).favorites, {'npv'});
    expect((await disk.load()).recent, hasLength(1));
    await disk.close();
  });
  test(
    'unwritable path fails explicitly rather than fallback to memory',
    () async {
      final directory = Directory.systemTemp.createTempSync('toolbox-invalid-');
      addTearDown(() => directory.deleteSync(recursive: true));
      File('${directory.path}/blocker').writeAsStringSync('not a directory');
      final disk = DriftToolRepository(
        ToolboxDatabase.file(
          File('${directory.path}/blocker/db.sqlite'),
          background: false,
        ),
      );
      await expectLater(disk.load(), throwsA(anything));
      await disk.close();
      expect(
        File('${directory.path}/blocker').readAsStringSync(),
        'not a directory',
      );
    },
  );
}
