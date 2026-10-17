import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/roi_engine.dart';

import 'helpers.dart';

RoiParameters parameters(Map<String, double> v) =>
    RoiParameters(netProfit: v['net_profit']!, investment: v['investment']!);
void main() {
  const engine = RoiEngine();
  const defaults = <String, double>{'net_profit': 200.0, 'investment': 1000.0};
  test('roi: reference formula', () {
    expect(engine.calculatorId, 'roi');
    expect(number(engine.calculate(parameters(defaults))), closeTo(0.2, 1e-9));
  });
  test('roi: typed bind and domain validation', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final bound = engine.bind(input);
    expect(bound, isA<BoundInput<RoiParameters>>());
    expect(
      number(engine.calculate((bound as BoundInput<RoiParameters>).parameters)),
      closeTo(0.2, 1e-9),
    );
    final bad = {...defaults, 'investment': 0.toDouble()};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<RoiParameters>>(),
    );
  });
  test('roi: nonfinite net_profit', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'net_profit': x})),
        'net_profit',
      );
    }
  });
  test('roi: nonfinite investment', () {
    for (final x in [double.nan, double.infinity, double.negativeInfinity]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'investment': x})),
        'investment',
      );
    }
  });
  test('roi: lower bound investment', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'investment': 0.toDouble()})),
      'investment',
    );
  });
  test('roi: 20 independent Decimal formula fixtures', () {
    final rows = references('roi');
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
  test('roi: zero cross-field and numerical edge cases', () {
    expect(
      number(
        engine.calculate(
          const RoiParameters(netProfit: -1500, investment: 1000),
        ),
      ),
      -1.5,
    );
    expect(
      number(
        engine.calculate(const RoiParameters(netProfit: 0, investment: 1000)),
      ),
      0,
    );
    failure(
      engine.calculate(
        const RoiParameters(netProfit: 1e308, investment: 1e-308),
      ),
      'numeric_range',
    );
    failure(
      engine.calculate(
        const RoiParameters(netProfit: 1e-308, investment: 1e308),
      ),
      'numeric_range',
    );
  });
}
