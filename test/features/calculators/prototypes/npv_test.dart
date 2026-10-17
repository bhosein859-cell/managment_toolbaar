import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/npv_engine.dart';

import 'test_helpers.dart';

void main() {
  const engine = NpvEngine();
  NpvParameters parameters({
    double initial = 1000,
    double rate = 0.1,
    List<double> flows = const [600, 600],
  }) => NpvParameters(
    initialInvestment: initial,
    discountRate: rate,
    cashFlows: flows,
  );
  test('known NPV discounts CF1 and CF2, does not count CF0 twice', () {
    expect(
      valueOf(engine.calculate(parameters())),
      closeTo(41.322314049586566, 1e-10),
    );
    expect(
      valueOf(
        engine.calculate(parameters(initial: 100, rate: 1, flows: [100])),
      ),
      -50,
    );
  });
  test(
    'zero discount rate is signed cash-flow sum minus initial investment',
    () {
      expect(valueOf(engine.calculate(parameters(rate: 0))), 200);
      expect(
        valueOf(
          engine.calculate(parameters(initial: 100, rate: 0, flows: [-20, 10])),
        ),
        -110,
      );
      expect(
        valueOf(engine.calculate(parameters(initial: 0, rate: 0, flows: [0]))),
        0,
      );
    },
  );
  test('negative discount greater than -1 is valid and warned', () {
    final output = engine.calculate(
      parameters(initial: 100, rate: -0.5, flows: [100]),
    );
    expect(valueOf(output), 100);
    expect(
      (output as CalculationSuccess).result.warnings.any(
        (warning) => warning.code == 'negative_rate',
      ),
      isTrue,
    );
  });
  test('50 independent 80-digit Decimal fixtures agree within tolerance', () {
    final cases = (jsonDecode(
      File('test/fixtures/npv_reference.json').readAsStringSync(),
    ) as List<Object?>).cast<Map<String, Object?>>();
    expect(cases, hasLength(50));
    for (final item in cases) {
      final expected = double.parse(item['expected']! as String);
      final actual = valueOf(
        engine.calculate(
          parameters(
            initial: (item['initial']! as num).toDouble(),
            rate: double.parse(item['rate']! as String),
            flows: (item['flows']! as List<Object?>)
                .cast<num>()
                .map((value) => value.toDouble())
                .toList(),
          ),
        ),
      );
      expect(
        actual,
        closeTo(expected, math.max(1e-8, expected.abs() * 1e-12)),
        reason: '$item',
      );
    }
  });
  test('compensated sum retains small mixed-sign cash flows', () {
    expect(
      valueOf(
        engine.calculate(
          parameters(initial: 0, rate: 0, flows: [1e16, 1, -1e16]),
        ),
      ),
      1,
    );
  });
  test('fallback handles overflowing denominator with representable PV', () {
    final flows = List<double>.filled(400, 0)..[399] = 1e300;
    expect(
      valueOf(engine.calculate(parameters(initial: 0, rate: 9, flows: flows))),
      closeTo(1e-100, 1e-110),
    );
  });
  test('subnormal discount factor uses stable fallback rather than rounded denominator', () {
    final flows = List<double>.filled(320, 0)..[319] = 5e-324;
    // Python Decimal, 100 digits, exact binary64 CF and (1 + rate) as inputs.
    const expected = 0.00049406564584128164965213290612777;
    expect(
      valueOf(
        engine.calculate(parameters(initial: 0, rate: -0.9, flows: flows)),
      ),
      closeTo(expected, 1e-15),
    );
  });
  test('zero flows stay exactly zero at extreme valid negative rates', () {
    expect(
      valueOf(
        engine.calculate(
          parameters(initial: 0, rate: -0.9999999, flows: List.filled(1000, 0)),
        ),
      ),
      0,
    );
  });
  for (final rate in [-1.0, -1.01, double.nan, double.infinity]) {
    test('invalid direct discount $rate rejected', () {
      expect(
        codes(engine.calculate(parameters(rate: rate))),
        contains('invalid_discount_rate'),
      );
    });
  }
  test('negative/nonfinite initial investment is rejected', () {
    for (final amount in [-1.0, double.infinity, double.nan]) {
      expect(
        codes(engine.calculate(parameters(initial: amount))),
        contains('invalid_initial_investment'),
      );
    }
  });
  test('empty too-long and nonfinite series rejected', () {
    expect(
      codes(engine.calculate(parameters(flows: []))),
      contains('invalid_flow_count'),
    );
    expect(
      codes(engine.calculate(parameters(flows: List.filled(1001, 1)))),
      contains('invalid_flow_count'),
    );
    final output = engine.calculate(
      parameters(flows: [1, double.nan]),
    ) as CalculationFailure;
    expect(output.issues.single.itemIndex, 1);
  });
  test('numeric overflow and underflow produce explicit failure, not made-up result', () {
    expect(
      codes(
        engine.calculate(
          parameters(initial: 0, rate: -0.99, flows: List.filled(1000, 1e300)),
        ),
      ),
      contains('numeric_range'),
    );
    expect(
      codes(
        engine.calculate(
          parameters(initial: 0, rate: 0, flows: [1e308, 1e308]),
        ),
      ),
      contains('numeric_range'),
    );
    expect(
      codes(
        engine.calculate(parameters(initial: 0, rate: 1e308, flows: [1, 1])),
      ),
      contains('numeric_range'),
    );
  });
  test('parameters snapshot cash-flow list', () {
    final flows = [1.0, 2.0];
    final input = parameters(flows: flows);
    flows.clear();
    expect(input.cashFlows, [1, 2]);
    expect(() => input.cashFlows.clear(), throwsUnsupportedError);
  });
  test('catalog rejects exactly -100 percent and invalid initial text', () {
    final raw = <String, RawFieldInput>{
      ...PrototypeCalculators.npv.examples.single.inputs.values,
    };
    raw['discount_rate'] = const RawTextInput('−۱۰۰');
    expect(
      codes(PrototypeCalculators.npvRunner.run(RawCalculatorInput(raw))),
      contains('invalid_discount_rate'),
    );
    raw['discount_rate'] = const RawTextInput('10');
    raw['initial_investment'] = const RawTextInput('-1');
    expect(
      codes(PrototypeCalculators.npvRunner.run(RawCalculatorInput(raw))),
      contains('below_min'),
    );
  });
  test('unit changes only label, example matches known reference', () {
    final example = PrototypeCalculators.npv.examples.single;
    final raw = <String, RawFieldInput>{...example.inputs.values};
    expect(
      valueOf(PrototypeCalculators.npvRunner.run(example.inputs)),
      closeTo(41.322314049586566, 1e-10),
    );
    raw['money_unit'] = const RawTextInput('toman');
    final outcome = PrototypeCalculators.npvRunner.run(
      RawCalculatorInput(raw),
    ) as CalculationSuccess;
    expect(valueOf(outcome), closeTo(41.322314049586566, 1e-10));
    expect((outcome.result.primary.value as NumericResultValue).unit, 'تومان');
  });
  test('direct bind rejects invalid rate and currency', () {
    CalculatorInput input(String unit, double rate) => CalculatorInput({
      'initial_investment': NumberInputValue(1),
      'discount_rate': NumberInputValue(rate),
      'cash_flows': NumberListInputValue([1]),
      'money_unit': ChoiceInputValue(unit),
    });
    expect(engine.bind(input('rial', -1)), isA<RejectedInput<NpvParameters>>());
    expect(
      engine.bind(input('unknown', 0.1)),
      isA<RejectedInput<NpvParameters>>(),
    );
  });
}
