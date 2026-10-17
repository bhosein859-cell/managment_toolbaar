import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/utility_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/glossary/domain/glossary_catalog.dart';
import 'package:management_toolbox/features/utilities/domain/unit_conversion.dart';

void main() {
  if (AppCatalog.catalog.tools.length != 73 ||
      UnitRegistry.units.length != 42) {
    throw StateError('Catalog mismatch');
  }
  for (final r in UtilityCalculators.runners) {
    final example = r.definition.examples.single;
    final result = r.run(example.inputs);
    if (result is! CalculationSuccess) {
      throw StateError('${r.definition.id}: failure');
    }
    final expected =
        (example.expectedResult!.primary.value as NumericResultValue).value;
    final actual = (result.result.primary.value as NumericResultValue).value;
    if ((actual - expected).abs() > 1e-10) {
      throw StateError('${r.definition.id}: wrong result');
    }
  }
  final glossary = GlossaryCatalog.fromTools(AppCatalog.catalog);
  for (final entry in glossary.entries) {
    for (final link in entry.calculatorIds) {
      if (AppCatalog.catalog.toolById(link) == null) {
        throw StateError('Broken link');
      }
    }
  }
  stdout.writeln(
    '5 utility engines, 42 units/10 dimensions, ${glossary.entries.length} offline terms, 73-tool catalog: PASS',
  );
}
