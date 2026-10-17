import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/smed_engine.dart';

import 'helpers.dart';

SmedParameters parameters(Map<String, double> values) => SmedParameters(
  beforeTime: values['before_time']!,
  afterTime: values['after_time']!,
);
void main() {
  const engine = SmedEngine();
  const defaults = <String, double>{'before_time': 60, 'after_time': 20};
  test('smed: independent numeric reference', () {
    expect(engine.calculatorId, 'smed');
    expect(
      number(engine.calculate(parameters(defaults))),
      closeTo(0.6666666666666666, 1e-12),
    );
  });
  test('smed: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<SmedParameters>>());
    expect(
      number(
        engine.calculate((binding as BoundInput<SmedParameters>).parameters),
      ),
      closeTo(0.6666666666666666, 1e-12),
    );
    final bad = {...defaults, 'before_time': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<SmedParameters>>(),
    );
  });
  test(
    'smed: rejects negative/nonfinite before_time in direct calculation',
    () {
      for (final bad in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        failsAt(
          engine.calculate(parameters({...defaults, 'before_time': bad})),
          'before_time',
        );
      }
    },
  );
  test('smed: zero before_time is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'before_time': 0})),
      'before_time',
    );
  });
  test('smed: rejects negative/nonfinite after_time in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'after_time': bad})),
        'after_time',
      );
    }
  });
  test('smed: zero after_time is a real valid boundary', () {
    expect(
      number(engine.calculate(parameters({...defaults, 'after_time': 0}))),
      1,
    );
  });
  test(
    'smed: overflow returns Persian numeric-range failure, not Infinity',
    () {
      rangeFailure(
        engine.calculate(
          parameters({'before_time': 1e-308, 'after_time': 1e+308}),
        ),
      );
    },
  );
  test('smed: 20 independent Decimal fixtures', () {
    final cases = referenceCases('smed');
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
  test('smed: semantic and scale boundaries', () {
    final increased = engine.calculate(
      const SmedParameters(beforeTime: 60, afterTime: 90),
    ) as CalculationSuccess;
    expect(number(increased), -0.5);
    expect(increased.result.warnings.last.code, 'setup_increased');
    expect(
      (increased.result.details.single.value as NumericResultValue).value,
      -30,
    );
    expect(
      number(
        engine.calculate(const SmedParameters(beforeTime: 60, afterTime: 60)),
      ),
      0,
    );
    rangeFailure(
      engine.calculate(const SmedParameters(beforeTime: 1, afterTime: 1e307)),
    );
  });
}
