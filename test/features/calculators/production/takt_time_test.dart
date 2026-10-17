import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/takt_time_engine.dart';

import 'helpers.dart';

TaktTimeParameters parameters(Map<String, double> values) => TaktTimeParameters(
  availableTime: values['available_time']!,
  demand: values['demand']!,
);
void main() {
  const engine = TaktTimeEngine();
  const defaults = <String, double>{'available_time': 420, 'demand': 210};
  test('takt_time: independent numeric reference', () {
    expect(engine.calculatorId, 'takt_time');
    expect(number(engine.calculate(parameters(defaults))), closeTo(2, 1e-12));
  });
  test('takt_time: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<TaktTimeParameters>>());
    expect(
      number(
        engine.calculate(
          (binding as BoundInput<TaktTimeParameters>).parameters,
        ),
      ),
      closeTo(2, 1e-12),
    );
    final bad = {...defaults, 'available_time': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<TaktTimeParameters>>(),
    );
  });
  test('takt_time: rejects negative/nonfinite available_time in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'available_time': bad})),
        'available_time',
      );
    }
  });
  test('takt_time: zero available_time is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'available_time': 0})),
      'available_time',
    );
  });
  test(
    'takt_time: rejects negative/nonfinite demand in direct calculation',
    () {
      for (final bad in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        failsAt(
          engine.calculate(parameters({...defaults, 'demand': bad})),
          'demand',
        );
      }
    },
  );
  test('takt_time: zero demand is rejected', () {
    failsAt(engine.calculate(parameters({...defaults, 'demand': 0})), 'demand');
  });
  test(
    'takt_time: overflow returns Persian numeric-range failure, not Infinity',
    () {
      rangeFailure(
        engine.calculate(
          parameters({'available_time': 1e+308, 'demand': 1e-308}),
        ),
      );
    },
  );
  test('takt_time: underflow is not disguised as zero', () {
    rangeFailure(
      engine.calculate(
        parameters({'available_time': 1e-308, 'demand': 1e+308}),
      ),
    );
  });
  test('takt_time: 20 independent Decimal fixtures', () {
    final cases = referenceCases('takt_time');
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
  test('takt_time: semantic and scale boundaries', () {
    expect(
      number(
        engine.calculate(
          const TaktTimeParameters(availableTime: 420, demand: 420),
        ),
      ),
      1,
    );
  });
}
