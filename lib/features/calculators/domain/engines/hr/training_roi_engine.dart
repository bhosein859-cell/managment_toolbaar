import '../../calculator_domain.dart';
import '../../hr/hr_support.dart';
import '../../statistics/tool_numeric.dart';

final class TrainingRoiParameters implements CalculatorParameters {
  const TrainingRoiParameters({
    required this.grossBenefits,
    required this.attributionRate,
    required this.trainingCost,
    required this.periodDays,
  });
  final double grossBenefits;
  final double attributionRate;
  final double trainingCost;
  final double periodDays;
}

final class TrainingRoiEngine
    implements CalculatorEngine<TrainingRoiParameters> {
  const TrainingRoiEngine();
  static const basis =
      'صورت منفعت پولی قابل انتساب منهای کل هزینهٔ آموزش است؛ منفعت قابل انتساب = منفعت ناخالص برآوردی × سهم انتساب. مخرج کل هزینهٔ همان آموزش/cohort است. طول بازه، پنجرهٔ مشاهدهٔ منافع پس از آموزش است؛ هزینهٔ اولیه و همهٔ هزینه‌های مرتبط با همان cohort در آن مقایسه تخصیص می‌یابند، حتی اگر پیش از پنجره پرداخت شده باشند. ارز/مبنای قیمت مشترک، تخصیص بدون هم‌پوشانی و انتساب مستند فرض می‌شوند؛ تنزیل زمانی اجرا نمی‌شود. سهم انتساب، فرض است و رابطهٔ علّی را اثبات نمی‌کند؛ اثر عوامل بیرونی و منافع غیرپولیِ ارزش‌گذاری‌نشده خودکار مدل نمی‌شوند. هزینهٔ صفر ROI را تعریف نمی‌کند؛ منفعت صفر یا سهم انتساب صفر ROI برابر منفی صد درصد می‌دهد و ROI منفی قطع نمی‌شود.';
  @override
  String get calculatorId => 'training_roi';
  @override
  InputBinding<TrainingRoiParameters> bind(CalculatorInput input) {
    final p = TrainingRoiParameters(
      grossBenefits: input.requireNumber('gross_benefits'),
      attributionRate: input.requireNumber('attribution_rate'),
      trainingCost: input.requireNumber('training_cost'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(TrainingRoiParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final benefit = p.grossBenefits * p.attributionRate;
    if (invalidNumeric(
      benefit,
      nonzero: p.grossBenefits > 0 && p.attributionRate > 0,
    )) {
      return toolRange();
    }
    final net = benefit - p.trainingCost, value = net / p.trainingCost;
    return hrResult(
      id: calculatorId,
      label: 'ROI برآوردی آموزش در پنجرهٔ گزارش',
      value: value,
      basis: basis,
      periodDays: p.periodDays,
      percentage: true,
      nonzero: net != 0,
      details: [
        metric(
          'attributed_benefit',
          'منفعت پولی قابل انتساب طبق فرض ورودی',
          benefit,
          unit: 'ریال',
        ),
        metric('net_benefit', 'صورت: منفعت خالص برآوردی', net, unit: 'ریال'),
        metric(
          'training_investment',
          'مخرج: هزینهٔ کل cohort',
          p.trainingCost,
          unit: 'ریال',
        ),
        metric(
          'selected_attribution',
          'سهم انتساب فرض‌شده',
          p.attributionRate,
          percentage: true,
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(TrainingRoiParameters p) {
    final issues = validateHr([
      HrNumber(
        'gross_benefits',
        'منافع پولی برآوردشده پیش از انتساب',
        p.grossBenefits,
      ),
      HrNumber(
        'attribution_rate',
        'سهم برآوردی قابل انتساب به آموزش',
        p.attributionRate,
        max: 1,
      ),
      HrNumber(
        'training_cost',
        'کل هزینهٔ آموزش cohort',
        p.trainingCost,
        positive: true,
      ),
      HrNumber('period_days', 'طول بازهٔ گزارش', p.periodDays, positive: true),
    ]);
    if (issues.isNotEmpty) return issues;
    return issues;
  }
}
