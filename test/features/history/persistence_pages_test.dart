import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/core/storage/toolbox_database.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import 'controlled_repository.dart';

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String id, String text) async {
  final target = find.byKey(Key('input-$id'));
  await tester.ensureVisible(target);
  await tester.enterText(target, text);
  await tester.pumpAndSettle();
}

Future<void> start(WidgetTester tester, DriftToolRepository repo) async {
  await tester.pumpWidget(ManagementToolboxApp(repository: repo));
  await tester.pumpAndSettle();
  await tap(tester, find.text('ورود به برنامه'));
}

String primary(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const Key('primary-result')))
    .data!;
void main() {
  testWidgets(
    'actual SQLite file retains favorite and exact saved inputs through app shutdown/reopen',
    (tester) async {
      final directory = Directory.systemTemp.createTempSync(
        'toolbox-app-restart-',
      );
      addTearDown(() => directory.deleteSync(recursive: true));
      final file = File('${directory.path}/app.sqlite');
      var repo = DriftToolRepository(
        ToolboxDatabase.file(file, background: false),
      );
      await start(tester, repo);
      await tap(tester, find.byKey(const Key('available-favorite-oee')));
      await tap(tester, find.byKey(const Key('favorite-tool-oee')));
      await enter(tester, 'availability', '50');
      expect(primary(tester), '۴۶٫۵۵٪');
      await tester.tap(find.byKey(const Key('calculator-save')));
      await tester.pumpAndSettle();
      expect(find.text('محاسبه در تاریخچهٔ محلی ذخیره شد.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await repo.close();
      repo = DriftToolRepository(ToolboxDatabase.file(file, background: false));
      await start(tester, repo);
      expect(find.byKey(const Key('favorite-tool-oee')), findsOneWidget);
      await tap(tester, find.byKey(const Key('recent-1-tool-oee')));
      expect(primary(tester), '۴۶٫۵۵٪');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-availability')))
            .controller!
            .text,
        '50',
      );
      await tester.tap(find.byKey(const Key('calculator-favorite')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await repo.close();
      repo = DriftToolRepository(ToolboxDatabase.file(file, background: false));
      final snapshot = await repo.load();
      expect(snapshot.favorites, isEmpty);
      expect(snapshot.recent, hasLength(1));
      await repo.close();
    },
  );
  testWidgets(
    'startup read failure blocks false empty state and retry opens the same stored data',
    (tester) async {
      final repo = ControlledRepository()..failRead = true;
      await tester.pumpWidget(ManagementToolboxApp(repository: repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('storage-startup-error')), findsOneWidget);
      expect(find.text('ورود به برنامه'), findsNothing);
      repo.failRead = false;
      await tap(tester, find.byKey(const Key('storage-retry')));
      expect(find.text('ورود به برنامه'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await repo.close();
    },
  );
  testWidgets('failed save reports error, not success; retry commits once', (
    tester,
  ) async {
    final repo = ControlledRepository();
    await tester.pumpWidget(ManagementToolboxApp(repository: repo));
    await tester.pumpAndSettle();
    await tap(tester, find.text('ورود به برنامه'));
    await tap(tester, find.byKey(const Key('available-tool-oee')));
    repo.failWrite = true;
    await tester.tap(find.byKey(const Key('calculator-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calculator-storage-error')), findsOneWidget);
    expect(find.text('محاسبه در تاریخچهٔ محلی ذخیره شد.'), findsNothing);
    expect((await repo.inner.load()).recent, isEmpty);
    repo.failWrite = false;
    await tester.tap(find.byKey(const Key('calculator-save')));
    await tester.pumpAndSettle();
    expect((await repo.inner.load()).recent, hasLength(1));
    expect(find.byKey(const Key('calculator-storage-error')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await repo.close();
  });
  testWidgets(
    'tap-time snapshot never pairs stale result with newly edited or invalid input',
    (tester) async {
      final repo = DriftToolRepository.memory();
      await start(tester, repo);
      await tap(tester, find.byKey(const Key('available-tool-oee')));
      final action = tester
          .widget<IconButton>(find.byKey(const Key('calculator-save')))
          .onPressed!;
      final field = find.byKey(const Key('input-availability'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, '');
      action();
      await tester.pumpAndSettle();
      expect((await repo.load()).recent, isEmpty);
      await tester.enterText(field, '50');
      action();
      await tester.pumpAndSettle();
      final saved = (await repo.load()).recent.single;
      expect((saved.inputs.values['availability'] as RawTextInput).text, '50');
      expect(
        (saved.result.primary.value as NumericResultValue).value,
        closeTo(0.4655, 1e-12),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await repo.close();
    },
  );
}
