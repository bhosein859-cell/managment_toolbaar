import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/core/storage/toolbox_database.dart';
import 'package:management_toolbox/features/history/data/calculation_snapshot_codec.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';
import 'package:sqlite3/sqlite3.dart';

import 'fixtures.dart';

void main() {
  late Directory directory;
  late File file;
  setUp(() {
    directory = Directory.systemTemp.createTempSync('toolbox-migration-');
    file = File('${directory.path}/data.sqlite');
  });
  tearDown(() => directory.deleteSync(recursive: true));
  void seedV1({int count = 15}) {
    final db = sqlite3.open(file.path);
    db.execute(File('test/fixtures/storage/schema_v1.sql').readAsStringSync());
    db.execute('INSERT INTO favorites VALUES (?,?)', [
      'oee',
      clock.microsecondsSinceEpoch,
    ]);
    for (var i = 0; i < count; i++) {
      db.execute(
        'INSERT INTO calculation_history(calculator_id,inputs_json,result_json,created_at_micros) VALUES (?,?,?,?)',
        [
          'oee',
          CalculationSnapshotCodec.encodeInputs(input),
          CalculationSnapshotCodec.encodeResult(result),
          clock.microsecondsSinceEpoch,
        ],
      );
    }
    db.close();
  }

  List<Object?> schema(Database db) => [
    for (final table in ['favorites', 'calculation_history'])
      db
          .select('PRAGMA table_info($table)')
          .map((r) => r.values.toList())
          .toList(),
    db
        .select(
          "SELECT name FROM sqlite_master WHERE type='trigger' ORDER BY name",
        )
        .map((r) => r['name'])
        .toList(),
  ];
  test(
    'fresh schema matches independent v2 fixture and required constraints',
    () async {
      final repo = DriftToolRepository(
        ToolboxDatabase.file(file, background: false),
      );
      await repo.load();
      await repo.close();
      final actual = sqlite3.open(file.path), expected = sqlite3.openInMemory();
      expected.execute(
        File('test/fixtures/storage/schema_v2.sql').readAsStringSync(),
      );
      expect(schema(actual), schema(expected));
      expect(actual.select('PRAGMA user_version').single.values.single, 2);
      expect(
        () => actual.execute("INSERT INTO favorites VALUES ('',0)"),
        throwsA(anything),
      );
      expect(
        () => actual.execute(
          "INSERT INTO calculation_history(calculator_id,inputs_json,result_json,created_at_micros,payload_version) VALUES ('oee','{}','{}',0,0)",
        ),
        throwsA(anything),
      );
      actual.close();
      expected.close();
    },
  );
  test('v1 to v2 preserves favorites/payloads/timestamps, prunes oldest five atomically', () async {
    seedV1();
    final before = sqlite3.open(file.path),
        expectedRaw = before
            .select(
              'SELECT inputs_json,result_json FROM calculation_history WHERE id=15',
            )
            .single
            .values
            .toList();
    before.close();
    final repo = DriftToolRepository(
      ToolboxDatabase.file(file, background: false),
    );
    final s = await repo.load();
    expect(s.favorites, {'oee'});
    expect(s.recent.map((r) => r.sequence), List.generate(10, (i) => 15 - i));
    expect(s.recent.first.createdAt, clock);
    await repo.close();
    final actual = sqlite3.open(file.path), expected = sqlite3.openInMemory();
    expected.execute(
      File('test/fixtures/storage/schema_v2.sql').readAsStringSync(),
    );
    expect(schema(actual), schema(expected));
    expect(actual.select('PRAGMA user_version').single.values.single, 2);
    expect(
      actual
          .select('SELECT DISTINCT payload_version FROM calculation_history')
          .single
          .values
          .single,
      1,
    );
    expect(
      actual
          .select(
            'SELECT inputs_json,result_json FROM calculation_history WHERE id=15',
          )
          .single
          .values
          .toList(),
      expectedRaw,
    );
    actual.close();
    expected.close();
  });
  for (final count in [0, 1, 10, 11]) {
    test('v1 migration with $count rows retains min(count,10)', () async {
      seedV1(count: count);
      final repo = DriftToolRepository(
        ToolboxDatabase.file(file, background: false),
      );
      expect((await repo.load()).recent.length, count > 10 ? 10 : count);
      await repo.close();
    });
  }
  test(
    'already-current reopen is idempotent and IDs continue after migration',
    () async {
      seedV1();
      var repo = DriftToolRepository(
        ToolboxDatabase.file(file, background: false),
      );
      await repo.load();
      await repo.close();
      repo = DriftToolRepository(ToolboxDatabase.file(file, background: false));
      expect(
        (await repo.record('oee', input, result, clock)).recent.first.sequence,
        16,
      );
      await repo.close();
    },
  );
  test(
    'retention invariant is enforced for direct SQLite writers too',
    () async {
      final repo = DriftToolRepository(
        ToolboxDatabase.file(file, background: false),
      );
      await repo.load();
      await repo.close();
      final db = sqlite3.open(file.path);
      for (var i = 0; i < 25; i++) {
        db.execute(
          'INSERT INTO calculation_history(calculator_id,inputs_json,result_json,created_at_micros) VALUES (?,?,?,?)',
          [
            'oee',
            CalculationSnapshotCodec.encodeInputs(input),
            CalculationSnapshotCodec.encodeResult(result),
            0,
          ],
        );
      }
      expect(
        db
            .select('SELECT id FROM calculation_history ORDER BY id')
            .map((r) => r['id']),
        List.generate(10, (i) => 16 + i),
      );
      db.close();
    },
  );
  test('failed migration rolls back ALTER, retention and version without deleting data', () async {
    seedV1();
    final old = sqlite3.open(file.path);
    old.execute(
      'CREATE TRIGGER history_keep_ten AFTER INSERT ON favorites BEGIN SELECT 1; END',
    );
    old.close();
    final repo = DriftToolRepository(
      ToolboxDatabase.file(file, background: false),
    );
    await expectLater(repo.load(), throwsA(anything));
    await repo.close();
    final db = sqlite3.open(file.path);
    expect(db.select('PRAGMA user_version').single.values.single, 1);
    expect(
      db.select('PRAGMA table_info(calculation_history)').map((r) => r['name']),
      isNot(contains('payload_version')),
    );
    expect(
      db.select('SELECT count(*) AS n FROM calculation_history').single['n'],
      15,
    );
    expect(
      db.select('SELECT calculator_id FROM favorites').single['calculator_id'],
      'oee',
    );
    db.close();
  });
  test('newer database is refused, never downgraded or recreated', () async {
    seedV1(count: 1);
    final old = sqlite3.open(file.path);
    old.execute('PRAGMA user_version=99');
    old.close();
    final repo = DriftToolRepository(
      ToolboxDatabase.file(file, background: false),
    );
    await expectLater(repo.load(), throwsA(anything));
    await repo.close();
    final db = sqlite3.open(file.path);
    expect(db.select('PRAGMA user_version').single.values.single, 99);
    expect(
      db.select('SELECT count(*) AS n FROM calculation_history').single['n'],
      1,
    );
    db.close();
  });
  test(
    'corrupt file is not deleted or silently replaced with an empty database',
    () async {
      file.writeAsStringSync('not a sqlite database');
      final bytes = file.readAsBytesSync();
      final repo = DriftToolRepository(
        ToolboxDatabase.file(file, background: false),
      );
      await expectLater(repo.load(), throwsA(anything));
      await repo.close();
      expect(file.readAsBytesSync(), bytes);
    },
  );
}
