import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/finance_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/irr_engine.dart';

void main() {
  const expected = {
    'npv': 41.32231404958662,
    'irr': 0.1306623862918075,
    'payback': 2.6,
    'roi': 0.2,
    'wacc': 0.096,
    'current_ratio': 2.0,
    'quick_ratio': 1.9,
    'compound_interest': 1210.0,
    'loan_payment': 88.8487886783417,
    'break_even': 250.0,
  };
  if (FinanceCalculators.runners.length != 10 ||
      AppCatalog.catalog.tools.length != 73) {
    throw StateError('Incorrect catalog count');
  }
  for (final runner in FinanceCalculators.runners) {
    final id = runner.definition.id;
    final output = runner.run(runner.definition.examples.single.inputs);
    if (output is! CalculationSuccess) throw StateError('$id failed');
    final value = (output.result.primary.value as NumericResultValue).value;
    if (!value.isFinite || (value - expected[id]!).abs() > 1e-8) {
      throw StateError('$id: $value != ${expected[id]}');
    }
    stdout.writeln('$id: $value');
  }
  for (final (flows, code) in <(List<double>, String)>[
    ([100, 50], 'no_irr'),
    ([-100, 230, -132], 'nonconventional_flows'),
  ]) {
    final outcome = const IrrEngine().calculate(IrrParameters(flows));
    if (outcome is! CalculationFailure || outcome.issues.single.code != code) {
      throw StateError('IRR failure path $code');
    }
  }
  final exhausted = const IrrEngine(maxIterations: 1)
      .calculate(IrrParameters([-1000, 600, 600]));
  if (exhausted is! CalculationFailure ||
      exhausted.issues.single.code != 'no_convergence') {
    throw StateError('IRR returned an unconverged rate');
  }
  stdout.writeln(
    'Pure Dart finance smoke: 10 engines, 73-tool catalog and IRR failure paths passed.',
  );
}
