import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/inventory_calculators.dart';
import 'package:management_toolbox/app/catalog/quality_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import '../presentation/fixtures.dart';

const expectedResults = {
  'cp': '۱٫۶۶۶۶۶۷',
  'cpk': '۱',
  'pp': '۰٫۵',
  'ppk': '۰٫۳۳۳۳۳۳',
  'dpmo': '۱۰۰۰ نقص/میلیون فرصت',
  'sigma_level': '۳٫۰۹۰۲۳۲',
  'xbar_control': '۱۱ واحد مشترک',
  'coq': '۱۰۰۰ ریال/بازه',
  'eoq': '۱۰۰۰ واحد/سفارش',
  'rop': '۲۵۰ واحد',
  'safety_stock': '۳۲٫۸۹۷۰۷۳ واحد',
  'abc': '۱۰۰۰۰ ریال/سال',
  'inventory_turnover': '۴ بار/دوره',
  'days_inventory': '۹۱٫۲۵ روز',
  'inventory_holding_cost': '۵۰۰۰۰ ریال/دوره',
  'reorder_interval': '۳۰ روز/سفارش',
};
const invalidInputs = {
  'cp': ('sigma', '0'),
  'cpk': ('sigma', '0'),
  'pp': ('sigma', '0'),
  'ppk': ('sigma', '0'),
  'dpmo': ('defects', '10001'),
  'sigma_level': ('dpmo', '0'),
  'xbar_control': ('observations', '1\n1\n1\n1\n1\n1\n1\n1\n1\n1'),
  'coq': ('prevention', '-1'),
  'eoq': ('holding_cost', '0'),
  'rop': ('lead_time', '-1'),
  'safety_stock': ('service_level', '100'),
  'abc': ('unit_costs', '1'),
  'inventory_turnover': ('average_inventory', '0'),
  'days_inventory': ('cogs', '0'),
  'inventory_holding_cost': ('year_days', '0'),
  'reorder_interval': ('annual_demand', '0'),
};
final allRunners = [
  ...QualityCalculators.runners,
  ...InventoryCalculators.runners,
];
String result(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const Key('primary-result')))
    .data!;
Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> edit(WidgetTester tester, String id, String value) async {
  final target = find.byKey(Key('input-$id'));
  await tester.ensureVisible(target);
  await tester.enterText(target, value);
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
  for (final runner in allRunners) {
    final definition = runner.definition;
    testWidgets(
      '${definition.id}: generic form rendered formula error and example',
      (tester) async {
        await tester.pumpWidget(host(runner));
        await tester.pumpAndSettle();
        expect(
          find.byType(CalculatorPage<CalculatorParameters>),
          findsOneWidget,
        );
        expect(result(tester), expectedResults[definition.id]);
        expect(find.text(definition.assumptions), findsWidgets);
        expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
        final (id, bad) = invalidInputs[definition.id]!;
        await edit(tester, id, bad);
        expect(find.byKey(const Key('primary-result')), findsNothing);
        await tapVisible(tester, find.byKey(const Key('load-example-0')));
        expect(
          result(tester),
          definition.id == 'cp' ? '۱' : expectedResults[definition.id],
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final (category, runners) in [
    ('quality', QualityCalculators.runners),
    ('inventory', InventoryCalculators.runners),
  ]) {
    testWidgets('eight $category tools open through real routes', (
      tester,
    ) async {
      await start(tester);
      await tapVisible(tester, find.byKey(Key('category-$category')));
      expect(find.text('۸ ابزار قابل استفاده'), findsOneWidget);
      for (final runner in runners) {
        await tapVisible(
          tester,
          find.byKey(Key('category-tool-${runner.definition.id}')),
        );
        expect(result(tester), expectedResults[runner.definition.id]);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Sigma convention is explicit and endpoints clear stale result', (
    tester,
  ) async {
    await tester.pumpWidget(host(QualityCalculators.sigmaLevelRunner));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('input-shift')));
    await tapVisible(tester, find.text('افزودن قرارداد ۱٫۵').last);
    expect(result(tester), '۴٫۵۹۰۲۳۲');
    await edit(tester, 'dpmo', '1000000');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('load-example-0')));
    expect(result(tester), '۳٫۰۹۰۲۳۲');
  });
  testWidgets(
    'ABC paired inputs and thresholds save and reopen through history',
    (tester) async {
      await start(tester);
      await tapVisible(tester, find.byKey(const Key('category-inventory')));
      await tapVisible(tester, find.byKey(const Key('category-tool-abc')));
      await edit(tester, 'unit_costs', '1');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('calculator-save')))
            .onPressed,
        isNull,
      );
      await tapVisible(tester, find.byKey(const Key('load-example-0')));
      await edit(tester, 'a_threshold', '70');
      expect(result(tester), '۱۰۰۰۰ ریال/سال');
      await tester.tap(find.byKey(const Key('calculator-save')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.byKey(const Key('recent-1-tool-abc')));
      expect(result(tester), '۱۰۰۰۰ ریال/سال');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-a_threshold')))
            .controller!
            .text,
        '70',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-unit_costs')))
            .controller!
            .text,
        contains('70'),
      );
    },
  );
  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets(
        'sixteen quality/inventory pages fit $size dark=$dark enlarged RTL',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          for (final runner in allRunners) {
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
