import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/project_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import '../presentation/fixtures.dart';

const expectedResults = {
  'pert_duration': '۴٫۳۳۳۳۳۳ روز',
  'cpm': '۸ روز',
  'project_float': '۲ روز',
  'evm_performance': '۰٫۸',
  'three_point': '۴٫۶۶۶۶۶۷ واحد مشترک',
  'eac_etc': '۱۲۵۰ ریال',
  'sv_cv': '-۲۰ ریال',
  'duration_comparison': '۲ روز',
};
const invalidInputs = {
  'pert_duration': ('most_likely', '9'),
  'cpm': ('predecessor_ids', '99\n1\n2\n3'),
  'project_float': ('predecessor_ids', '99\n1\n2\n3'),
  'evm_performance': ('pv', '0'),
  'three_point': ('most_likely', '9'),
  'eac_etc': ('ev', '1001'),
  'sv_cv': ('ac', '-1'),
  'duration_comparison': ('planned_duration', '-1'),
};
final allRunners = ProjectCalculators.runners;
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
  testWidgets('eight project tools open through real category routes', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(tester, find.byKey(const Key('category-project')));
    expect(find.text('۸ ابزار قابل استفاده'), findsOneWidget);
    for (final runner in allRunners) {
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
  testWidgets('structured CPM rejects refs and cycles without stale results', (
    tester,
  ) async {
    await tester.pumpWidget(host(ProjectCalculators.cpmRunner));
    await tester.pumpAndSettle();
    await edit(tester, 'predecessor_ids', '99\n1\n2\n3');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    expect(find.textContaining('هر دو سر وابستگی'), findsOneWidget);
    await edit(tester, 'predecessor_ids', '4\n1\n2\n3');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    expect(find.textContaining('شبکه چرخه دارد'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('load-example-0')));
    expect(result(tester), '۸ روز');
    await edit(tester, 'predecessor_ids', '');
    await edit(tester, 'successor_ids', '');
    expect(result(tester), '۴ روز');
  });
  testWidgets('EAC method choice handles undefined indices explicitly', (
    tester,
  ) async {
    await tester.pumpWidget(host(ProjectCalculators.eacEtcRunner));
    await tester.pumpAndSettle();
    await edit(tester, 'ev', '0');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    await tapVisible(tester, find.byKey(const Key('input-method')));
    await tapVisible(tester, find.text('باقی‌مانده طبق بودجه').last);
    expect(result(tester), '۱۱۰۰ ریال');
    await tapVisible(tester, find.byKey(const Key('input-method')));
    await tapVisible(tester, find.text('برآورد مجدد پایین‌به‌بالا').last);
    expect(result(tester), '۳۵۰ ریال');
    expect(tester.takeException(), isNull);
  });
  testWidgets('structured CPM graph save/reopen and invalid form disabled', (
    tester,
  ) async {
    await start(tester);
    await tapVisible(tester, find.byKey(const Key('category-project')));
    await tapVisible(tester, find.byKey(const Key('category-tool-cpm')));
    await edit(tester, 'durations', '3\n4');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('calculator-save')))
          .onPressed,
      isNull,
    );
    await edit(tester, 'durations', '3\n4\n2\n1');
    expect(result(tester), '۸ روز');
    await tester.tap(find.byKey(const Key('calculator-favorite')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('calculator-save')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorite-tool-cpm')), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('recent-1-tool-cpm')));
    expect(result(tester), '۸ روز');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('input-durations')))
          .controller!
          .text,
      '3\n4\n2\n1',
    );
  });
  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets('eight project pages fit $size dark=$dark enlarged RTL', (
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
