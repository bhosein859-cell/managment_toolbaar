import '../../calculator_domain.dart';
import '../../hr/hr_support.dart';
import '../../statistics/tool_numeric.dart';

final class EmployeeProductivityParameters implements CalculatorParameters {
  const EmployeeProductivityParameters({
    required this.output,
    required this.workedHours,
    required this.periodDays,
  });
  final double output;
  final double workedHours;
  final double periodDays;
}

final class EmployeeProductivityEngine
    implements CalculatorEngine<EmployeeProductivityParameters> {
  const EmployeeProductivityEngine();
  static const basis =
      'صورت خروجی واقعی همگن/استانداردشده در بازهٔ گزارش و مخرج جمع نفرساعت واقعاً کارشدهٔ همان دامنه است؛ نتیجه واحد خروجی/نفرساعت است، نه خروجی به‌ازای تعداد کارکنان یا سودآوری. تعریف خروجی، کیفیت، ترکیب محصول/خدمت و ساعت پشتیبانی مرتبط باید ثابت و مستند باشد. ساعت کار صفر نسبت را تعریف نمی‌کند؛ خروجی صفرِ مشاهده‌شده مجاز است و جای دادهٔ ناقص نیست. فناوری، سرمایه، برون‌سپاری، ظرفیت و شرایط کار بر این عدد اثر دارند؛ از آن رتبه‌بندی یا نتیجه‌گیری قطعی دربارهٔ افراد ساخته نمی‌شود.';
  @override
  String get calculatorId => 'employee_productivity';
  @override
  InputBinding<EmployeeProductivityParameters> bind(CalculatorInput input) {
    final p = EmployeeProductivityParameters(
      output: input.requireNumber('output'),
      workedHours: input.requireNumber('worked_hours'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(EmployeeProductivityParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.output / p.workedHours;
    return hrResult(
      id: calculatorId,
      label: 'خروجی مشاهده‌شده به‌ازای نفرساعت کار',
      value: value,
      basis: basis,
      periodDays: p.periodDays,
      unit: 'واحد خروجی/نفرساعت',
      nonzero: p.output > 0,
      details: [
        metric(
          'observed_output',
          'صورت: خروجی همگن دوره',
          p.output,
          unit: 'واحد خروجی',
        ),
        metric(
          'observed_hours',
          'مخرج: ساعت کار واقعی دوره',
          p.workedHours,
          unit: 'نفرساعت',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(EmployeeProductivityParameters p) {
    final issues = validateHr([
      HrNumber('output', 'خروجی همگن و استانداردشده', p.output),
      HrNumber(
        'worked_hours',
        'ساعت کار واقعی نیروی کار',
        p.workedHours,
        positive: true,
      ),
      HrNumber('period_days', 'طول بازهٔ گزارش', p.periodDays, positive: true),
    ]);
    if (issues.isNotEmpty) return issues;
    return issues;
  }
}
