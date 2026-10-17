// Pure Dart smoke check for the three compiled engines; no Flutter runtime.
import 'dart:io';

import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/cp_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/npv_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/oee_engine.dart';

double checkedValue(CalculationOutcome outcome, double expected) {
  if (outcome is! CalculationSuccess ||
      outcome.result.primary.value is! NumericResultValue) {
    throw StateError('موتور نتیجهٔ عددی معتبر تولید نکرد');
  }
  final value = (outcome.result.primary.value as NumericResultValue).value;
  if ((value - expected).abs() > 1e-9) {
    throw StateError('نتیجه با مرجع عددی یکسان نیست');
  }
  return value;
}

void main() {
  final oee = checkedValue(
    const OeeEngine().calculate(
      const OeeParameters(availability: 0.9, performance: 0.95, quality: 0.98),
    ),
    0.8379,
  );
  final npv = checkedValue(
    const NpvEngine().calculate(
      NpvParameters(
        initialInvestment: 1000,
        discountRate: 0.1,
        cashFlows: [600, 600],
      ),
    ),
    41.322314049586566,
  );
  final cp = checkedValue(
    const CpEngine().calculate(const CpParameters(usl: 110, lsl: 90, sigma: 2)),
    1.6666666666666667,
  );
  stdout.writeln(
    'Pure Dart prototype engines passed: OEE=$oee; NPV=$npv; Cp=$cp',
  );
}
