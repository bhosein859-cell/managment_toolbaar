import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/decision_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import '../presentation/fixtures.dart';

const expectedResults = {
  'ahp': '۰٫۴',
  'topsis': '۰٫۶',
  'decision_matrix': '۰٫۶',
  'expected_value_tree': '۵۲ ریال',
  'weight_sensitivity': '۰٫۶',
  'weighted_scoring': '۷٫۸',
  'cost_benefit_comparison': '۳۰ ریال',
  'two_option_break_even': '۵۰ واحد',
};
const invalidInputs = {
  'ahp': ('alternatives', '1'),
  'topsis': ('alternatives', '1'),
  'decision_matrix': ('alternatives', '1'),
  'expected_value_tree': ('root_id', '0'),
  'weight_sensitivity': ('selected_criterion', '0'),
  'weighted_scoring': ('alternatives', '1'),
  'cost_benefit_comparison': ('period_days', '0'),
  'two_option_break_even': ('period_days', '0'),
};
final allRunners = DecisionCalculators.runners;
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
  testWidgets('eight decision tools open through real category routes', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(tester, find.byKey(const Key('category-decisionMaking')));
    expect(find.text('۸ ابزار قابل استفاده'), findsOneWidget);
    for (final r in allRunners) {
      await tapVisible(
        tester,
        find.byKey(Key('category-tool-${r.definition.id}')),
      );
      expect(result(tester), expectedResults[r.definition.id]);
      expect(find.textContaining('فرض'), findsWidgets);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Decision incomplete external snapshots do not silently borrow example defaults',
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
  testWidgets(
    'Decision matrix list save/reopen retains weights and invalid shape disables save',
    (tester) async {
      await start(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('category-decisionMaking')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('category-tool-weighted_scoring')),
      );
      await edit(tester, 'matrix', '10\n10\n20\n20\n30\n30');
      expect(result(tester), '۳۰');
      await edit(tester, 'alternatives', '4');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('calculator-save')))
            .onPressed,
        isNull,
      );
      await edit(tester, 'alternatives', '3');
      await tester.tap(find.byKey(const Key('calculator-save')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const Key('recent-1-tool-weighted_scoring')),
      );
      expect(result(tester), '۳۰');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-matrix')))
            .controller!
            .text,
        '10\n10\n20\n20\n30\n30',
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets('eight decision pages fit $size dark=$dark enlarged RTL', (
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
