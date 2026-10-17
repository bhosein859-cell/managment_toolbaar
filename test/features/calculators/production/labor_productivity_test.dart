import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/production/labor_productivity_engine.dart';

import 'helpers.dart';

LaborProductivityParameters parameters(Map<String, double> values) =>
    LaborProductivityParameters(
      goodOutput: values['good_output']!,
      laborHours: values['labor_hours']!,
    );
void main() {
  const engine = LaborProductivityEngine();
  const defaults = <String, double>{'good_output': 800, 'labor_hours': 100};
  test('labor_productivity: independent numeric reference', () {
    expect(engine.calculatorId, 'labor_productivity');
    expect(number(engine.calculate(parameters(defaults))), closeTo(8, 1e-12));
  });
  test('labor_productivity: typed bind validates independently of form', () {
    final input = CalculatorInput({
      for (final e in defaults.entries) e.key: NumberInputValue(e.value),
    });
    final binding = engine.bind(input);
    expect(binding, isA<BoundInput<LaborProductivityParameters>>());
    expect(
      number(
        engine.calculate(
          (binding as BoundInput<LaborProductivityParameters>).parameters,
        ),
      ),
      closeTo(8, 1e-12),
    );
    final bad = {...defaults, 'good_output': -1.0};
    expect(
      engine.bind(
        CalculatorInput({
          for (final e in bad.entries) e.key: NumberInputValue(e.value),
        }),
      ),
      isA<RejectedInput<LaborProductivityParameters>>(),
    );
  });
  test('labor_productivity: rejects negative/nonfinite good_output in direct calculation', () {
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
  test('labor_productivity: zero good_output is a real valid boundary', () {
    expect(
      number(engine.calculate(parameters({...defaults, 'good_output': 0}))),
      0,
    );
  });
  test('labor_productivity: rejects negative/nonfinite labor_hours in direct calculation', () {
    for (final bad in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      failsAt(
        engine.calculate(parameters({...defaults, 'labor_hours': bad})),
        'labor_hours',
      );
    }
  });
  test('labor_productivity: zero labor_hours is rejected', () {
    failsAt(
      engine.calculate(parameters({...defaults, 'labor_hours': 0})),
      'labor_hours',
    );
  });
  test('labor_productivity: overflow returns Persian numeric-range failure, not Infinity', () {
    rangeFailure(
      engine.calculate(
        parameters({'good_output': 1e+308, 'labor_hours': 1e-308}),
      ),
    );
  });
  test('labor_productivity: underflow is not disguised as zero', () {
    rangeFailure(
      engine.calculate(
        parameters({'good_output': 1e-308, 'labor_hours': 1e+308}),
      ),
    );
  });
  test('labor_productivity: 20 independent Decimal fixtures', () {
    final cases = referenceCases('labor_productivity');
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
  test('labor_productivity: semantic and scale boundaries', () {
    expect(
      number(
        engine.calculate(
          const LaborProductivityParameters(goodOutput: 640, laborHours: 80),
        ),
      ),
      8,
    );
  });
}
