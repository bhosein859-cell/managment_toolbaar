import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/finance_calculators.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/core/utils/persian_numbers.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/npv_engine.dart';
import 'package:management_toolbox/features/home/domain/catalog_search.dart';

void main() {
  test('ten finance runners, preserved NPV and 73 actual tools', () {
    expect(FinanceCalculators.runners, hasLength(10));
    expect(FinanceCalculators.byId.keys.toSet(), {
      'npv',
      'irr',
      'payback',
      'roi',
      'wacc',
      'current_ratio',
      'quick_ratio',
      'compound_interest',
      'loan_payment',
      'break_even',
    });
    expect(
      FinanceCalculators.byId['npv'],
      same(PrototypeCalculators.npvRunner),
    );
    expect(AppCatalog.catalog.tools, hasLength(73));
    expect(
      AppCatalog.catalog.toolsIn(CalculatorCategoryId.finance),
      hasLength(10),
    );
    expect(() => FinanceCalculators.runners.clear(), throwsUnsupportedError);
    expect(
      () => FinanceCalculators.definitions.clear(),
      throwsUnsupportedError,
    );
    expect(() => FinanceCalculators.byId.clear(), throwsUnsupportedError);
  });
  test(
    'NPV first cash flow is CF1 and discount rate belongs to each period',
    () {
      const engine = NpvEngine();
      final one = engine.calculate(
        NpvParameters(
          initialInvestment: 1000,
          discountRate: 0.1,
          cashFlows: [1100],
        ),
      ) as CalculationSuccess;
      expect(
        (one.result.primary.value as NumericResultValue).value,
        closeTo(0, 1e-10),
      );
      final two = engine.calculate(
        NpvParameters(
          initialInvestment: 1000,
          discountRate: 0.1,
          cashFlows: [0, 1210],
        ),
      ) as CalculationSuccess;
      expect(
        (two.result.primary.value as NumericResultValue).value,
        closeTo(0, 1e-10),
      );
      expect(PrototypeCalculators.npv.assumptions, contains('پایان دورهٔ اول'));
      expect(PrototypeCalculators.npv.assumptions, contains('نرخ مؤثر'));
      expect(
        one.result.warnings.any((w) => w.code == 'timing_assumption'),
        isTrue,
      );
      expect(
        engine.calculate(
          NpvParameters(
            initialInvestment: 1000,
            discountRate: -1,
            cashFlows: [1100],
          ),
        ),
        isA<CalculationFailure>(),
      );
    },
  );
  for (final runner in FinanceCalculators.runners) {
    final definition = runner.definition;
    test(
      '${definition.id}: full definition formula and educational numeric example',
      () {
        expect(definition.categoryId, CalculatorCategoryId.finance);
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
          closeTo(expected.value, expected.value.abs() * 1e-10 + 1e-10),
        );
        expect(actual.unit, expected.unit);
        expect(actual.display, expected.display);
        expect(output.result.interpretation, isNotEmpty);
        if (definition.id != 'npv') {
          expect(
            output.result.warnings.any(
              (w) => w.code == 'not_investment_advice',
            ),
            isTrue,
          );
        }
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
