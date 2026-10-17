import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/features/home/presentation/controllers/tool_session_controller.dart';

import 'controlled_repository.dart';
import 'fixtures.dart';

void main() {
  late ControlledRepository repo;
  late ToolSessionController controller;
  setUp(() {
    repo = ControlledRepository();
    controller = ToolSessionController(
      catalog: AppCatalog.catalog,
      repository: repo,
      now: () => clock,
    );
  });
  tearDown(() => controller.close());
  test(
    'read failure is visible, not an empty-success store; retry recovers',
    () async {
      repo.failRead = true;
      expect(await controller.initialize(), isFalse);
      expect(controller.isReady, isFalse);
      expect(controller.lastError, isNotNull);
      expect(controller.isBusy, isFalse);
      repo.failRead = false;
      expect(await controller.initialize(), isTrue);
      expect(controller.lastError, isNull);
    },
  );
  test(
    'write failures never optimistically mutate favorites or history',
    () async {
      await controller.initialize();
      repo.failWrite = true;
      expect(await controller.toggleFavorite('oee'), isFalse);
      expect(controller.favorites, isEmpty);
      expect(controller.lastError, contains('ذخیره'));
      expect(await controller.record('oee', input, result), isFalse);
      expect(controller.recent, isEmpty);
      repo.failWrite = false;
      expect(await controller.record('oee', input, result), isTrue);
      expect(controller.lastError, isNull);
    },
  );
  test(
    'busy state lasts until durable commit and exposes only committed snapshot',
    () async {
      await controller.initialize();
      repo.gate = Completer<void>();
      final future = controller.toggleFavorite('oee');
      await Future<void>.delayed(Duration.zero);
      expect(controller.isBusy, isTrue);
      expect(controller.favorites, isEmpty);
      repo.gate!.complete();
      expect(await future, isTrue);
      expect(controller.isBusy, isFalse);
      expect(controller.favorites, {'oee'});
    },
  );
  test(
    'rapid queued writes have deterministic tap order and survive failures',
    () async {
      await controller.initialize();
      await Future.wait([
        for (var i = 0; i < 21; i++) controller.toggleFavorite('oee'),
      ]);
      expect(controller.favorites, {'oee'});
      await Future.wait([
        for (var i = 0; i < 15; i++) controller.record('oee', input, result),
      ]);
      expect(
        controller.recent.map((r) => r.sequence),
        List.generate(10, (i) => 15 - i),
      );
    },
  );
  test('closed and uninitialized controllers reject actions', () async {
    expect(() => controller.toggleFavorite('oee'), throwsStateError);
    await controller.initialize();
    await controller.close();
    expect(() => controller.record('oee', input, result), throwsStateError);
    expect(await controller.initialize(), isFalse);
  });
  test('retired catalog IDs are hidden without deleting stored data', () async {
    await repo.inner.toggleFavorite('retired_tool', clock);
    await repo.inner.record('retired_tool', input, result, clock);
    expect(await controller.initialize(), isTrue);
    expect(controller.favorites, isEmpty);
    expect(controller.recent, isEmpty);
    final stored = await repo.inner.load();
    expect(stored.favorites, {'retired_tool'});
    expect(stored.recent, hasLength(1));
  });
  test('disposing during an active write safely closes after completion and never notifies disposed listeners', () async {
    await controller.initialize();
    repo.gate = Completer<void>();
    final pending = controller.toggleFavorite('oee');
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    repo.gate!.complete();
    expect(await pending, isFalse);
    await controller.close();
    expect(repo.closed, isTrue);
  });
}
