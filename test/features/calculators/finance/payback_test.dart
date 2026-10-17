import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/payback_engine.dart';

import 'helpers.dart';

void main() {
  const engine = PaybackEngine();
  test(
    'payback reference is 2.6 periods with uniform intraperiod receipts',
    () {
      final output = engine.calculate(
        PaybackParameters(initialInvestment: 1000, cashFlows: [300, 400, 500]),
      );
      expect(number(output), 2.6);
      expect(
        ((output as CalculationSuccess).result.details.single.value
                as NumericResultValue)
            .value,
        3,
      );
    },
  );
  test('payback zero investment exact endpoint and zero-flow periods', () {
    expect(
      number(
        engine.calculate(
          PaybackParameters(initialInvestment: 0, cashFlows: [0]),
        ),
      ),
      0,
    );
    expect(
      number(
        engine.calculate(
          PaybackParameters(initialInvestment: 100, cashFlows: [0, 100]),
        ),
      ),
      2,
    );
    expect(
      number(
        engine.calculate(
          PaybackParameters(initialInvestment: 50, cashFlows: [100]),
        ),
      ),
      0.5,
    );
  });
  test('payback not recovered never returns a made-up period', () {
    failure(
      engine.calculate(
        PaybackParameters(initialInvestment: 1000, cashFlows: [100, 200]),
      ),
      'not_recovered',
    );
    failure(
      engine.calculate(
        PaybackParameters(initialInvestment: 1000, cashFlows: [0, 0]),
      ),
      'not_recovered',
    );
  });
  test('payback invalid initial cost direct validation', () {
    for (final value in [-1.0, double.nan, double.infinity]) {
      failsAt(
        engine.calculate(
          PaybackParameters(initialInvestment: value, cashFlows: [100]),
        ),
        'initial_investment',
      );
    }
  });
  test(
    'payback negative future flow is explicitly unsupported, not ignored',
    () {
      for (final flow in [-1.0, double.nan, double.infinity]) {
        failsAt(
          engine.calculate(
            PaybackParameters(initialInvestment: 100, cashFlows: [flow]),
          ),
          'cash_flows',
        );
      }
      for (final flows in <List<double>>[[], List.filled(1001, 1)]) {
        failure(
          engine.calculate(
            PaybackParameters(initialInvestment: 100, cashFlows: flows),
          ),
          'invalid_flow_count',
        );
      }
    },
  );
  test('payback immutable inputs typed bind and underflow safeguards', () {
    final values = <double>[100];
    final p = PaybackParameters(initialInvestment: 50, cashFlows: values);
    values[0] = 0;
    expect(number(engine.calculate(p)), 0.5);
    expect(() => p.cashFlows.clear(), throwsUnsupportedError);
    final binding = engine.bind(
      CalculatorInput({
        'initial_investment': NumberInputValue(50),
        'cash_flows': NumberListInputValue([100]),
      }),
    );
    expect(binding, isA<BoundInput<PaybackParameters>>());
    expect(
      engine.bind(
        CalculatorInput({
          'initial_investment': NumberInputValue(-1),
          'cash_flows': NumberListInputValue([100]),
        }),
      ),
      isA<RejectedInput<PaybackParameters>>(),
    );
    failure(
      engine.calculate(
        PaybackParameters(initialInvestment: 1e-300, cashFlows: [1e300]),
      ),
      'numeric_range',
    );
  });
  test('payback 20 independent Decimal fixtures', () {
    final rows = references('payback');
    expect(rows, hasLength(20));
    for (final row in rows) {
      final inputs = row['inputs'] as Map<String, dynamic>;
      final p = PaybackParameters(
        initialInvestment: double.parse(inputs['initial_investment'] as String),
        cashFlows: (inputs['cash_flows'] as List<dynamic>).map(
          (v) => double.parse(v as String),
        ),
      );
      expect(
        number(engine.calculate(p)),
        closeTo(double.parse(row['expected'] as String), 1e-10),
      );
    }
  });
}
