import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/hr_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import '../presentation/fixtures.dart';

const expectedResults = {
  'cost_per_hire': '۱۰۰۰۰۰۰۰ ریال/جذب',
  'employee_turnover': '۵٪',
  'employee_productivity': '۵ واحد خروجی/نفرساعت',
  'training_roi': '۱۰۰٪',
  'replacement_time': '۳۰ روز/جایگزینی',
  'absence_cost': '۲۲۰۰۰۰۰۰ ریال/بازه',
};
const invalidInputs = {
  'cost_per_hire': ('hires', '0'),
  'employee_turnover': ('separations', '-1'),
  'employee_productivity': ('worked_hours', '0'),
  'training_roi': ('training_cost', '0'),
  'replacement_time': ('elapsed_days', ''),
  'absence_cost': ('loaded_hourly_cost', '0'),
};
final allRunners = HrCalculators.runners;
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
        expect(result(tester), expectedResults[definition.id]);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('six HR tools open through real category routes', (tester) async {
    await start(tester);
    await tapVisible(tester, find.byKey(const Key('category-humanResources')));
    expect(find.text('۶ ابزار قابل استفاده'), findsOneWidget);
    for (final r in allRunners) {
      await tapVisible(
        tester,
        find.byKey(Key('category-tool-${r.definition.id}')),
      );
      expect(result(tester), expectedResults[r.definition.id]);
      expect(find.textContaining('معیار قطعی'), findsWidgets);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'zero average turnover and blank observations have Persian errors',
    (tester) async {
      await tester.pumpWidget(host(HrCalculators.employeeTurnoverRunner));
      await tester.pumpAndSettle();
      await edit(tester, 'opening_headcount', '0');
      await edit(tester, 'closing_headcount', '0');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(
        find.textContaining('میانگین تعداد کارکنان صفر است'),
        findsOneWidget,
      );
      await tapVisible(tester, find.byKey(const Key('load-example-0')));
      expect(result(tester), '۵٪');
      await edit(tester, 'period_days', '');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(find.textContaining('الزامی است'), findsWidgets);
    },
  );
  testWidgets('negative training ROI remains descriptive, not clamped', (
    tester,
  ) async {
    await tester.pumpWidget(host(HrCalculators.trainingRoiRunner));
    await tester.pumpAndSettle();
    await edit(tester, 'gross_benefits', '0');
    expect(result(tester), '-۱۰۰٪');
    await edit(tester, 'attribution_rate', '101');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('load-example-0')));
    expect(result(tester), '۱۰۰٪');
  });
  testWidgets(
    'HR context and time list save/reopen, invalid fields disable save',
    (tester) async {
      await start(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('category-humanResources')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('category-tool-replacement_time')),
      );
      await edit(tester, 'period_days', '0');
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('calculator-save')))
            .onPressed,
        isNull,
      );
      await edit(tester, 'period_days', '30');
      await edit(tester, 'elapsed_days', '10\n20\n30');
      expect(result(tester), '۲۰ روز/جایگزینی');
      await tester.tap(find.byKey(const Key('calculator-save')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const Key('recent-1-tool-replacement_time')),
      );
      expect(result(tester), '۲۰ روز/جایگزینی');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-period_days')))
            .controller!
            .text,
        '30',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-elapsed_days')))
            .controller!
            .text,
        '10\n20\n30',
      );
    },
  );
  testWidgets(
    'HR incomplete external snapshots do not silently borrow example defaults',
    (tester) async {
      for (final r in allRunners) {
        await tester.pumpWidget(host(r, initialInput: RawCalculatorInput({})));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('primary-result')), findsNothing);
        expect(find.textContaining('الزامی است'), findsWidgets);
        await tapVisible(tester, find.byKey(const Key('load-example-0')));
        expect(result(tester), expectedResults[r.definition.id]);
      }
    },
  );
  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets('six HR pages fit $size dark=$dark enlarged RTL', (
        tester,
      ) async {
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
          expect(tester.takeException(), isNull, reason: runner.definition.id);
        }
      });
    }
  }
}
