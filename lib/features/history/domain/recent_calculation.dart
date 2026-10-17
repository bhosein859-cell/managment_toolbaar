import '../../calculators/domain/calculator_domain.dart';

/// Immutable durable snapshot; sequence is the SQLite insertion ID.
final class RecentCalculation {
  const RecentCalculation({
    required this.sequence,
    required this.calculatorId,
    required this.inputs,
    required this.result,
    required this.createdAt,
  });
  final int sequence;
  final String calculatorId;
  final RawCalculatorInput inputs;
  final CalculationResult result;
  final DateTime createdAt;
}
