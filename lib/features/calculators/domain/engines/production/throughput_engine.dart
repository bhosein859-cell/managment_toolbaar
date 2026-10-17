import '../../calculator_domain.dart';
import 'production_support.dart';

final class ThroughputParameters implements CalculatorParameters {
  const ThroughputParameters({
    required this.goodOutput,
    required this.elapsedTime,
  });
  final double goodOutput;
  final double elapsedTime;
}

final class ThroughputEngine implements CalculatorEngine<ThroughputParameters> {
  const ThroughputEngine();
  @override
  String get calculatorId => 'throughput';
  @override
  InputBinding<ThroughputParameters> bind(CalculatorInput input) {
    final p = ThroughputParameters(
      goodOutput: input.requireNumber('good_output'),
      elapsedTime: input.requireNumber('elapsed_time'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(ThroughputParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.goodOutput / p.elapsedTime;
    return productionResult(
      id: calculatorId,
      label: 'نرخ خروجی — Throughput',
      value: value,
      nonzeroExpected: p.goodOutput > 0,
      unit: 'واحد سالم/ساعت',
      percentage: false,
      interpretation: 'خروجی نرخ سالم بر ساعت تقویمی همان مرز است. به‌علت تفاوت مبنای توقف/ضایعات، لزوماً معکوس زمان سیکل ابزار دیگر یا نرخ مناسب قانون لیتل نیست.',
    );
  }

  List<CalculationIssue> _validate(ThroughputParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'good_output',
          'خروجی سالم تکمیل‌شده',
          p.goodOutput,
          positive: false,
          integer: false,
        ),
        ProductionNumber(
          'elapsed_time',
          'مدت تقویمی مشاهده',
          p.elapsedTime,
          positive: true,
          integer: false,
        ),
      ]);
}
