import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/wacc_engine.dart';

import 'helpers.dart';

WaccParameters parameters(Map<String, double> v) => WaccParameters(
  equity: v['equity']!,
  debt: v['debt']!,
  equityCost: v['equity_cost']!,
  debtCost: v['debt_cost']!,
  taxRate: v['tax_rate']!,
);
void main() {
  const engine = WaccEngine();
  const defaults = <String, double>{
    'equity': 600.0,
    'debt': 400.0,
    'equity_cost': 0.12,
    'debt_cost': 0.08,
    'tax_rate': 0.25,
  };
  test('wacc: reference formula', () {
    expect(engine.calculatorId, 'wacc');
    expect(
      number(engine.calculate(parameters(defaults))),
      closeTo(0.096, 1e-9),
    );
  });
  test('wacc: typed bind and domain validation', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final bound = engine.bind(input);
    expect(bound, isA<BoundInput<WaccParameters>>());
    expect(
      number(
        engine.calculate((bound as BoundInput<WaccParameters>).parameters),
      ),
      closeTo(0.096, 1e-9),
    );
    final bad = {...defaults, 'equity': -1.toDouble()};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<WaccParameters>>(),
    );
  });
  test('wacc: nonfinite equity', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'equity': x})),
        'equity',
      );
    }
  });
  test('wacc: lower bound equity', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'equity': -1.toDouble()})),
      'equity',
    );
  });
  test('wacc: nonfinite debt', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(engine.calculate(parameters({...defaults, 'debt': x})), 'debt');
    }
  });
  test('wacc: lower bound debt', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'debt': -1.toDouble()})),
      'debt',
    );
  });
  test('wacc: nonfinite equity_cost', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'equity_cost': x})),
        'equity_cost',
      );
    }
  });
  test('wacc: lower bound equity_cost', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'equity_cost': -1.toDouble()})),
      'equity_cost',
    );
  });
  test('wacc: nonfinite debt_cost', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'debt_cost': x})),
        'debt_cost',
      );
    }
  });
  test('wacc: lower bound debt_cost', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'debt_cost': -1.toDouble()})),
      'debt_cost',
    );
  });
  test('wacc: nonfinite tax_rate', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'tax_rate': x})),
        'tax_rate',
      );
    }
  });
  test('wacc: lower bound tax_rate', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'tax_rate': -1.toDouble()})),
      'tax_rate',
    );
  });
  test('wacc: upper bound tax_rate', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'tax_rate': 2.toDouble()})),
      'tax_rate',
    );
  });
  test('wacc: 20 independent Decimal formula fixtures', () {
    final rows = references('wacc');
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
  test('wacc: zero cross-field and numerical edge cases', () {
    failure(
      engine.calculate(
        const WaccParameters(
          equity: 1,
          debt: 1,
          equityCost: 0.1,
          debtCost: 5e-324,
          taxRate: 0.5,
        ),
      ),
      'numeric_range',
    );
    expect(
      number(
        engine.calculate(
          const WaccParameters(
            equity: 100,
            debt: 0,
            equityCost: 0.1,
            debtCost: 5e-324,
            taxRate: 0.5,
          ),
        ),
      ),
      0.1,
    );

    failure(
      engine.calculate(
        const WaccParameters(
          equity: 0,
          debt: 0,
          equityCost: 0.1,
          debtCost: 0.1,
          taxRate: 0,
        ),
      ),
      'zero_capital',
    );
    expect(
      number(
        engine.calculate(
          const WaccParameters(
            equity: 1e308,
            debt: 1e308,
            equityCost: 0.1,
            debtCost: 0.1,
            taxRate: 0,
          ),
        ),
      ),
      closeTo(0.1, 1e-15),
    );
    expect(
      number(
        engine.calculate(
          const WaccParameters(
            equity: 0,
            debt: 100,
            equityCost: 0.12,
            debtCost: 0.08,
            taxRate: 1,
          ),
        ),
      ),
      0,
    );
    expect(
      number(
        engine.calculate(
          const WaccParameters(
            equity: 100,
            debt: 0,
            equityCost: 0.12,
            debtCost: 0.08,
            taxRate: 0.25,
          ),
        ),
      ),
      0.12,
    );
    failure(
      engine.calculate(
        const WaccParameters(
          equity: 1e308,
          debt: 1e-308,
          equityCost: 0.1,
          debtCost: 0.1,
          taxRate: 0,
        ),
      ),
      'numeric_range',
    );
  });
}
