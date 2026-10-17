import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/decision_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

void main() {
  if (AppCatalog.catalog.tools.length != 73 ||
      DecisionCalculators.runners.length != 8) {
    throw StateError('Incorrect catalog');
  }
  for (final r in DecisionCalculators.runners) {
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
    if (!o.result.warnings.any((w) => w.code == 'conditional_decision')) {
      throw StateError('Missing conditional interpretation caution');
    }
    if (r.run(RawCalculatorInput({})) is! CalculationFailure) {
      throw StateError('Missing observations became defaults');
    }
    stdout.writeln('${r.definition.id}: $actual');
  }
  stdout.writeln('Eight decision engines and 73-tool catalog verified.');
}
