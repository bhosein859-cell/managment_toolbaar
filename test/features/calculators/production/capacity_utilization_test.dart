import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/capacity_utilization_engine.dart';

import 'helpers.dart';

CapacityUtilizationParameters parameters(Map<String, double> values) =>
    CapacityUtilizationParameters(
      actualOutput: values['actual_output']!,
      designCapacity: values['design_capacity']!,
    );
void main() {
  const engine = CapacityUtilizationEngine();
  const defaults = <String, double>{
    'actual_output': 360,
    'design_capacity': 480,
  };
  test('capacity_utilization: independent numeric reference', () {
    expect(engine.calculatorId, 'capacity_utilization');
    expect(
      number(engine.calculate(parameters(defaults))),
      closeTo(0.75, 1e-12),
    );
  });
  test('capacity_utilization: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<CapacityUtilizationParameters>>());
    expect(
      number(
        engine.calculate(
          (binding as BoundInput<CapacityUtilizationParameters>).parameters,
        ),
      ),
      closeTo(0.75, 1e-12),
    );
    final bad = {...defaults, 'actual_output': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<CapacityUtilizationParameters>>(),
    );
  });
  test('capacity_utilization: rejects negative/nonfinite actual_output in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'actual_output': bad})),
        'actual_output',
      );
    }
  });
  test('capacity_utilization: zero actual_output is a real valid boundary', () {
    expect(
      number(engine.calculate(parameters({...defaults, 'actual_output': 0}))),
      0,
    );
  });
  test('capacity_utilization: rejects negative/nonfinite design_capacity in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'design_capacity': bad})),
        'design_capacity',
      );
    }
  });
  test('capacity_utilization: zero design_capacity is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'design_capacity': 0})),
      'design_capacity',
    );
  });
  test('capacity_utilization: overflow returns Persian numeric-range failure, not Infinity', () {
    rangeFailure(
      engine.calculate(
        parameters({'actual_output': 1e+308, 'design_capacity': 1e-308}),
      ),
    );
  });
  test('capacity_utilization: underflow is not disguised as zero', () {
    rangeFailure(
      engine.calculate(
        parameters({'actual_output': 1e-308, 'design_capacity': 1e+308}),
      ),
    );
  });
  test('capacity_utilization: 20 independent Decimal fixtures', () {
    final cases = referenceCases('capacity_utilization');
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
  test('capacity_utilization: semantic and scale boundaries', () {
    final over = engine.calculate(
      const CapacityUtilizationParameters(
        actualOutput: 720,
        designCapacity: 480,
      ),
    ) as CalculationSuccess;
    expect(number(over), 1.5);
    expect(over.result.warnings.last.code, 'above_design_capacity');
    expect(
      number(
        engine.calculate(
          const CapacityUtilizationParameters(
            actualOutput: 480,
            designCapacity: 480,
          ),
        ),
      ),
      1,
    );
    rangeFailure(
      engine.calculate(
        const CapacityUtilizationParameters(
          actualOutput: 1e307,
          designCapacity: 1,
        ),
      ),
    );
  });
}
