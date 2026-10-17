import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/cp_engine.dart';

import 'test_helpers.dart';

void main() {
  const engine = CpEngine();
  test('known examples and dimensionless result', () {
    expect(
      valueOf(
        engine.calculate(const CpParameters(usl: 110, lsl: 90, sigma: 2)),
      ),
      closeTo(1.6666666666666667, 1e-14),
    );
    final example = PrototypeCalculators.cp.examples.single;
    final outcome =
        PrototypeCalculators.cpRunner.run(example.inputs) as CalculationSuccess;
    expect(valueOf(outcome), 1);
    expect((outcome.result.primary.value as NumericResultValue).unit, isNull);
    expect(outcome.result.warnings, hasLength(2));
  });
  test(
    'negative specification limits are valid, common unit scaling invariant',
    () {
      expect(
        valueOf(
          engine.calculate(const CpParameters(usl: -4, lsl: -10, sigma: 1)),
        ),
        1,
      );
      expect(
        valueOf(
          engine.calculate(
            const CpParameters(
              usl: 10000,
              lsl: 4000,
              sigma: 1000,
              unit: CapabilityUnit.generic,
            ),
          ),
        ),
        1,
      );
    },
  );
  for (final limits in [(10.0, 10.0), (9.0, 10.0)]) {
    test('equal or reversed limits $limits rejected', () {
      expect(
        codes(
          engine.calculate(
            CpParameters(usl: limits.$1, lsl: limits.$2, sigma: 1),
          ),
        ),
        contains('invalid_limits'),
      );
    });
  }
  for (final sigma in [0.0, -1.0, double.nan, double.infinity]) {
    test('invalid sigma $sigma rejected', () {
      expect(
        codes(engine.calculate(CpParameters(usl: 10, lsl: 4, sigma: sigma))),
        contains('invalid_sigma'),
      );
    });
  }
  test('nonfinite specification limits rejected independently', () {
    expect(
      codes(
        engine.calculate(
          const CpParameters(usl: double.infinity, lsl: double.nan, sigma: 1),
        ),
      ),
      ['invalid_usl', 'invalid_lsl'],
    );
  });
  test(
    'very large common scale avoids intermediate width/denominator overflow',
    () {
      expect(
        valueOf(
          engine.calculate(
            const CpParameters(usl: 1e308, lsl: -1e308, sigma: 1e308),
          ),
        ),
        closeTo(1 / 3, 1e-14),
      );
      expect(
        valueOf(
          engine.calculate(const CpParameters(usl: 1e308, lsl: 0, sigma: 0.2)),
        ),
        closeTo(8.333333333333333e307, 1e294),
      );
    },
  );
  test('subnormal common scale does not create a false zero', () {
    expect(
      valueOf(
        engine.calculate(
          const CpParameters(usl: 5e-324, lsl: 0, sigma: 5e-324),
        ),
      ),
      closeTo(1 / 6, 1e-14),
    );
  });
  test('unrepresentable huge/tiny Cp produces range failure', () {
    expect(
      codes(
        engine.calculate(const CpParameters(usl: 1e308, lsl: 0, sigma: 5e-324)),
      ),
      contains('numeric_range'),
    );
    expect(
      codes(
        engine.calculate(const CpParameters(usl: 5e-324, lsl: 0, sigma: 1e308)),
      ),
      contains('numeric_range'),
    );
  });
  test('catalog sigma zero and relationship errors are field-specific', () {
    final raw = <String, RawFieldInput>{
      ...PrototypeCalculators.cp.examples.single.inputs.values,
    };
    raw['sigma'] = const RawTextInput('۰');
    final output = PrototypeCalculators.cpRunner.run(
      RawCalculatorInput(raw),
    ) as CalculationFailure;
    expect(output.issues.single.fieldId, 'sigma');
    raw['sigma'] = const RawTextInput('۱');
    raw['usl'] = const RawTextInput('۳');
    expect(
      codes(PrototypeCalculators.cpRunner.run(RawCalculatorInput(raw))),
      contains('invalid_limits'),
    );
  });
  test('direct bind checks limits and all declared measurement units work', () {
    for (final unit in ['mm', 'cm', 'seconds', 'generic']) {
      final raw = <String, RawFieldInput>{
        ...PrototypeCalculators.cp.examples.single.inputs.values,
      };
      raw['measurement_unit'] = RawTextInput(unit);
      expect(
        valueOf(PrototypeCalculators.cpRunner.run(RawCalculatorInput(raw))),
        1,
      );
    }
    CalculatorInput input(String unit, double upper) => CalculatorInput({
      'usl': NumberInputValue(upper),
      'lsl': NumberInputValue(4),
      'sigma': NumberInputValue(1),
      'measurement_unit': ChoiceInputValue(unit),
    });
    expect(engine.bind(input('bad', 10)), isA<RejectedInput<CpParameters>>());
    expect(engine.bind(input('mm', 3)), isA<RejectedInput<CpParameters>>());
  });
}
