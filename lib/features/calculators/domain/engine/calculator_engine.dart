import '../models/calculation_result.dart';
import '../models/calculator_input.dart';

/// Each calculator supplies a dedicated immutable parameter class.
abstract interface class CalculatorParameters {}

sealed class InputBinding<I extends CalculatorParameters> {
  const InputBinding();
}

final class BoundInput<I extends CalculatorParameters> extends InputBinding<I> {
  const BoundInput(this.parameters);
  final I parameters;
}

/// Cross-field/domain-specific validation belongs in the engine binding step.
final class RejectedInput<I extends CalculatorParameters>
    extends InputBinding<I> {
  RejectedInput(Iterable<CalculationIssue> issues)
    : issues = List.unmodifiable(issues) {
    if (this.issues.isEmpty) throw ArgumentError('خطا نباید خالی باشد');
  }
  final List<CalculationIssue> issues;
}

abstract interface class CalculatorEngine<I extends CalculatorParameters> {
  String get calculatorId;
  InputBinding<I> bind(CalculatorInput input);
  CalculationOutcome calculate(I parameters);
}
