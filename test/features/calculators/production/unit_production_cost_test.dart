import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/unit_production_cost_engine.dart';

import 'helpers.dart';

UnitProductionCostParameters parameters(Map<String, double> values) =>
    UnitProductionCostParameters(
      allocatedCost: values['allocated_cost']!,
      goodOutput: values['good_output']!,
    );
void main() {
  const engine = UnitProductionCostEngine();
  const defaults = <String, double>{
    'allocated_cost': 1500000,
    'good_output': 500,
  };
  test('unit_production_cost: independent numeric reference', () {
    expect(engine.calculatorId, 'unit_production_cost');
    expect(
      number(engine.calculate(parameters(defaults))),
      closeTo(3000, 1e-12),
    );
  });
  test('unit_production_cost: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<UnitProductionCostParameters>>());
    expect(
      number(
        engine.calculate(
          (binding as BoundInput<UnitProductionCostParameters>).parameters,
        ),
      ),
      closeTo(3000, 1e-12),
    );
    final bad = {...defaults, 'allocated_cost': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<UnitProductionCostParameters>>(),
    );
  });
  test('unit_production_cost: rejects negative/nonfinite allocated_cost in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'allocated_cost': bad})),
        'allocated_cost',
      );
    }
  });
  test(
    'unit_production_cost: zero allocated_cost is a real valid boundary',
    () {
      expect(
        number(
          engine.calculate(parameters({...defaults, 'allocated_cost': 0})),
        ),
        0,
      );
    },
  );
  test('unit_production_cost: rejects negative/nonfinite good_output in direct calculation', () {
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
  });
  test('unit_production_cost: zero good_output is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'good_output': 0})),
      'good_output',
    );
  });
  test('unit_production_cost: overflow returns Persian numeric-range failure, not Infinity', () {
    rangeFailure(
      engine.calculate(
        parameters({'allocated_cost': 1e+308, 'good_output': 1e-308}),
      ),
    );
  });
  test('unit_production_cost: underflow is not disguised as zero', () {
    rangeFailure(
      engine.calculate(
        parameters({'allocated_cost': 1e-308, 'good_output': 1e+308}),
      ),
    );
  });
  test('unit_production_cost: 20 independent Decimal fixtures', () {
    final cases = referenceCases('unit_production_cost');
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
  test('unit_production_cost: semantic and scale boundaries', () {
    expect(
      number(
        engine.calculate(
          const UnitProductionCostParameters(
            allocatedCost: 1e-200,
            goodOutput: 1e-200,
          ),
        ),
      ),
      1,
    );
  });
}
