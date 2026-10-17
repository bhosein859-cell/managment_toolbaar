import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/break_even_engine.dart';

import 'helpers.dart';

BreakEvenParameters parameters(Map<String, double> v) => BreakEvenParameters(
  fixedCost: v['fixed_cost']!,
  unitPrice: v['unit_price']!,
  variableCost: v['variable_cost']!,
);
void main() {
  const engine = BreakEvenEngine();
  const defaults = <String, double>{
    'fixed_cost': 1000.0,
    'unit_price': 10.0,
    'variable_cost': 6.0,
  };
  test('break_even: reference formula', () {
    expect(engine.calculatorId, 'break_even');
    expect(number(engine.calculate(parameters(defaults))), closeTo(250, 1e-9));
  });
  test('break_even: typed bind and domain validation', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final bound = engine.bind(input);
    expect(bound, isA<BoundInput<BreakEvenParameters>>());
    expect(
      number(
        engine.calculate((bound as BoundInput<BreakEvenParameters>).parameters),
      ),
      closeTo(250, 1e-9),
    );
    final bad = {...defaults, 'fixed_cost': -1.toDouble()};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<BreakEvenParameters>>(),
    );
  });
  test('break_even: nonfinite fixed_cost', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'fixed_cost': x})),
        'fixed_cost',
      );
    }
  });
  test('break_even: lower bound fixed_cost', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'fixed_cost': -1.toDouble()})),
      'fixed_cost',
    );
  });
  test('break_even: nonfinite unit_price', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'unit_price': x})),
        'unit_price',
      );
    }
  });
  test('break_even: lower bound unit_price', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'unit_price': 0.toDouble()})),
      'unit_price',
    );
  });
  test('break_even: nonfinite variable_cost', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'variable_cost': x})),
        'variable_cost',
      );
    }
  });
  test('break_even: lower bound variable_cost', () {
    failsAt(
      engine.calculate(
        parameters({...defaults, 'variable_cost': -1.toDouble()}),
      ),
      'variable_cost',
    );
  });
  test('break_even: 20 independent Decimal formula fixtures', () {
    final rows = references('break_even');
    expect(rows, hasLength(20));
    for (final row in rows) {
      final values = (row['inputs'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, double.parse(v as String)),
      );
      final expected = double.parse(row['expected'] as String);
      expect(
        number(engine.calculate(parameters(values))),
        closeTo(expected, expected.abs() * 2e-11 + 1e-11),
        reason: row.toString(),
      );
    }
  });
  test('break_even: zero cross-field and numerical edge cases', () {
    failure(
      engine.calculate(
        const BreakEvenParameters(
          fixedCost: 1000,
          unitPrice: 6,
          variableCost: 6,
        ),
      ),
      'nonpositive_margin',
    );
    failure(
      engine.calculate(
        const BreakEvenParameters(
          fixedCost: 1000,
          unitPrice: 5,
          variableCost: 6,
        ),
      ),
      'nonpositive_margin',
    );
    expect(
      number(
        engine.calculate(
          const BreakEvenParameters(
            fixedCost: 0,
            unitPrice: 10,
            variableCost: 6,
          ),
        ),
      ),
      0,
    );
    final fractional = engine.calculate(
      const BreakEvenParameters(fixedCost: 1000, unitPrice: 6, variableCost: 3),
    ) as CalculationSuccess;
    expect(number(fractional), closeTo(1000 / 3, 1e-12));
    expect(
      (fractional.result.details.first.value as NumericResultValue).value,
      334,
    );
    failure(
      engine.calculate(
        const BreakEvenParameters(
          fixedCost: 1e308,
          unitPrice: 10,
          variableCost: 6,
        ),
      ),
      'numeric_range',
    );
  });
}
