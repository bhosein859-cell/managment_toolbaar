import '../../calculator_domain.dart';
import 'production_support.dart';

final class CycleTimeParameters implements CalculatorParameters {
  const CycleTimeParameters({required this.runTime, required this.totalOutput});
  final double runTime;
  final double totalOutput;
}

final class CycleTimeEngine implements CalculatorEngine<CycleTimeParameters> {
  const CycleTimeEngine();
  @override
  String get calculatorId => 'cycle_time';
  @override
  InputBinding<CycleTimeParameters> bind(CalculatorInput input) {
    final p = CycleTimeParameters(
      runTime: input.requireNumber('run_time'),
      totalOutput: input.requireNumber('total_output'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(CycleTimeParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.runTime / p.totalOutput;
    return productionResult(
      id: calculatorId,
      label: 'زمان سیکل',
      value: value,
      nonzeroExpected: true,
      unit: 'دقیقه/واحد',
      percentage: false,
      interpretation: 'میانگین بر مبنای کارکرد و خروجی کل است. معکوس آن فقط با واحد و مبنای زمانی/تعدادی یکسان به نرخ تبدیل می‌شود؛ با Throughput سالم تقویمی الزاماً برابر نیست.',
    );
  }

  List<CalculationIssue> _validate(CycleTimeParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'run_time',
          'زمان کارکرد واقعی',
          p.runTime,
          positive: true,
          integer: false,
        ),
        ProductionNumber(
          'total_output',
          'کل خروجی تولیدشده',
          p.totalOutput,
          positive: true,
          integer: false,
        ),
      ]);
}
