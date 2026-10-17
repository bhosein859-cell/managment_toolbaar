import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/wip_engine.dart';

import 'helpers.dart';

WipParameters parameters(Map<String, double> values) => WipParameters(
  throughputRate: values['throughput_rate']!,
  flowTime: values['flow_time']!,
);
void main() {
  const engine = WipEngine();
  const defaults = <String, double>{'throughput_rate': 20, 'flow_time': 3};
  test('wip: independent numeric reference', () {
    expect(engine.calculatorId, 'wip');
    expect(number(engine.calculate(parameters(defaults))), closeTo(60, 1e-12));
  });
  test('wip: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<WipParameters>>());
    expect(
      number(
        engine.calculate((binding as BoundInput<WipParameters>).parameters),
      ),
      closeTo(60, 1e-12),
    );
    final bad = {...defaults, 'throughput_rate': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<WipParameters>>(),
    );
  });
  test(
    'wip: rejects negative/nonfinite throughput_rate in direct calculation',
    () {
      for (final bad in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        failsAt(
          engine.calculate(parameters({...defaults, 'throughput_rate': bad})),
          'throughput_rate',
        );
      }
    },
  );
  test('wip: zero throughput_rate is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'throughput_rate': 0})),
      'throughput_rate',
    );
  });
  test('wip: rejects negative/nonfinite flow_time in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'flow_time': bad})),
        'flow_time',
      );
    }
  });
  test('wip: zero flow_time is a real valid boundary', () {
    expect(
      number(engine.calculate(parameters({...defaults, 'flow_time': 0}))),
      0,
    );
  });
  test('wip: overflow returns Persian numeric-range failure, not Infinity', () {
    rangeFailure(
      engine.calculate(
        parameters({'throughput_rate': 1e+308, 'flow_time': 1e+308}),
      ),
    );
  });
  test('wip: underflow is not disguised as zero', () {
    rangeFailure(
      engine.calculate(
        parameters({'throughput_rate': 1e-308, 'flow_time': 1e-308}),
      ),
    );
  });
  test('wip: 20 independent Decimal fixtures', () {
    final cases = referenceCases('wip');
    expect(cases, hasLength(20));
    for (final item in cases) {
      final input = (item['inputs'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, double.parse(value as String)),
      );
      final expected = double.parse(item['expected'] as String);
      final actual = number(engine.calculate(parameters(input)));
      final tolerance = expected.abs() * 2e-12 + 1e-14;
      expect(actual, closeTo(expected, tolerance), reason: item.toString());
    }
  });
  test('wip: semantic and scale boundaries', () {
    expect(
      number(
        engine.calculate(
          const WipParameters(throughputRate: 20, flowTime: 0.5),
        ),
      ),
      10,
    );
    expect(
      number(
        engine.calculate(
          const WipParameters(throughputRate: 1e-100, flowTime: 1e-100),
        ),
      ),
      closeTo(1e-200, 1e-212),
    );
  });
}
