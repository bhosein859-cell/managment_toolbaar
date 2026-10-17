import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/production_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import '../presentation/fixtures.dart';

const expectedResults = {
  'oee': '۸۳٫۷۹٪',
  'takt_time': '۲ دقیقه/واحد',
  'production_capacity': '۴۸۰ واحد/بازه',
  'labor_productivity': '۸ واحد سالم/نفرساعت',
  'cycle_time': '۲ دقیقه/واحد',
  'smed': '۶۶٫۶۶۶۶۶۷٪',
  'unit_production_cost': '۳۰۰۰ ریال/واحد سالم',
  'wip': '۶۰ واحد متوسط',
  'throughput': '۳۰ واحد سالم/ساعت',
  'capacity_utilization': '۷۵٪',
};
String result(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const Key('primary-result')))
    .data!;
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> start(WidgetTester tester) async {
  await tester.pumpWidget(
    ManagementToolboxApp(repository: DriftToolRepository.memory()),
  );
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('ورود به برنامه'));
}

void main() {
  for (final runner in ProductionCalculators.runners.skip(1)) {
    final definition = runner.definition;
    testWidgets(
      '${definition.id}: uses generated generic page, validates and restores example',
      (tester) async {
        await tester.pumpWidget(host(runner));
        await tester.pumpAndSettle();
        expect(
          find.byType(CalculatorPage<CalculatorParameters>),
          findsOneWidget,
        );
        expect(result(tester), expectedResults[definition.id]);
        expect(find.text(definition.assumptions), findsOneWidget);
        expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
        final positiveField = definition.fields
            .cast<NumericFieldDefinition>()
            .firstWhere((f) => f.min == null || f.integerOnly);
        final field = find.byKey(Key('input-${positiveField.id}'));
        await tester.ensureVisible(field);
        await tester.enterText(field, '0');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('primary-result')), findsNothing);
        await tapVisible(tester, find.byKey(const Key('load-example-0')));
        expect(result(tester), expectedResults[definition.id]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'all ten tools open from production category through public routing',
    (tester) async {
      await start(tester);
      await tapVisible(tester, find.byKey(const Key('category-production')));
      expect(find.text('۱۰ ابزار قابل استفاده'), findsOneWidget);
      for (final runner in ProductionCalculators.runners) {
        final id = runner.definition.id;
        await tapVisible(tester, find.byKey(Key('category-tool-$id')));
        expect(result(tester), expectedResults[id]);
        expect(find.byKey(const Key('calculator-favorite')), findsOneWidget);
        expect(find.byKey(const Key('calculator-save')), findsOneWidget);
        expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new tool search favorite and history reopen keep edited inputs',
    (tester) async {
      await start(tester);
      final search = find.byKey(const Key('home-search'));
      await tester.enterText(search, 'تاکت تایم');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('search-tool-takt_time')));
      final demand = find.byKey(const Key('input-demand'));
      await tester.ensureVisible(demand);
      await tester.enterText(demand, '0');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('calculator-save')))
            .onPressed,
        isNull,
      );
      await tester.enterText(demand, '420');
      await tester.pumpAndSettle();
      expect(result(tester), '۱ دقیقه/واحد');
      await tester.tap(find.byKey(const Key('calculator-favorite')));
      await tester.pumpAndSettle();
      expect(result(tester), '۱ دقیقه/واحد');
      await tester.tap(find.byKey(const Key('calculator-save')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('پاک کردن جستجو'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorite-tool-takt_time')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const Key('recent-1-tool-takt_time')),
      );
      expect(result(tester), '۱ دقیقه/واحد');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-demand')))
            .controller!
            .text,
        '420',
      );
    },
  );

  testWidgets(
    'SMED increase and utilization above 100 remain visible with warnings',
    (tester) async {
      await tester.pumpWidget(host(ProductionCalculators.smedRunner));
      await tester.pumpAndSettle();
      var field = find.byKey(const Key('input-after_time'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '90');
      await tester.pumpAndSettle();
      expect(result(tester), '-۵۰٪');
      expect(find.textContaining('کاهش منفی گزارش شد'), findsOneWidget);
      await tester.pumpWidget(
        host(ProductionCalculators.capacityUtilizationRunner),
      );
      await tester.pumpAndSettle();
      field = find.byKey(const Key('input-actual_output'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '720');
      await tester.pumpAndSettle();
      expect(result(tester), '۱۵۰٪');
      expect(
        find.textContaining('خروجی از ظرفیت اسمی بیشتر است'),
        findsOneWidget,
      );
    },
  );

  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets(
        'nine new generic pages fit $size dark=$dark text scale 1.5',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          for (final runner in ProductionCalculators.runners.skip(1)) {
            await tester.pumpWidget(host(runner, dark: dark));
            await tester.pumpAndSettle();
            expect(result(tester), expectedResults[runner.definition.id]);
            await tester.ensureVisible(find.text('تفسیر'));
            await tester.pumpAndSettle();
            expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
            expect(
              tester.takeException(),
              isNull,
              reason: runner.definition.id,
            );
          }
        },
      );
    }
  }
}
