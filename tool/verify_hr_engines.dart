import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/hr_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

void main() {
  if (AppCatalog.catalog.tools.length != 73 ||
      HrCalculators.runners.length != 6) {
    throw StateError('Incorrect catalog');
  }
  for (final r in HrCalculators.runners) {
    final e = r.definition.examples.single, o = r.run(e.inputs);
    if (o is! CalculationSuccess) {
      throw StateError('Failed ${r.definition.id}');
    }
    final actual = (o.result.primary.value as NumericResultValue).value,
        expected =
            (e.expectedResult!.primary.value as NumericResultValue).value;
    if (!actual.isFinite ||
        (actual - expected).abs() > expected.abs() * 1e-10 + 1e-10) {
      throw StateError('Wrong ${r.definition.id}');
    }
    if (!o.result.warnings.any((w) => w.code == 'descriptive_hr_only')) {
      throw StateError('Missing HR interpretation caution');
    }
    if (r.run(RawCalculatorInput({})) is! CalculationFailure) {
      throw StateError('Missing observations became defaults');
    }
    stdout.writeln('${r.definition.id}: $actual');
  }
  final raw = HrCalculators.costPerHire.examples.single.inputs;
  final o = HrCalculators.costPerHireRunner.run(
    RawCalculatorInput({...raw.values, 'hires': const RawTextInput('0')}),
  );
  if (o is! CalculationFailure ||
      !o.issues.any((i) => i.code == 'positive_required')) {
    throw StateError('Zero denominator fabricated result');
  }
  stdout.writeln(
    '6 HR typed engines, explicit observations, 73-tool catalog: PASS',
  );
}
