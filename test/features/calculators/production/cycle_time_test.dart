import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/cycle_time_engine.dart';

import 'helpers.dart';

CycleTimeParameters parameters(Map<String, double> values) =>
    CycleTimeParameters(
      runTime: values['run_time']!,
      totalOutput: values['total_output']!,
    );
void main() {
  const engine = CycleTimeEngine();
  const defaults = <String, double>{'run_time': 420, 'total_output': 210};
  test('cycle_time: independent numeric reference', () {
    expect(engine.calculatorId, 'cycle_time');
    expect(number(engine.calculate(parameters(defaults))), closeTo(2, 1e-12));
  });
  test('cycle_time: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<CycleTimeParameters>>());
    expect(
      number(
        engine.calculate(
          (binding as BoundInput<CycleTimeParameters>).parameters,
        ),
      ),
      closeTo(2, 1e-12),
    );
    final bad = {...defaults, 'run_time': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<CycleTimeParameters>>(),
    );
  });
  test(
    'cycle_time: rejects negative/nonfinite run_time in direct calculation',
    () {
      for (final bad in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        failsAt(
          engine.calculate(parameters({...defaults, 'run_time': bad})),
          'run_time',
        );
      }
    },
  );
  test('cycle_time: zero run_time is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'run_time': 0})),
      'run_time',
    );
  });
  test(
    'cycle_time: rejects negative/nonfinite total_output in direct calculation',
    () {
      for (final bad in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        failsAt(
          engine.calculate(parameters({...defaults, 'total_output': bad})),
          'total_output',
        );
      }
    },
  );
  test('cycle_time: zero total_output is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'total_output': 0})),
      'total_output',
    );
  });
  test(
    'cycle_time: overflow returns Persian numeric-range failure, not Infinity',
    () {
      rangeFailure(
        engine.calculate(
          parameters({'run_time': 1e+308, 'total_output': 1e-308}),
        ),
      );
    },
  );
  test('cycle_time: underflow is not disguised as zero', () {
    rangeFailure(
      engine.calculate(
        parameters({'run_time': 1e-308, 'total_output': 1e+308}),
      ),
    );
  });
  test('cycle_time: 20 independent Decimal fixtures', () {
    final cases = referenceCases('cycle_time');
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
  test('cycle_time: semantic and scale boundaries', () {
    expect(
      number(
        engine.calculate(
          const CycleTimeParameters(runTime: 90, totalOutput: 50),
        ),
      ),
      1.8,
    );
  });
}
