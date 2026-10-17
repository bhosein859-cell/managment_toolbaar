import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/engineering_economics_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import '../presentation/fixtures.dart';

const expectedResults = {
  'time_value_money': '۱۳۳۱ ریال',
  'future_present_factor': '۱٫۳۳۱ برابر',
  'present_future_factor': '۰٫۷۵۱۳۱۵ برابر',
  'future_annuity_factor': '۳٫۳۱ برابر',
  'annuity_future_factor': '۰٫۳۰۲۱۱۵ برابر',
  'present_annuity_factor': '۲٫۴۸۶۸۵۲ برابر',
  'annuity_present_factor': '۰٫۴۰۲۱۱۵ برابر',
  'straight_line_depreciation': '۱۸۰ ریال/سال',
  'declining_balance_depreciation': '۱۶۰ ریال/سال',
  'inflation_adjustment': '۷۵۱٫۳۱۴۸۰۱ ریال',
};
final invalidInputs = {
  for (final id in expectedResults.keys)
    id: (
      id.contains('depreciation') ? 'cost' : 'rate',
      id.contains('depreciation') ? '-1' : '-100',
    ),
};
final allRunners = EngineeringEconomicsCalculators.runners;
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
  testWidgets('ten economics tools open through real category routes', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(
      tester,
      find.byKey(const Key('category-engineeringEconomics')),
    );
    expect(find.text('۱۰ ابزار قابل استفاده'), findsOneWidget);
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
    'Economics incomplete external snapshots do not silently borrow example defaults',
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
    'Zero-rate factor inputs save/reopen and undefined zero-period inverse disables save',
    (tester) async {
      await start(tester);
      await tapVisible(
        tester,
        find.byKey(const Key('category-engineeringEconomics')),
      );
      await tapVisible(
        tester,
        find.byKey(const Key('category-tool-annuity_present_factor')),
      );
      await edit(tester, 'periods', '0');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('calculator-save')))
            .onPressed,
        isNull,
      );
      await edit(tester, 'periods', '2');
      await edit(tester, 'rate', '0');
      expect(result(tester), '۰٫۵ برابر');
      await tester.tap(find.byKey(const Key('calculator-save')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byKey(const Key('recent-1-tool-annuity_present_factor')),
      );
      expect(result(tester), '۰٫۵ برابر');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-periods')))
            .controller!
            .text,
        '2',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-rate')))
            .controller!
            .text,
        '0',
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets('ten economics pages fit $size dark=$dark enlarged RTL', (
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
