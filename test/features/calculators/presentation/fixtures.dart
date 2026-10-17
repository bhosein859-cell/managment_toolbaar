import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:management_toolbox/app/theme/app_theme.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';

final class FixtureParameters implements CalculatorParameters {
  const FixtureParameters(this.value);
  final double value;
}

final class FixtureEngine implements CalculatorEngine<FixtureParameters> {
  const FixtureEngine({this.list = false});
  final bool list;
  @override
  String get calculatorId => 'fixture';
  @override
  InputBinding<FixtureParameters> bind(CalculatorInput input) {
    final value = list
        ? input.requireNumberList('values').fold(0.0, (a, b) => a + b)
        : input.requireNumber('value');
    if (value == 13) {
      return RejectedInput([
        CalculationIssue(
          code: 'reserved',
          message: 'این مقدار در نمونه مجاز نیست.',
          fieldId: list ? 'values' : 'value',
        ),
      ]);
    }
    return BoundInput(FixtureParameters(value));
  }

  @override
  CalculationOutcome calculate(FixtureParameters parameters) {
    if (parameters.value == 7) {
      return CalculationFailure([
        CalculationIssue(
          code: 'no_solution',
          message: 'برای این ورودی پاسخی وجود ندارد.',
        ),
      ]);
    }
    if (parameters.value == 9) throw StateError('INTERNAL');
    final value = parameters.value == 11 ? double.infinity : parameters.value;
    return CalculationSuccess(
      CalculationResult(
        primary: ResultMetric(
          id: 'sum',
          label: 'جمع',
          value: NumericResultValue(value),
        ),
        interpretation: 'تفسیر آزمایشی',
      ),
    );
  }
}

CalculatorRunner<FixtureParameters> fixtureRunner({
  bool list = false,
  double initial = 2,
}) => CalculatorRunner(
  definition: CalculatorDefinition(
    id: 'fixture',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'فرم آزمایشی',
    nameEn: 'Fixture',
    description: 'فقط برای تست',
    formulaLatex: r'y=x',
    fields: list
        ? [
            NumberListFieldDefinition(
              id: 'values',
              label: 'داده‌ها',
              defaultValue: [1, 2],
              min: -100,
              max: 100,
              maxItems: 3,
            ),
          ]
        : [
            NumericFieldDefinition(
              id: 'value',
              label: 'مقدار',
              min: 0,
              max: 100,
              defaultValue: initial,
            ),
          ],
  ),
  engine: FixtureEngine(list: list),
);

Widget host<I extends CalculatorParameters>(
  CalculatorRunner<I> runner, {
  RawCalculatorInput? initialInput,
  bool dark = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: const Locale('fa', 'IR'),
  supportedLocales: const [Locale('fa', 'IR')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  home: CalculatorPage(runner: runner, initialInput: initialInput),
);
