import '../../calculator_domain.dart';
import '../../hr/hr_support.dart';
import '../../statistics/tool_numeric.dart';

final class CostPerHireParameters implements CalculatorParameters {
  const CostPerHireParameters({
    required this.internalCost,
    required this.externalCost,
    required this.hires,
    required this.periodDays,
  });
  final double internalCost;
  final double externalCost;
  final double hires;
  final double periodDays;
}

final class CostPerHireEngine
    implements CalculatorEngine<CostPerHireParameters> {
  const CostPerHireEngine();
  static const basis =
      'صورت جمع هزینه‌های داخلی تخصیص‌یافته و خارجی جذب در بازهٔ گزارش است؛ مخرج تعداد جذب‌های تکمیل‌شده با شروع کار در همان بازه و دامنه است. واحد ریال/جذب است. حقوق عادی پس از شروع، هزینهٔ جای خالی و هزینهٔ غیبت خودکار اضافه نمی‌شوند. صفر بودن تعداد جذب نسبت را تعریف نمی‌کند؛ صفر هزینه فقط با ثبت واقعی همهٔ هزینه‌ها معتبر است. نسبت هزینهٔ دوره به جذب‌های دوره به‌دلیل تأخیر بین هزینه و شروع کار، لزوماً هزینهٔ دقیق هر cohort نیست؛ سیاست تخصیص ثابت و مستند لازم است.';
  @override
  String get calculatorId => 'cost_per_hire';
  @override
  InputBinding<CostPerHireParameters> bind(CalculatorInput input) {
    final p = CostPerHireParameters(
      internalCost: input.requireNumber('internal_cost'),
      externalCost: input.requireNumber('external_cost'),
      hires: input.requireNumber('hires'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(CostPerHireParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final total = p.internalCost + p.externalCost;
    if (!total.isFinite) return toolRange();
    final value = total / p.hires;
    return hrResult(
      id: calculatorId,
      label: 'هزینهٔ متوسط هر جذب تکمیل‌شده',
      value: value,
      basis: basis,
      periodDays: p.periodDays,
      unit: 'ریال/جذب',
      nonzero: total > 0,
      details: [
        metric(
          'total_recruitment_cost',
          'صورت: هزینهٔ کل تخصیص‌یافتهٔ جذب',
          total,
          unit: 'ریال',
        ),
        metric(
          'completed_hires',
          'مخرج: جذب‌های تکمیل‌شدهٔ همان بازه',
          p.hires,
          unit: 'نفر',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(CostPerHireParameters p) {
    final issues = validateHr([
      HrNumber(
        'internal_cost',
        'هزینهٔ داخلی تخصیص‌یافتهٔ جذب',
        p.internalCost,
      ),
      HrNumber('external_cost', 'هزینهٔ خارجی جذب', p.externalCost),
      HrNumber(
        'hires',
        'تعداد جذب تکمیل‌شده',
        p.hires,
        positive: true,
        integer: true,
        max: 1000000000,
      ),
      HrNumber('period_days', 'طول بازهٔ گزارش', p.periodDays, positive: true),
    ]);
    if (issues.isNotEmpty) return issues;
    return issues;
  }
}
