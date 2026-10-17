import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/project_calculators.dart';
import 'package:management_toolbox/core/utils/persian_numbers.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/home/domain/catalog_search.dart';

void main() {
  test('eight independent project tools and 73 catalog entries', () {
    expect(ProjectCalculators.runners, hasLength(8));
    expect(AppCatalog.catalog.tools, hasLength(73));
    expect(
      AppCatalog.catalog.toolsIn(CalculatorCategoryId.project),
      hasLength(8),
    );
    expect(() => ProjectCalculators.runners.clear(), throwsUnsupportedError);
    expect(
      () => ProjectCalculators.definitions.clear(),
      throwsUnsupportedError,
    );
    expect(() => ProjectCalculators.byId.clear(), throwsUnsupportedError);
  });
  for (final runner in ProjectCalculators.runners) {
    final definition = runner.definition;
    test(
      '${definition.id}: full definition formula and educational numeric example',
      () {
        expect(definition.categoryId, CalculatorCategoryId.project);
        expect(definition.description, isNotEmpty);
        expect(definition.formulaLatex, isNotEmpty);
        expect(definition.assumptions, isNotEmpty);
        expect(definition.relatedTerms, isNotEmpty);
        for (final field in definition.fields) {
          expect(field.help, isNotEmpty);
        }
        final example = definition.examples.single;
        final output = runner.run(example.inputs) as CalculationSuccess;
        final actual = output.result.primary.value as NumericResultValue;
        final expected =
            example.expectedResult!.primary.value as NumericResultValue;
        expect(
          actual.value,
          closeTo(expected.value, expected.value.abs() * 5e-8 + 5e-8),
        );
        expect(actual.unit, expected.unit);
        expect(actual.display, expected.display);
        expect(output.result.interpretation, isNotEmpty);
        final search = CatalogSearch(AppCatalog.catalog);
        expect(search.search(definition.nameEn).first.tool.id, definition.id);
        expect(search.search(definition.nameFa).first.tool.id, definition.id);
      },
    );
    test(
      '${definition.id}: Arabic Persian Latin digits and malformed form data',
      () {
        final raw = definition.examples.single.inputs;
        RawCalculatorInput convert(String Function(String) f) =>
            RawCalculatorInput({
              for (final entry in raw.values.entries)
                entry.key: switch (entry.value) {
                  RawTextInput(:final text) => RawTextInput(f(text)),
                  RawNumberListInput(:final items) => RawNumberListInput(
                    items.map(f),
                  ),
                },
            });
        final original = runner.run(raw) as CalculationSuccess;
        final expected =
            (original.result.primary.value as NumericResultValue).value;
        for (final f in [
          PersianNumbers.toLatin,
          PersianNumbers.toPersian,
          (String s) => PersianNumbers.toLatin(s).replaceAllMapped(
            RegExp('[0-9]'),
            (m) => String.fromCharCode(0x660 + int.parse(m[0]!)),
          ),
        ]) {
          final output = runner.run(convert(f)) as CalculationSuccess;
          expect(
            (output.result.primary.value as NumericResultValue).value,
            expected,
          );
        }
        for (final field in definition.fields) {
          final bad = switch (field) {
            NumberListFieldDefinition() => RawNumberListInput(['NaN']),
            _ => const RawTextInput('invalid'),
          };
          final outcome = runner.run(
            RawCalculatorInput({...raw.values, field.id: bad}),
          );
          expect(outcome, isA<CalculationFailure>());
          expect(
            (outcome as CalculationFailure).issues.every(
              (i) => i.code != 'calculation_failed',
            ),
            isTrue,
          );
        }
      },
    );
  }
}
