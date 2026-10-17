import '../../calculator_domain.dart';
import 'production_support.dart';

final class WipParameters implements CalculatorParameters {
  const WipParameters({required this.throughputRate, required this.flowTime});
  final double throughputRate;
  final double flowTime;
}

final class WipEngine implements CalculatorEngine<WipParameters> {
  const WipEngine();
  @override
  String get calculatorId => 'wip';
  @override
  InputBinding<WipParameters> bind(CalculatorInput input) {
    final p = WipParameters(
      throughputRate: input.requireNumber('throughput_rate'),
      flowTime: input.requireNumber('flow_time'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(WipParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.throughputRate * p.flowTime;
    return productionResult(
      id: calculatorId,
      label: 'موجودی در جریان ساخت — WIP',
      value: value,
      nonzeroExpected: p.flowTime > 0,
      unit: 'واحد متوسط',
      percentage: false,
      interpretation: 'این خروجی موجودی متوسط برآوردی در شرایط قانون لیتل است، نه شمارش موجودی لحظه‌ای. پایداری سیستم و سازگاری مرز/میانگین‌ها باید بیرون از ابزار بررسی شود.',
    );
  }

  List<CalculationIssue> _validate(WipParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'throughput_rate',
          'نرخ خروج متوسط هم‌مرز',
          p.throughputRate,
          positive: true,
          integer: false,
        ),
        ProductionNumber(
          'flow_time',
          'متوسط زمان حضور در سیستم',
          p.flowTime,
          positive: false,
          integer: false,
        ),
      ]);
}
