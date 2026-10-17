import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/current_ratio_engine.dart';

import 'helpers.dart';

CurrentRatioParameters parameters(Map<String, double> v) =>
    CurrentRatioParameters(
      currentAssets: v['current_assets']!,
      currentLiabilities: v['current_liabilities']!,
    );
void main() {
  const engine = CurrentRatioEngine();
  const defaults = <String, double>{
    'current_assets': 400.0,
    'current_liabilities': 200.0,
  };
  test('current_ratio: reference formula', () {
    expect(engine.calculatorId, 'current_ratio');
    expect(number(engine.calculate(parameters(defaults))), closeTo(2, 1e-9));
  });
  test('current_ratio: typed bind and domain validation', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final bound = engine.bind(input);
    expect(bound, isA<BoundInput<CurrentRatioParameters>>());
    expect(
      number(
        engine.calculate(
          (bound as BoundInput<CurrentRatioParameters>).parameters,
        ),
      ),
      closeTo(2, 1e-9),
    );
    final bad = {...defaults, 'current_assets': -1.toDouble()};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<CurrentRatioParameters>>(),
    );
  });
  test('current_ratio: nonfinite current_assets', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'current_assets': x})),
        'current_assets',
      );
    }
  });
  test('current_ratio: lower bound current_assets', () {
    failsAt(
      engine.calculate(
        parameters({...defaults, 'current_assets': -1.toDouble()}),
      ),
      'current_assets',
    );
  });
  test('current_ratio: nonfinite current_liabilities', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'current_liabilities': x})),
        'current_liabilities',
      );
    }
  });
  test('current_ratio: lower bound current_liabilities', () {
    failsAt(
      engine.calculate(
        parameters({...defaults, 'current_liabilities': 0.toDouble()}),
      ),
      'current_liabilities',
    );
  });
  test('current_ratio: 20 independent Decimal formula fixtures', () {
    final rows = references('current_ratio');
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
  test('current_ratio: zero cross-field and numerical edge cases', () {
    expect(
      number(
        engine.calculate(
          const CurrentRatioParameters(currentAssets: 0, currentLiabilities: 1),
        ),
      ),
      0,
    );
    failure(
      engine.calculate(
        const CurrentRatioParameters(
          currentAssets: 1e308,
          currentLiabilities: 1e-308,
        ),
      ),
      'numeric_range',
    );
    failure(
      engine.calculate(
        const CurrentRatioParameters(
          currentAssets: 1e-308,
          currentLiabilities: 1e308,
        ),
      ),
      'numeric_range',
    );
  });
}
