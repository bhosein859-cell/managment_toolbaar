import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/finance_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/irr_engine.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import '../presentation/fixtures.dart';

const expectedResults = {
  'npv': '۴۱٫۳۲۲۳۱۴ ریال',
  'irr': '۱۳٫۰۶۶۲۳۹٪',
  'payback': '۲٫۶ دوره',
  'roi': '۲۰٪',
  'current_ratio': '۲ برابر',
  'quick_ratio': '۱٫۹ برابر',
  'wacc': '۹٫۶٪',
  'compound_interest': '۱۲۱۰ ریال',
  'loan_payment': '۸۸٫۸۴۸۷۸۹ ریال/قسط',
  'break_even': '۲۵۰ واحد',
};
const invalidInputs = {
  'irr': ('cash_flows', '100\n100'),
  'payback': ('initial_investment', '-1'),
  'roi': ('investment', '0'),
  'current_ratio': ('current_liabilities', '0'),
  'quick_ratio': ('current_liabilities', '0'),
  'wacc': ('tax_rate', '101'),
  'compound_interest': ('period_rate', '-100'),
  'loan_payment': ('periods', '0'),
  'break_even': ('unit_price', '6'),
};
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
  for (final runner in FinanceCalculators.runners.skip(1)) {
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
        expect(result(tester), expectedResults[definition.id]);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('ten finance tools open through real category routes', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(tester, find.byKey(const Key('category-finance')));
    expect(find.text('۱۰ ابزار قابل استفاده'), findsOneWidget);
    for (final runner in FinanceCalculators.runners) {
      final id = runner.definition.id;
      await tapVisible(tester, find.byKey(Key('category-tool-$id')));
      expect(result(tester), expectedResults[id]);
      expect(find.byKey(const Key('calculator-save')), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'IRR missing root ambiguous roots and convergence failure show no stale result',
    (tester) async {
      await tester.pumpWidget(host(FinanceCalculators.irrRunner));
      await tester.pumpAndSettle();
      await edit(tester, 'cash_flows', '100\n50');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(find.textContaining('ریشه ندارد'), findsOneWidget);
      await edit(tester, 'cash_flows', '-100\n230\n-132');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(find.textContaining('یک جواب انتخابی'), findsOneWidget);
      await edit(tester, 'cash_flows', '-100\n110');
      expect(result(tester), '۱۰٪');
      final limited = CalculatorRunner(
        definition: FinanceCalculators.irr,
        engine: const IrrEngine(maxIterations: 1),
      );
      await tester.pumpWidget(host(limited));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(find.textContaining('همگرا نشد'), findsOneWidget);
    },
  );
  testWidgets('new loan favorite save and reopen keep period-rate input', (
    tester,
  ) async {
    await start(tester);
    await tester.enterText(find.byKey(const Key('home-search')), 'PMT');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('search-tool-loan_payment')));
    await edit(tester, 'periods', '0');
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('calculator-save')))
          .onPressed,
      isNull,
    );
    await edit(tester, 'periods', '12');
    await edit(tester, 'period_rate', '0');
    expect(result(tester), '۸۳٫۳۳۳۳۳۳ ریال/قسط');
    await tester.tap(find.byKey(const Key('calculator-favorite')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calculator-save')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('پاک کردن جستجو'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorite-tool-loan_payment')), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const Key('recent-1-tool-loan_payment')),
    );
    expect(result(tester), '۸۳٫۳۳۳۳۳۳ ریال/قسط');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('input-period_rate')))
          .controller!
          .text,
      '0',
    );
  });
  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets('nine finance pages fit $size dark=$dark enlarged RTL', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        for (final runner in FinanceCalculators.runners.skip(1)) {
          await tester.pumpWidget(host(runner, dark: dark));
          await tester.pumpAndSettle();
          expect(result(tester), expectedResults[runner.definition.id]);
          await tester.ensureVisible(find.text('تفسیر'));
          await tester.pumpAndSettle();
          expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
          expect(tester.takeException(), isNull, reason: runner.definition.id);
        }
      });
    }
  }
}
