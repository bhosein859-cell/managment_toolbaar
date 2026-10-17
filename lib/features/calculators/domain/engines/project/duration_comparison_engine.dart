import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class DurationComparisonParameters implements CalculatorParameters {
  const DurationComparisonParameters({
    required this.planned,
    required this.actual,
  });
  final double planned;
  final double actual;
}

final class DurationComparisonEngine
    implements CalculatorEngine<DurationComparisonParameters> {
  const DurationComparisonEngine();
  static const basis =
      'اختلاف = مدت واقعی−مدت برنامه است؛ مثبت یعنی طولانی‌تر و منفی یعنی کوتاه‌تر. نسبت واقعی/برنامه و درصد اختلاف فقط برای برنامهٔ مثبت تعریف می‌شوند؛ برنامهٔ صفر اختلاف معتبر ولی نسبت نامعین دارد. دامنه، تقویم روز کاری/تقویمی و نقطهٔ شروع یکسان فرض می‌شوند. این مقایسه برای مدت نهایی هم‌دامنه است، نه اندازه‌گیری پیشرفت کار ناتمام، SPI یا تحلیل علت تأخیر.';
  @override
  String get calculatorId => 'duration_comparison';
  @override
  InputBinding<DurationComparisonParameters> bind(CalculatorInput input) {
    final p = DurationComparisonParameters(
      planned: input.requireNumber('planned_duration'),
      actual: input.requireNumber('actual_duration'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(DurationComparisonParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final delta = p.actual - p.planned;
    final details = <ResultMetric>[];
    if (p.planned == 0) {
      details.add(
        textMetric(
          'undefined_ratio',
          'نسبت و درصد اختلاف',
          'برای مدت برنامهٔ صفر تعریف نمی‌شود',
        ),
      );
    } else {
      final ratio = p.actual / p.planned, overrun = delta / p.planned;
      if (invalidNumeric(ratio, nonzero: p.actual > 0) ||
          invalidNumeric(overrun, nonzero: delta != 0)) {
        return toolRange();
      }
      details.addAll([
        metric('duration_ratio', 'نسبت واقعی به برنامه، نه SPI', ratio),
        metric(
          'overrun',
          'درصد اختلاف نسبت به برنامه',
          overrun,
          percentage: true,
        ),
      ]);
    }
    return toolResult(
      id: calculatorId,
      label: 'اختلاف مدت واقعی منهای برنامه',
      value: delta,
      unit: 'روز',
      basis: basis,
      details: details,
    );
  }

  List<CalculationIssue> _validate(DurationComparisonParameters p) {
    final issues = toolValidate([
      ToolNumber('planned_duration', 'مدت برنامه‌ریزی‌شده', p.planned, min: 0),
      ToolNumber('actual_duration', 'مدت واقعی', p.actual, min: 0),
    ]);
    if (issues.isNotEmpty) return issues;
    return issues;
  }
}
