import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/project_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

void main() {
  if (AppCatalog.catalog.tools.length != 73 ||
      ProjectCalculators.runners.length != 8) {
    throw StateError('Incorrect catalog');
  }
  for (final r in ProjectCalculators.runners) {
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
    stdout.writeln('${r.definition.id}: $actual');
  }
  final raw = ProjectCalculators.cpm.examples.single.inputs;
  for (final from in [
    ['99', '1', '2', '3'],
    ['4', '1', '2', '3'],
  ]) {
    final o = ProjectCalculators.cpmRunner.run(
      RawCalculatorInput({
        ...raw.values,
        'predecessor_ids': RawNumberListInput(from),
      }),
    );
    if (o is! CalculationFailure ||
        o.issues.any((i) => i.code == 'calculation_failed')) {
      throw StateError('Invalid reference/cycle not rejected safely');
    }
  }
  final evm = ProjectCalculators.evmPerformance.examples.single.inputs;
  final invalid = ProjectCalculators.evmPerformanceRunner.run(
    RawCalculatorInput({...evm.values, 'pv': const RawTextInput('0')}),
  );
  if (invalid is! CalculationFailure) {
    throw StateError('Fabricated zero-denominator index');
  }
  stdout.writeln(
    '8 project engines, structured DAG validation, 73-tool catalog: PASS',
  );
}
