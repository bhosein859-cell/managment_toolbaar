import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/oee_engine.dart';

import 'test_helpers.dart';

void main() {
  const engine = OeeEngine();
  test(
    'required reference gives fraction 0.8379 and percentage output metadata',
    () {
      final outcome = engine.calculate(
        const OeeParameters(
          availability: 0.90,
          performance: 0.95,
          quality: 0.98,
        ),
      );
      expect(valueOf(outcome), closeTo(0.8379, 1e-14));
      final metric =
          ((outcome as CalculationSuccess).result.primary.value
              as NumericResultValue);
      expect(metric.display, NumberDisplay.percentage);
      expect(metric.value * 100, closeTo(83.79, 1e-12));
    },
  );
  test(
    'catalog percentages normalize once and examples match expected value',
    () {
      final definition = PrototypeCalculators.oee;
      final example = definition.examples.single;
      expect(
        valueOf(PrototypeCalculators.oeeRunner.run(example.inputs)),
        closeTo(0.8379, 1e-14),
      );
      expect(
        (example.expectedResult!.primary.value as NumericResultValue).value,
        0.8379,
      );
    },
  );
  for (final field in ['availability', 'performance', 'quality']) {
    for (final zero in [true, false]) {
      test('$field at ${zero ? 0 : 100} percent is handled', () {
        final input = {
          'availability': '100',
          'performance': '100',
          'quality': '100',
        };
        input[field] = zero ? '0' : '100';
        expect(
          valueOf(PrototypeCalculators.oeeRunner.run(textInput(input))),
          zero ? 0 : 1,
        );
      });
    }
    for (final invalid in ['-1', '100.01', 'NaN', '', 'Infinity']) {
      test('invalid $field "$invalid" is rejected with field issue', () {
        final input = {
          'availability': '90',
          'performance': '95',
          'quality': '98',
        };
        input[field] = invalid;
        final output = PrototypeCalculators.oeeRunner.run(textInput(input));
        expect(output, isA<CalculationFailure>());
        expect(
          (output as CalculationFailure).issues.any(
            (issue) => issue.fieldId == field,
          ),
          isTrue,
        );
      });
    }
  }
  test('typed engine validates all ratios even outside normalizer', () {
    final output = engine.calculate(
      const OeeParameters(
        availability: double.nan,
        performance: 1.01,
        quality: -1,
      ),
    );
    expect(codes(output), ['invalid_ratio', 'invalid_ratio', 'invalid_ratio']);
    expect(
      engine.bind(
        CalculatorInput({
          'availability': NumberInputValue(-1),
          'performance': NumberInputValue(1),
          'quality': NumberInputValue(1),
        }),
      ),
      isA<RejectedInput<OeeParameters>>(),
    );
  });
  test(
    'underflow is not silently reported as zero for all-positive inputs',
    () {
      expect(
        codes(
          engine.calculate(
            const OeeParameters(
              availability: 1e-200,
              performance: 1e-200,
              quality: 1,
            ),
          ),
        ),
        contains('numeric_range'),
      );
    },
  );
  for (final digits in [
    ['۹۰', '۹۵', '۹۸'],
    ['٩٠', '٩٥', '٩٨'],
    ['90', '95', '98'],
  ]) {
    test('accepts digit set ${digits.first}', () {
      final result = PrototypeCalculators.oeeRunner.run(
        textInput({
          'availability': digits[0],
          'performance': digits[1],
          'quality': digits[2],
        }),
      );
      expect(valueOf(result), closeTo(0.8379, 1e-14));
    });
  }
}
