import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/inventory_calculators.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/app/catalog/quality_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

void main() {
  if (AppCatalog.catalog.tools.length != 73 ||
      QualityCalculators.runners.length != 8 ||
      InventoryCalculators.runners.length != 8) {
    throw StateError('Catalog counts');
  }
  if (!identical(
    QualityCalculators.byId['cp'],
    PrototypeCalculators.cpRunner,
  )) {
    throw StateError('Cp was duplicated');
  }
  for (final runner in [
    ...QualityCalculators.runners,
    ...InventoryCalculators.runners,
  ]) {
    final example = runner.definition.examples.single;
    final o = runner.run(example.inputs);
    if (o is! CalculationSuccess) {
      throw StateError('Failed ${runner.definition.id}');
    }
    final actual = (o.result.primary.value as NumericResultValue).value;
    final expected =
        (example.expectedResult!.primary.value as NumericResultValue).value;
    if (!actual.isFinite ||
        (actual - expected).abs() > expected.abs() * 5e-8 + 5e-8) {
      throw StateError('Wrong ${runner.definition.id}');
    }
    stdout.writeln('${runner.definition.id}: $actual');
  }
  for (final endpoint in ['0', '1000000']) {
    final raw = QualityCalculators.sigmaLevel.examples.single.inputs;
    final o = QualityCalculators.sigmaLevelRunner.run(
      RawCalculatorInput({...raw.values, 'dpmo': RawTextInput(endpoint)}),
    );
    if (o is! CalculationFailure ||
        !o.issues.any((i) => i.code == 'unbounded_sigma')) {
      throw StateError('Fake sigma endpoint');
    }
  }
  stdout.writeln(
    '16 tools / 15 new independent engines, 73-tool catalog: PASS',
  );
}
