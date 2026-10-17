import '../../calculator_domain.dart';
import 'production_support.dart';

final class LaborProductivityParameters implements CalculatorParameters {
  const LaborProductivityParameters({
    required this.goodOutput,
    required this.laborHours,
  });
  final double goodOutput;
  final double laborHours;
}

final class LaborProductivityEngine
    implements CalculatorEngine<LaborProductivityParameters> {
  const LaborProductivityEngine();
  @override
  String get calculatorId => 'labor_productivity';
  @override
  InputBinding<LaborProductivityParameters> bind(CalculatorInput input) {
    final p = LaborProductivityParameters(
      goodOutput: input.requireNumber('good_output'),
      laborHours: input.requireNumber('labor_hours'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(LaborProductivityParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.goodOutput / p.laborHours;
    return productionResult(
      id: calculatorId,
      label: 'بهره‌وری نیروی کار',
      value: value,
      nonzeroExpected: p.goodOutput > 0,
      unit: 'واحد سالم/نفرساعت',
      percentage: false,
      interpretation: 'شاخص بر مبنای نفرساعت تخصیص‌یافته است. تغییر تعریف ساعت، مرز تیم یا ترکیب محصول مقایسه را نامعتبر می‌کند.',
    );
  }

  List<CalculationIssue> _validate(LaborProductivityParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'good_output',
          'خروجی سالم همان بازه',
          p.goodOutput,
          positive: false,
          integer: false,
        ),
        ProductionNumber(
          'labor_hours',
          'جمع نفرساعت تخصیص‌یافته',
          p.laborHours,
          positive: true,
          integer: false,
        ),
      ]);
}
