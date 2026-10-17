import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/loan_payment_engine.dart';

import 'helpers.dart';

LoanPaymentParameters parameters(Map<String, double> v) =>
    LoanPaymentParameters(
      principal: v['principal']!,
      periodRate: v['period_rate']!,
      periods: v['periods']!,
    );
void main() {
  const engine = LoanPaymentEngine();
  const defaults = <String, double>{
    'principal': 1000.0,
    'period_rate': 0.01,
    'periods': 12.0,
  };
  test('loan_payment: reference formula', () {
    expect(engine.calculatorId, 'loan_payment');
    expect(
      number(engine.calculate(parameters(defaults))),
      closeTo(88.8487886783417, 1e-9),
    );
  });
  test('loan_payment: typed bind and domain validation', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final bound = engine.bind(input);
    expect(bound, isA<BoundInput<LoanPaymentParameters>>());
    expect(
      number(
        engine.calculate(
          (bound as BoundInput<LoanPaymentParameters>).parameters,
        ),
      ),
      closeTo(88.8487886783417, 1e-9),
    );
    final bad = {...defaults, 'principal': -1.toDouble()};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<LoanPaymentParameters>>(),
    );
  });
  test('loan_payment: nonfinite principal', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'principal': x})),
        'principal',
      );
    }
  });
  test('loan_payment: lower bound principal', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'principal': -1.toDouble()})),
      'principal',
    );
  });
  test('loan_payment: nonfinite period_rate', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'period_rate': x})),
        'period_rate',
      );
    }
  });
  test('loan_payment: lower bound period_rate', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'period_rate': -1.toDouble()})),
      'period_rate',
    );
  });
  test('loan_payment: nonfinite periods', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'periods': x})),
        'periods',
      );
    }
  });
  test('loan_payment: lower bound periods', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'periods': 0.toDouble()})),
      'periods',
    );
  });
  test('loan_payment: upper bound periods', () {
    failsAt(
      engine.calculate(
        parameters({...defaults, 'periods': 1000001.toDouble()}),
      ),
      'periods',
    );
  });
  test('loan_payment: fractional periods are rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'periods': 1.5})),
      'periods',
    );
  });
  test('loan_payment: 20 independent Decimal formula fixtures', () {
    final rows = references('loan_payment');
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
  test('loan_payment: zero cross-field and numerical edge cases', () {
    final zero = engine.calculate(
      const LoanPaymentParameters(principal: 1000, periodRate: 0, periods: 10),
    ) as CalculationSuccess;
    expect(number(zero), 100);
    expect((zero.result.details.last.value as NumericResultValue).value, 0);
    expect(
      number(
        engine.calculate(
          const LoanPaymentParameters(
            principal: 0,
            periodRate: 0.1,
            periods: 10,
          ),
        ),
      ),
      0,
    );
    expect(
      number(
        engine.calculate(
          const LoanPaymentParameters(
            principal: 1000,
            periodRate: 0.1,
            periods: 1,
          ),
        ),
      ),
      closeTo(1100, 1e-10),
    );
    failure(
      engine.calculate(
        const LoanPaymentParameters(
          principal: 1.5e308,
          periodRate: 0.1,
          periods: 12,
        ),
      ),
      'numeric_range',
    );
    failure(
      engine.calculate(
        const LoanPaymentParameters(
          principal: 1000,
          periodRate: 1e-20,
          periods: 12,
        ),
      ),
      'numeric_range',
    );
  });
}
