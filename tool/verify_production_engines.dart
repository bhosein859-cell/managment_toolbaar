import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/production_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

/// Pure Dart runtime check; uses explicit numeric references, not formula text.
void main() {
  const expected = {
    'oee': 0.8379,
    'takt_time': 2.0,
    'production_capacity': 480.0,
    'labor_productivity': 8.0,
    'cycle_time': 2.0,
    'smed': 2 / 3,
    'unit_production_cost': 3000.0,
    'wip': 60.0,
    'throughput': 30.0,
    'capacity_utilization': 0.75,
  };
  if (ProductionCalculators.runners.length != 10 ||
      AppCatalog.catalog.tools.length != 73) {
    throw StateError('Unexpected catalog counts');
  }
  for (final runner in ProductionCalculators.runners) {
    final id = runner.definition.id;
    final output = runner.run(runner.definition.examples.single.inputs);
    if (output is! CalculationSuccess) throw StateError('$id failed');
    final actual = (output.result.primary.value as NumericResultValue).value;
    if (!actual.isFinite || (actual - expected[id]!).abs() > 1e-10) {
      throw StateError('$id: $actual != ${expected[id]}');
    }
    stdout.writeln('$id: $actual');
  }
  stdout.writeln(
    'Pure Dart production smoke: all 10 engines and 73-tool catalog passed.',
  );
}
