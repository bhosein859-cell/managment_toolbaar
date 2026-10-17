import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/decision_calculators.dart';
import 'package:management_toolbox/app/catalog/engineering_economics_calculators.dart';
import 'package:management_toolbox/app/catalog/finance_calculators.dart';
import 'package:management_toolbox/app/catalog/hr_calculators.dart';
import 'package:management_toolbox/app/catalog/inventory_calculators.dart';
import 'package:management_toolbox/app/catalog/production_calculators.dart';
import 'package:management_toolbox/app/catalog/project_calculators.dart';
import 'package:management_toolbox/app/catalog/quality_calculators.dart';
import 'package:management_toolbox/app/catalog/utility_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/formatting/result_text_export.dart';

void main() {
  final runners = <CalculatorRunner<CalculatorParameters>>[
    ...ProductionCalculators.runners,
    ...FinanceCalculators.runners,
    ...QualityCalculators.runners,
    ...InventoryCalculators.runners,
    ...ProjectCalculators.runners,
    ...HrCalculators.runners,
    ...DecisionCalculators.runners,
    ...EngineeringEconomicsCalculators.runners,
    ...UtilityCalculators.runners,
  ];
  for (final r in runners) {
    test(
      '${r.definition.id}: complete text export with actual example/result/units/warnings',
      () {
        final raw = r.definition.examples.single.inputs;
        final result = (r.run(raw) as CalculationSuccess).result;
        final text = ResultTextExport.format(r.definition, raw, result);
        expect(text, contains(r.definition.nameFa));
        expect(text, contains(r.definition.nameEn));
        expect(text, contains(result.primary.label));
        for (final field in r.definition.fields) {
          expect(text, contains(field.label));
        }
        for (final metric in result.details) {
          expect(text, contains(metric.label));
        }
        for (final warning in result.warnings) {
          expect(text, contains(warning.message));
        }
        expect(text, endsWith('سازنده حسین بختیاری'));
      },
    );
  }
  test('original digits/whitespace and percentage display unit are not normalized away', () {
    final r = UtilityCalculators.percentageOfRunner;
    final raw = RawCalculatorInput({
      'amount': const RawTextInput('  ۲۵۰  '),
      'rate': const RawTextInput('٢٠'),
    });
    final text = ResultTextExport.format(
      r.definition,
      raw,
      (r.run(raw) as CalculationSuccess).result,
    );
    expect(text, contains('  ۲۵۰  '));
    expect(text, contains('(٪): ٢٠'));
    expect(text, contains('۵۰'));
  });
  test(
    'valid whitespace around a choice resolves to its displayed unit name',
    () {
      final r = UtilityCalculators.unitConversionRunner;
      final raw = RawCalculatorInput({
        'amount': const RawTextInput('1'),
        'from_unit': const RawTextInput(' m '),
        'to_unit': const RawTextInput('cm'),
      });
      final result = (r.run(raw) as CalculationSuccess).result;
      expect(
        ResultTextExport.format(r.definition, raw, result),
        contains('متر (m)'),
      );
    },
  );
  test('incomplete export input is rejected rather than invented', () {
    final r = UtilityCalculators.percentageOfRunner;
    final result = (r.run(
      r.definition.examples.single.inputs,
    ) as CalculationSuccess).result;
    expect(
      () =>
          ResultTextExport.format(r.definition, RawCalculatorInput({}), result),
      throwsArgumentError,
    );
  });
}
