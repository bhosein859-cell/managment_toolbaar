import '../../calculator_domain.dart';
import '../../hr/hr_support.dart';
import '../../statistics/tool_numeric.dart';

final class EmployeeTurnoverParameters implements CalculatorParameters {
  const EmployeeTurnoverParameters({
    required this.separations,
    required this.openingHeadcount,
    required this.closingHeadcount,
    required this.periodDays,
  });
  final double separations;
  final double openingHeadcount;
  final double closingHeadcount;
  final double periodDays;
}

final class EmployeeTurnoverEngine
    implements CalculatorEngine<EmployeeTurnoverParameters> {
  const EmployeeTurnoverEngine();
  static const basis =
      'صورت تعداد خروج قطعی از دامنهٔ سازمان در بازهٔ گزارش است؛ مخرج تقریب میانگین تعداد کارکنان با (ابتدا+انتها)/۲ است، نه تعداد جذب یا تعداد کارکنان ابتدا به‌تنهایی. خروج شامل موارد تعریف‌شدهٔ سیاست سازمان است و جابه‌جایی داخلی سازمان در آن نیست. نتیجه درصد همان بازه است و خودکار سالانه نمی‌شود. برای رشد/فصل‌مندی شدید، میانگین دو نقطه می‌تواند با میانگین واقعی روزانه متفاوت باشد. خروج صفر معتبر است؛ هر دو شمار کارکنان صفر، مخرج نامعتبر می‌سازند. نرخ می‌تواند با جذب/خروج مکرر از صد درصد بیشتر شود و قطع نمی‌شود.';
  @override
  String get calculatorId => 'employee_turnover';
  @override
  InputBinding<EmployeeTurnoverParameters> bind(CalculatorInput input) {
    final p = EmployeeTurnoverParameters(
      separations: input.requireNumber('separations'),
      openingHeadcount: input.requireNumber('opening_headcount'),
      closingHeadcount: input.requireNumber('closing_headcount'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(EmployeeTurnoverParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final average = p.openingHeadcount / 2 + p.closingHeadcount / 2;
    final value = p.separations / average;
    return hrResult(
      id: calculatorId,
      label: 'نرخ ترک خدمت در بازهٔ گزارش',
      value: value,
      basis: basis,
      periodDays: p.periodDays,
      percentage: true,
      nonzero: p.separations > 0,
      details: [
        metric(
          'average_headcount',
          'مخرج: میانگین تقریبی ابتدا/انتها',
          average,
          unit: 'نفر',
        ),
        metric(
          'separation_count',
          'صورت: خروج‌های قطعی بازه',
          p.separations,
          unit: 'نفر',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(EmployeeTurnoverParameters p) {
    final issues = validateHr([
      HrNumber(
        'separations',
        'تعداد خروج قطعی از دامنه',
        p.separations,
        integer: true,
        max: 1000000000,
      ),
      HrNumber(
        'opening_headcount',
        'تعداد کارکنان ابتدای بازه',
        p.openingHeadcount,
        integer: true,
        max: 1000000000,
      ),
      HrNumber(
        'closing_headcount',
        'تعداد کارکنان انتهای بازه',
        p.closingHeadcount,
        integer: true,
        max: 1000000000,
      ),
      HrNumber('period_days', 'طول بازهٔ گزارش', p.periodDays, positive: true),
    ]);
    if (issues.isNotEmpty) return issues;
    if (p.openingHeadcount == 0 && p.closingHeadcount == 0) {
      issues.add(
        CalculationIssue(
          code: 'zero_average_headcount',
          fieldId: 'closing_headcount',
          message: 'میانگین تعداد کارکنان صفر است؛ نرخ ترک خدمت تعریف نمی‌شود. دادهٔ معتبر میانگین/بازه را بررسی کنید.',
        ),
      );
    }
    return issues;
  }
}
