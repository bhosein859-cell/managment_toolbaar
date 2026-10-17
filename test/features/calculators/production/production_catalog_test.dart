import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/production_calculators.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/core/utils/persian_numbers.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/home/domain/catalog_search.dart';

void main() {
  test(
    'ten production engines registered once, prior OEE identity is preserved',
    () {
      expect(ProductionCalculators.runners, hasLength(10));
      expect(ProductionCalculators.byId.keys.toSet(), {
        'oee',
        'takt_time',
        'production_capacity',
        'labor_productivity',
        'cycle_time',
        'smed',
        'unit_production_cost',
        'wip',
        'throughput',
        'capacity_utilization',
      });
      expect(
        ProductionCalculators.byId['oee'],
        same(PrototypeCalculators.oeeRunner),
      );
      expect(AppCatalog.catalog.tools, hasLength(73));
      expect(
        AppCatalog.catalog.toolsIn(CalculatorCategoryId.production),
        hasLength(10),
      );
      expect(() => ProductionCalculators.byId.clear(), throwsUnsupportedError);
      expect(
        () => ProductionCalculators.definitions.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => ProductionCalculators.runners.clear(),
        throwsUnsupportedError,
      );
    },
  );
  for (final runner in ProductionCalculators.runners) {
    final definition = runner.definition;
    test(
      '${definition.id}: complete educational definition and executable example',
      () {
        expect(definition.categoryId, CalculatorCategoryId.production);
        expect(definition.description, isNotEmpty);
        expect(definition.assumptions, isNotEmpty);
        expect(definition.formulaLatex, isNotEmpty);
        expect(definition.relatedTerms, isNotEmpty);
        expect(definition.examples, hasLength(1));
        for (final field in definition.fields) {
          expect(field.help, isNotEmpty);
          if ((field as NumericFieldDefinition).kind !=
              NumericInputKind.percentage) {
            expect(field.unit, isNotEmpty);
          }
          expect((field).defaultValue, isNotNull);
        }
        final example = definition.examples.single;
        final outcome = runner.run(example.inputs) as CalculationSuccess;
        final actual = outcome.result.primary.value as NumericResultValue;
        final expected =
            example.expectedResult!.primary.value as NumericResultValue;
        expect(
          actual.value,
          closeTo(expected.value, expected.value.abs() * 1e-12 + 1e-14),
        );
        expect(actual.unit, expected.unit);
        expect(actual.display, expected.display);
        expect(outcome.result.interpretation, isNotEmpty);
        if (definition.id != 'oee') {
          expect(
            outcome.result.warnings.any(
              (w) =>
                  w.code == 'calculation_basis' &&
                  w.message == outcome.result.interpretation &&
                  w.severity == WarningSeverity.information,
            ),
            isTrue,
          );
        }
        // Both the original Persian name and English name remain searchable.
        final search = CatalogSearch(AppCatalog.catalog);
        expect(search.search(definition.nameEn).first.tool.id, definition.id);
        expect(search.search(definition.nameFa).first.tool.id, definition.id);
      },
    );
    test(
      '${definition.id}: Persian Arabic and Latin inputs agree; blank/NaN are rejected',
      () {
        final fields = definition.fields.cast<NumericFieldDefinition>();
        Map<String, RawFieldInput> raw(String Function(String) convert) => {
          for (final f in fields)
            f.id: RawTextInput(convert(f.defaultValue!.toString())),
        };
        final latin =
            runner.run(RawCalculatorInput(raw((s) => s))) as CalculationSuccess;
        final expected =
            (latin.result.primary.value as NumericResultValue).value;
        for (final convert in [
          PersianNumbers.toPersian,
          (String s) => s.replaceAllMapped(
            RegExp('[0-9]'),
            (m) => String.fromCharCode(0x660 + int.parse(m[0]!)),
          ),
        ]) {
          final outcome = runner.run(
            RawCalculatorInput(raw(convert)),
          ) as CalculationSuccess;
          expect(
            (outcome.result.primary.value as NumericResultValue).value,
            expected,
          );
        }
        for (final field in fields) {
          for (final invalid in ['', 'NaN', 'Infinity', '-1']) {
            final outcome = runner.run(
              RawCalculatorInput({
                ...raw((s) => s),
                field.id: RawTextInput(invalid),
              }),
            );
            expect(outcome, isA<CalculationFailure>());
            expect(
              (outcome as CalculationFailure).issues.every(
                (i) => i.code != 'calculation_failed',
              ),
              isTrue,
            );
          }
        }
      },
    );
  }
}
