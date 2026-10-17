import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/compound_interest_engine.dart';

import 'helpers.dart';

CompoundInterestParameters parameters(Map<String, double> v) =>
    CompoundInterestParameters(
      principal: v['principal']!,
      periodRate: v['period_rate']!,
      periods: v['periods']!,
    );
void main() {
  const engine = CompoundInterestEngine();
  const defaults = <String, double>{
    'principal': 1000.0,
    'period_rate': 0.1,
    'periods': 2.0,
  };
  test('compound_interest: reference formula', () {
    expect(engine.calculatorId, 'compound_interest');
    expect(number(engine.calculate(parameters(defaults))), closeTo(1210, 1e-9));
  });
  test('compound_interest: typed bind and domain validation', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final bound = engine.bind(input);
    expect(bound, isA<BoundInput<CompoundInterestParameters>>());
    expect(
      number(
        engine.calculate(
          (bound as BoundInput<CompoundInterestParameters>).parameters,
        ),
      ),
      closeTo(1210, 1e-9),
    );
    final bad = {...defaults, 'principal': -1.toDouble()};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<CompoundInterestParameters>>(),
    );
  });
  test('compound_interest: nonfinite principal', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'principal': x})),
        'principal',
      );
    }
  });
  test('compound_interest: lower bound principal', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'principal': -1.toDouble()})),
      'principal',
    );
  });
  test('compound_interest: nonfinite period_rate', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'period_rate': x})),
        'period_rate',
      );
    }
  });
  test('compound_interest: lower bound period_rate', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'period_rate': -1.toDouble()})),
      'period_rate',
    );
  });
  test('compound_interest: nonfinite periods', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'periods': x})),
        'periods',
      );
    }
  });
  test('compound_interest: lower bound periods', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'periods': -1.toDouble()})),
      'periods',
    );
  });
  test('compound_interest: upper bound periods', () {
    failsAt(
      engine.calculate(
        parameters({...defaults, 'periods': 1000001.toDouble()}),
      ),
      'periods',
    );
  });
  test('compound_interest: fractional periods are rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'periods': 1.5})),
      'periods',
    );
  });
  test('compound_interest: 20 independent Decimal formula fixtures', () {
    final rows = references('compound_interest');
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
  test('compound_interest: zero cross-field and numerical edge cases', () {
    expect(
      number(
        engine.calculate(
          const CompoundInterestParameters(
            principal: 1000,
            periodRate: 0,
            periods: 20,
          ),
        ),
      ),
      1000,
    );
    expect(
      number(
        engine.calculate(
          const CompoundInterestParameters(
            principal: 1000,
            periodRate: 0.1,
            periods: 0,
          ),
        ),
      ),
      1000,
    );
    expect(
      number(
        engine.calculate(
          const CompoundInterestParameters(
            principal: 0,
            periodRate: 0.1,
            periods: 2,
          ),
        ),
      ),
      0,
    );
    expect(
      number(
        engine.calculate(
          const CompoundInterestParameters(
            principal: 1000,
            periodRate: -0.1,
            periods: 2,
          ),
        ),
      ),
      closeTo(810, 1e-10),
    );
    final tiny = engine.calculate(
      const CompoundInterestParameters(
        principal: 1000,
        periodRate: 1e-20,
        periods: 1,
      ),
    ) as CalculationSuccess;
    expect(
      (tiny.result.details.single.value as NumericResultValue).value,
      closeTo(1e-17, 1e-30),
    );
    failure(
      engine.calculate(
        const CompoundInterestParameters(
          principal: 1e308,
          periodRate: 1,
          periods: 1000,
        ),
      ),
      'numeric_range',
    );
    failure(
      engine.calculate(
        const CompoundInterestParameters(
          principal: 1e-308,
          periodRate: -0.5,
          periods: 1000,
        ),
      ),
      'numeric_range',
    );
    expect(
      number(
        engine.calculate(
          const CompoundInterestParameters(
            principal: 1e-300,
            periodRate: 1,
            periods: 1100,
          ),
        ),
      ).isFinite,
      isTrue,
    );
  });
}
