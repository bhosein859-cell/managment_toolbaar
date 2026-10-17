import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/form_demo.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/widgets/calculator_formula.dart';
import 'package:management_toolbox/features/calculators/presentation/widgets/calculator_result_card.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import 'fixtures.dart';

String result(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const Key('primary-result')))
    .data!;
Future<void> edit(WidgetTester tester, String id, String text) async {
  final input = find.byKey(Key('input-$id'));
  await tester.ensureVisible(input);
  await tester.enterText(input, text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'renders typed defaults, units, ranges, explanations and LaTeX offline',
    (tester) async {
      await tester.pumpWidget(host(FormDemo.runner));
      await tester.pumpAndSettle();
      expect(result(tester), '۸۰ kg');
      expect(find.byKey(const Key('input-quantity')), findsOneWidget);
      expect(find.byKey(const Key('input-reduction')), findsOneWidget);
      expect(find.byKey(const Key('input-unit')), findsOneWidget);
      expect(find.text('توضیح پارامترها'), findsOneWidget);
      expect(find.text('مثال'), findsOneWidget);
      expect(find.text('تفسیر'), findsOneWidget);
      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining('بازهٔ مجاز:'), findsWidgets);
      expect(
        Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recalculates live and never shows stale result after invalid edit',
    (tester) async {
      await tester.pumpWidget(host(FormDemo.runner));
      await tester.pumpAndSettle();
      for (final value in ['۲۰۰', '٢٠٠', '200']) {
        await edit(tester, 'quantity', value);
        expect(result(tester), '۱۶۰ kg');
      }
      await edit(tester, 'reduction', '۲۵');
      expect(result(tester), '۱۵۰ kg');
      for (final invalid in ['NaN', 'Infinity', '101', '-', '']) {
        await edit(tester, 'reduction', invalid);
        expect(find.byKey(const Key('primary-result')), findsNothing);
        expect(find.byKey(const Key('no-result')), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('result-interpretation')))
              .data,
          contains('پس از معتبر شدن'),
        );
      }
      await edit(tester, 'reduction', '100');
      expect(result(tester), '۰ kg');
    },
  );

  testWidgets('selecting a unit updates output and preserves numeric input', (
    tester,
  ) async {
    await tester.pumpWidget(host(FormDemo.runner));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('input-unit')));
    await tester.tap(find.byKey(const Key('input-unit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ساعت (h)').last);
    await tester.pumpAndSettle();
    expect(result(tester), '۸۰ h');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('input-quantity')))
          .controller!
          .text,
      '۱۰۰',
    );
  });

  testWidgets(
    'loading an example fills controls; reset restores original defaults',
    (tester) async {
      await tester.pumpWidget(host(FormDemo.runner));
      await tester.pumpAndSettle();
      final example = find.byKey(const Key('load-example-0'));
      await tester.ensureVisible(example);
      await tester.tap(example);
      await tester.pumpAndSettle();
      expect(result(tester), '۱۵۰ h');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-reduction')))
            .controller!
            .text,
        '۲۵',
      );
      expect(
        tester
            .widget<DropdownButton<String>>(find.byKey(const Key('input-unit')))
            .value,
        'hours',
      );
      await tester.tap(find.byTooltip('بازنشانی ورودی‌ها'));
      await tester.pumpAndSettle();
      expect(result(tester), '۸۰ kg');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-quantity')))
            .controller!
            .text,
        '۱۰۰',
      );
    },
  );

  testWidgets(
    'numeric list uses newline entries and never splits thousands commas',
    (tester) async {
      await tester.pumpWidget(host(fixtureRunner(list: true)));
      await tester.pumpAndSettle();
      expect(result(tester), '۳');
      await edit(tester, 'values', '۱\n٢\n3');
      expect(result(tester), '۶');
      await edit(tester, 'values', '1,2');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(find.textContaining('عدد معتبر نیست'), findsOneWidget);
      await edit(tester, 'values', '1\n2\n3\n4');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(find.textContaining('تعداد موارد'), findsOneWidget);
    },
  );

  testWidgets(
    'domain failures and exceptions hide numeric output and expose safe Persian errors',
    (tester) async {
      await tester.pumpWidget(host(fixtureRunner()));
      await tester.pumpAndSettle();
      await edit(tester, 'value', '7');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      expect(find.text('برای این ورودی پاسخی وجود ندارد.'), findsOneWidget);
      for (final value in ['9', '11']) {
        await edit(tester, 'value', value);
        expect(find.byKey(const Key('primary-result')), findsNothing);
        expect(find.textContaining('محاسبه انجام نشد'), findsOneWidget);
        expect(find.textContaining('INTERNAL'), findsNothing);
      }
      await edit(tester, 'value', '13');
      expect(find.text('این مقدار در نمونه مجاز نیست.'), findsOneWidget);
      await edit(tester, 'value', '1');
      expect(result(tester), '۱');
      expect(find.byKey(const Key('global-errors')), findsNothing);
    },
  );

  testWidgets(
    'same runner survives theme rebuild; replacement runner resets safely',
    (tester) async {
      final runner = fixtureRunner();
      await tester.pumpWidget(host(runner));
      await tester.pumpAndSettle();
      await edit(tester, 'value', '5');
      await tester.pumpWidget(host(runner, dark: true));
      await tester.pumpAndSettle();
      expect(result(tester), '۵');
      final next = fixtureRunner(initial: 3);
      await tester.pumpWidget(host(next));
      await tester.pumpAndSettle();
      expect(result(tester), '۳');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('restores prior raw inputs and surfaces invalid initial values', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FormDemo.runner,
        initialInput: RawCalculatorInput({
          'quantity': const RawTextInput('50'),
          'reduction': const RawTextInput('50'),
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(result(tester), '۲۵ kg');
    await tester.pumpWidget(
      host(
        FormDemo.runner,
        initialInput: RawCalculatorInput({
          'quantity': const RawTextInput('bad'),
        }),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('primary-result')), findsNothing);
    expect(find.textContaining('باید عدد معتبر'), findsOneWidget);
  });

  testWidgets(
    'invalid LaTeX falls back to safe text rather than breaking page',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: CalculatorFormula(latex: r'\notARealCommand{')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsOneWidget);
      await tester.tap(find.text('متن LaTeX و کپی فرمول'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('formula-text')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('textual and numeric-series results and warnings are rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalculatorResultCard(
              result: CalculationResult(
                primary: ResultMetric(
                  id: 'text',
                  label: 'مسیر',
                  value: TextResultValue('الف ← ب'),
                ),
                details: [
                  ResultMetric(
                    id: 'series',
                    label: 'داده‌ها',
                    value: NumberListResultValue([1, 2], unit: 'h'),
                  ),
                ],
                warnings: [
                  CalculationWarning(
                    code: 'warning',
                    message: 'فرض‌ها را کنترل کنید.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(result(tester), 'الف ← ب');
    expect(find.text('۱ | ۲ h'), findsOneWidget);
    expect(find.text('فرض‌ها را کنترل کنید.'), findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets(
        'RTL layout $size dark=$dark at text scale 1.5 has no overflow',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(host(FormDemo.runner, dark: dark));
          await tester.pumpAndSettle();
          await edit(tester, 'quantity', 'bad');
          await tester.ensureVisible(find.text('تفسیر'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('demo is reachable from the existing app home', (tester) async {
    await tester.pumpWidget(
      ManagementToolboxApp(repository: DriftToolRepository.memory()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ورود به برنامه'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('آزمایش فرم ماشین‌حساب'));
    await tester.pumpAndSettle();
    expect(find.text('آزمایش فرم عمومی'), findsOneWidget);
    expect(result(tester), '۸۰ kg');
  });
}
