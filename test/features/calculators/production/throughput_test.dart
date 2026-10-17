import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/throughput_engine.dart';

import 'helpers.dart';

ThroughputParameters parameters(Map<String, double> values) =>
    ThroughputParameters(
      goodOutput: values['good_output']!,
      elapsedTime: values['elapsed_time']!,
    );
void main() {
  const engine = ThroughputEngine();
  const defaults = <String, double>{'good_output': 240, 'elapsed_time': 8};
  test('throughput: independent numeric reference', () {
    expect(engine.calculatorId, 'throughput');
    expect(number(engine.calculate(parameters(defaults))), closeTo(30, 1e-12));
  });
  test('throughput: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<ThroughputParameters>>());
    expect(
      number(
        engine.calculate(
          (binding as BoundInput<ThroughputParameters>).parameters,
        ),
      ),
      closeTo(30, 1e-12),
    );
    final bad = {...defaults, 'good_output': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<ThroughputParameters>>(),
    );
  });
  test(
    'throughput: rejects negative/nonfinite good_output in direct calculation',
    () {
      for (final bad in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        failsAt(
          engine.calculate(parameters({...defaults, 'good_output': bad})),
          'good_output',
        );
      }
    },
  );
  test('throughput: zero good_output is a real valid boundary', () {
    expect(
      number(engine.calculate(parameters({...defaults, 'good_output': 0}))),
      0,
    );
  });
  test(
    'throughput: rejects negative/nonfinite elapsed_time in direct calculation',
    () {
      for (final bad in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        failsAt(
          engine.calculate(parameters({...defaults, 'elapsed_time': bad})),
          'elapsed_time',
        );
      }
    },
  );
  test('throughput: zero elapsed_time is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'elapsed_time': 0})),
      'elapsed_time',
    );
  });
  test(
    'throughput: overflow returns Persian numeric-range failure, not Infinity',
    () {
      rangeFailure(
        engine.calculate(
          parameters({'good_output': 1e+308, 'elapsed_time': 1e-308}),
        ),
      );
    },
  );
  test('throughput: underflow is not disguised as zero', () {
    rangeFailure(
      engine.calculate(
        parameters({'good_output': 1e-308, 'elapsed_time': 1e+308}),
      ),
    );
  });
  test('throughput: 20 independent Decimal fixtures', () {
    final cases = referenceCases('throughput');
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
  test('throughput: semantic and scale boundaries', () {
    expect(
      number(
        engine.calculate(
          const ThroughputParameters(goodOutput: 12, elapsedTime: 0.5),
        ),
      ),
      24,
    );
  });
}
