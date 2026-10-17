import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/production_capacity_engine.dart';

import 'helpers.dart';

ProductionCapacityParameters parameters(Map<String, double> values) =>
    ProductionCapacityParameters(
      availableTime: values['available_time']!,
      idealCycle: values['ideal_cycle']!,
      parallelResources: values['parallel_resources']!,
    );
void main() {
  const engine = ProductionCapacityEngine();
  const defaults = <String, double>{
    'available_time': 480,
    'ideal_cycle': 2,
    'parallel_resources': 2,
  };
  test('production_capacity: independent numeric reference', () {
    expect(engine.calculatorId, 'production_capacity');
    expect(number(engine.calculate(parameters(defaults))), closeTo(480, 1e-12));
  });
  test('production_capacity: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<ProductionCapacityParameters>>());
    expect(
      number(
        engine.calculate(
          (binding as BoundInput<ProductionCapacityParameters>).parameters,
        ),
      ),
      closeTo(480, 1e-12),
    );
    final bad = {...defaults, 'available_time': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<ProductionCapacityParameters>>(),
    );
  });
  test('production_capacity: rejects negative/nonfinite available_time in direct calculation', () {
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
  test('production_capacity: zero available_time is a real valid boundary', () {
    expect(
      number(engine.calculate(parameters({...defaults, 'available_time': 0}))),
      0,
    );
  });
  test('production_capacity: rejects negative/nonfinite ideal_cycle in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'ideal_cycle': bad})),
        'ideal_cycle',
      );
    }
  });
  test('production_capacity: zero ideal_cycle is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'ideal_cycle': 0})),
      'ideal_cycle',
    );
  });
  test('production_capacity: rejects negative/nonfinite parallel_resources in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'parallel_resources': bad})),
        'parallel_resources',
      );
    }
  });
  test('production_capacity: zero parallel_resources is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'parallel_resources': 0})),
      'parallel_resources',
    );
  });
  test('production_capacity: overflow returns Persian numeric-range failure, not Infinity', () {
    rangeFailure(
      engine.calculate(
        parameters({
          'available_time': 1e+308,
          'ideal_cycle': 1e-308,
          'parallel_resources': 2,
        }),
      ),
    );
  });
  test('production_capacity: underflow is not disguised as zero', () {
    rangeFailure(
      engine.calculate(
        parameters({
          'available_time': 1e-308,
          'ideal_cycle': 1e+308,
          'parallel_resources': 2,
        }),
      ),
    );
  });
  test('production_capacity: 20 independent Decimal fixtures', () {
    final cases = referenceCases('production_capacity');
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
  test('production_capacity: semantic and scale boundaries', () {
    expect(
      number(
        engine.calculate(
          const ProductionCapacityParameters(
            availableTime: 5,
            idealCycle: 2,
            parallelResources: 1,
          ),
        ),
      ),
      2.5,
    );
    for (final count in [0.5, 1.5, 1e16]) {
      failsAt(
        engine.calculate(
          ProductionCapacityParameters(
            availableTime: 480,
            idealCycle: 2,
            parallelResources: count,
          ),
        ),
        'parallel_resources',
      );
    }
    expect(
      number(
        engine.calculate(
          const ProductionCapacityParameters(
            availableTime: 1e-200,
            idealCycle: 1e-200,
            parallelResources: 3,
          ),
        ),
      ),
      3,
    );
  });
}
