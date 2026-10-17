import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/quick_ratio_engine.dart';

import 'helpers.dart';

QuickRatioParameters parameters(Map<String, double> v) => QuickRatioParameters(
  currentAssets: v['current_assets']!,
  inventory: v['inventory']!,
  prepayments: v['prepayments']!,
  currentLiabilities: v['current_liabilities']!,
);
void main() {
  const engine = QuickRatioEngine();
  const defaults = <String, double>{
    'current_assets': 500.0,
    'inventory': 100.0,
    'prepayments': 20.0,
    'current_liabilities': 200.0,
  };
  test('quick_ratio: reference formula', () {
    expect(engine.calculatorId, 'quick_ratio');
    expect(number(engine.calculate(parameters(defaults))), closeTo(1.9, 1e-9));
  });
  test('quick_ratio: typed bind and domain validation', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final bound = engine.bind(input);
    expect(bound, isA<BoundInput<QuickRatioParameters>>());
    expect(
      number(
        engine.calculate(
          (bound as BoundInput<QuickRatioParameters>).parameters,
        ),
      ),
      closeTo(1.9, 1e-9),
    );
    final bad = {...defaults, 'current_assets': -1.toDouble()};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<QuickRatioParameters>>(),
    );
  });
  test('quick_ratio: nonfinite current_assets', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'current_assets': x})),
        'current_assets',
      );
    }
  });
  test('quick_ratio: lower bound current_assets', () {
    failsAt(
      engine.calculate(
        parameters({...defaults, 'current_assets': -1.toDouble()}),
      ),
      'current_assets',
    );
  });
  test('quick_ratio: nonfinite inventory', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'inventory': x})),
        'inventory',
      );
    }
  });
  test('quick_ratio: lower bound inventory', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'inventory': -1.toDouble()})),
      'inventory',
    );
  });
  test('quick_ratio: nonfinite prepayments', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'prepayments': x})),
        'prepayments',
      );
    }
  });
  test('quick_ratio: lower bound prepayments', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'prepayments': -1.toDouble()})),
      'prepayments',
    );
  });
  test('quick_ratio: nonfinite current_liabilities', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'current_liabilities': x})),
        'current_liabilities',
      );
    }
  });
  test('quick_ratio: lower bound current_liabilities', () {
    failsAt(
      engine.calculate(
        parameters({...defaults, 'current_liabilities': 0.toDouble()}),
      ),
      'current_liabilities',
    );
  });
  test('quick_ratio: 20 independent Decimal formula fixtures', () {
    final rows = references('quick_ratio');
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
  test('quick_ratio: zero cross-field and numerical edge cases', () {
    failure(
      engine.calculate(
        const QuickRatioParameters(
          currentAssets: 100,
          inventory: 90,
          prepayments: 20,
          currentLiabilities: 50,
        ),
      ),
      'inconsistent_assets',
    );
    failure(
      engine.calculate(
        const QuickRatioParameters(
          currentAssets: 100,
          inventory: 101,
          prepayments: 0,
          currentLiabilities: 50,
        ),
      ),
      'inconsistent_assets',
    );
    expect(
      number(
        engine.calculate(
          const QuickRatioParameters(
            currentAssets: 100,
            inventory: 100,
            prepayments: 0,
            currentLiabilities: 50,
          ),
        ),
      ),
      0,
    );
    failure(
      engine.calculate(
        const QuickRatioParameters(
          currentAssets: 1e308,
          inventory: 0,
          prepayments: 0,
          currentLiabilities: 1e-308,
        ),
      ),
      'numeric_range',
    );
  });
}
