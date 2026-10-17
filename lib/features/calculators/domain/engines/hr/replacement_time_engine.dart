import '../../calculator_domain.dart';
import '../../hr/hr_support.dart';
import '../../statistics/tool_numeric.dart';

final class ReplacementTimeParameters implements CalculatorParameters {
  ReplacementTimeParameters({
    required Iterable<double> elapsedDays,
    required this.periodDays,
  }) : elapsedDays = List.unmodifiable(elapsedDays);
  final List<double> elapsedDays;
  final double periodDays;
}

final class ReplacementTimeEngine
    implements CalculatorEngine<ReplacementTimeParameters> {
  const ReplacementTimeEngine();
  static const basis =
      'صورت جمع روزهای تقویمی سپری‌شده از تأیید رسمی درخواست جایگزینی تا شروع واقعی کار فرد جدید است؛ مخرج تعداد جایگزینی‌های تکمیل‌شدهٔ فهرست است. cohort گزارش شامل شروع‌کارهای واقع‌شده در بازهٔ گزارش است؛ آغاز درخواست می‌تواند پیش از آن باشد و مدت به طول پنجره محدود نمی‌شود. همهٔ اقلام باید همان نقطهٔ آغاز/پایان و تقویم را داشته باشند. این تعریف با زمان تا پذیرش پیشنهاد، زمان از خروج نفر قبلی یا زمان رسیدن به بهره‌وری کامل یکی نیست. موقعیت‌های هنوز خالی در میانگین نیستند؛ حذف آن‌ها سوگیری تکمیل‌شدگان دارد و این عدد طول انتظار همهٔ جای‌خالی‌ها را نشان نمی‌دهد. جایگزینی همان‌روز می‌تواند صفر روز باشد؛ فهرست خالی به معنی میانگین صفر نیست. میانه/صدک از این میانگین استنباط نمی‌شود.';
  @override
  String get calculatorId => 'replacement_time';
  @override
  InputBinding<ReplacementTimeParameters> bind(CalculatorInput input) {
    final p = ReplacementTimeParameters(
      elapsedDays: input.requireNumberList('elapsed_days'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(ReplacementTimeParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final total = compensatedSum(p.elapsedDays);
    if (!total.isFinite) return toolRange();
    final value = total / p.elapsedDays.length;
    return hrResult(
      id: calculatorId,
      label: 'میانگین زمان تکمیل جایگزینی‌های ثبت‌شده',
      value: value,
      basis: basis,
      periodDays: p.periodDays,
      unit: 'روز/جایگزینی',
      nonzero: p.elapsedDays.any((v) => v > 0),
      details: [
        metric(
          'total_elapsed_days',
          'صورت: مجموع روزهای تقویمی سپری‌شده',
          total,
          unit: 'روز',
        ),
        metric(
          'completed_replacements',
          'مخرج: تعداد جایگزینی‌های تکمیل‌شده',
          p.elapsedDays.length.toDouble(),
          unit: 'مورد',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(ReplacementTimeParameters p) {
    final issues = validateHr([
      HrNumber('period_days', 'طول بازهٔ گزارش', p.periodDays, positive: true),
    ]);
    if (issues.isNotEmpty) return issues;
    if (p.elapsedDays.isEmpty || p.elapsedDays.length > 1000) {
      issues.add(
        CalculationIssue(
          code: 'replacement_count',
          fieldId: 'elapsed_days',
          message: 'میانگین به ۱ تا ۱۰۰۰ جایگزینی تکمیل‌شده نیاز دارد؛ فهرست خالی میانگین صفر نیست.',
        ),
      );
    }
    for (var i = 0; i < p.elapsedDays.length; i++) {
      final v = p.elapsedDays[i];
      if (!v.isFinite || v < 0) {
        issues.add(
          CalculationIssue(
            code: 'invalid_elapsed_days',
            fieldId: 'elapsed_days',
            itemIndex: i,
            message: 'مدت هر جایگزینی باید عدد متناهی و نامنفی باشد.',
          ),
        );
      }
    }
    return issues;
  }
}
