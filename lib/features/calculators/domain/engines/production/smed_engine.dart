import '../../calculator_domain.dart';
import 'production_support.dart';

final class SmedParameters implements CalculatorParameters {
  const SmedParameters({required this.beforeTime, required this.afterTime});
  final double beforeTime;
  final double afterTime;
}

final class SmedEngine implements CalculatorEngine<SmedParameters> {
  const SmedEngine();
  @override
  String get calculatorId => 'smed';
  @override
  InputBinding<SmedParameters> bind(CalculatorInput input) {
    final p = SmedParameters(
      beforeTime: input.requireNumber('before_time'),
      afterTime: input.requireNumber('after_time'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(SmedParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = (p.beforeTime - p.afterTime) / p.beforeTime;
    return productionResult(
      id: calculatorId,
      label: 'کاهش زمان تعویض — SMED',
      value: value,
      nonzeroExpected: p.beforeTime != p.afterTime,
      unit: null,
      percentage: true,
      interpretation: 'مقدار منفی یعنی زمان تعویض افزایش یافته است. این محاسبه نه اثبات اجرای SMED است و نه تضمین رسیدن به کمتر از ده دقیقه؛ تعریف شروع/پایان باید ثابت بماند.',
      details: [
        ResultMetric(
          id: 'saved_minutes',
          label: 'زمان صرفه‌جویی‌شده (منفی یعنی افزایش)',
          value: NumericResultValue(p.beforeTime - p.afterTime, unit: 'دقیقه'),
        ),
      ],
      warnings: [
        if (p.afterTime > p.beforeTime)
          CalculationWarning(
            code: 'setup_increased',
            message: 'زمان تعویض افزایش یافته است؛ کاهش منفی گزارش شد.',
          ),
      ],
    );
  }

  List<CalculationIssue> _validate(SmedParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'before_time',
          'زمان تعویض پیش از تغییر',
          p.beforeTime,
          positive: true,
          integer: false,
        ),
        ProductionNumber(
          'after_time',
          'زمان تعویض پس از تغییر',
          p.afterTime,
          positive: false,
          integer: false,
        ),
      ]);
}
