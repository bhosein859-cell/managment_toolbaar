import '../../calculator_domain.dart';
import 'production_support.dart';

final class TaktTimeParameters implements CalculatorParameters {
  const TaktTimeParameters({required this.availableTime, required this.demand});
  final double availableTime;
  final double demand;
}

final class TaktTimeEngine implements CalculatorEngine<TaktTimeParameters> {
  const TaktTimeEngine();
  @override
  String get calculatorId => 'takt_time';
  @override
  InputBinding<TaktTimeParameters> bind(CalculatorInput input) {
    final p = TaktTimeParameters(
      availableTime: input.requireNumber('available_time'),
      demand: input.requireNumber('demand'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(TaktTimeParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.availableTime / p.demand;
    return productionResult(
      id: calculatorId,
      label: 'زمان تکت — Takt Time',
      value: value,
      nonzeroExpected: true,
      unit: 'دقیقه/واحد',
      percentage: false,
      interpretation: 'این عدد آهنگ لازم برای پاسخ به تقاضاست، نه اندازه‌گیری سرعت واقعی خط. زمان و تقاضا باید متعلق به یک بازه باشند.',
    );
  }

  List<CalculationIssue> _validate(TaktTimeParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'available_time',
          'زمان خالص در دسترس',
          p.availableTime,
          positive: true,
          integer: false,
        ),
        ProductionNumber(
          'demand',
          'تقاضای همان بازه',
          p.demand,
          positive: true,
          integer: false,
        ),
      ]);
}
