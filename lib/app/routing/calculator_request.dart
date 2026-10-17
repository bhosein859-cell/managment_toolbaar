import '../../features/calculators/domain/calculator_domain.dart';

final class CalculatorRequest {
  const CalculatorRequest(this.calculatorId, {this.inputs});
  final String calculatorId;
  final RawCalculatorInput? inputs;
}
