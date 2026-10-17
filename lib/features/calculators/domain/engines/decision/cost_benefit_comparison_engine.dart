import '../../calculator_domain.dart';
import '../../decision/decision_math.dart';
import '../../statistics/tool_numeric.dart';

final class CostBenefitComparisonParameters implements CalculatorParameters {
  const CostBenefitComparisonParameters({
    required this.costA,
    required this.benefitA,
    required this.costB,
    required this.benefitB,
    required this.periodDays,
  });
  final double costA;
  final double benefitA;
  final double costB;
  final double benefitB;
  final double periodDays;
}

final class CostBenefitComparisonEngine
    implements CalculatorEngine<CostBenefitComparisonParameters> {
  const CostBenefitComparisonEngine();
  static const basis =
      'مقایسهٔ خالص پولی دو گزینه: NB=Benefit−Cost و اختلاف NB_B−NB_A است؛ BCR=Benefit/Cost فقط برای هزینهٔ مثبت تعریف می‌شود. هزینه/منفعت نامنفی، افق و واحد پول و مبنای قیمت مشترک و تخصیص بدون هم‌پوشانی فرض شده‌اند. اعداد باید یا متعلق به دورهٔ مشترک باشند یا از پیش به ارزش فعلی با مبنای یکسان تبدیل شده باشند؛ ابزار جریان زمانی را تنزیل نمی‌کند. هزینهٔ صفر منفعت خالص را نامعتبر نمی‌کند، ولی BCR آن گزینه تعریف نشده است، نه بی‌نهایت ساختگی. خالص منفی قطع نمی‌شود. نسبت BCR به‌تنهایی معیار انتخاب بین گزینه‌های با مقیاس متفاوت نیست؛ آثار غیرپولی، توزیعی، ریسک و محدودیت منابع خودکار مدل نمی‌شوند.';
  @override
  String get calculatorId => 'cost_benefit_comparison';
  @override
  InputBinding<CostBenefitComparisonParameters> bind(CalculatorInput input) {
    final p = CostBenefitComparisonParameters(
      costA: input.requireNumber('cost_a'),
      benefitA: input.requireNumber('benefit_a'),
      costB: input.requireNumber('cost_b'),
      benefitB: input.requireNumber('benefit_b'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(CostBenefitComparisonParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return safelyDecide(() {
      final a = p.benefitA - p.costA,
          b = p.benefitB - p.costB,
          delta = checked(b - a);
      final details = <ResultMetric>[
        metric('net_a', 'منفعت خالص A', a, unit: 'ریال'),
        metric('net_b', 'منفعت خالص B', b, unit: 'ریال'),
        metric(
          'period_days',
          'افق مشترک؛ بدون تنزیل خودکار',
          p.periodDays,
          unit: 'روز',
        ),
      ];
      for (final (id, cost, benefit) in [
        ('a', p.costA, p.benefitA),
        ('b', p.costB, p.benefitB),
      ]) {
        details.add(
          cost == 0
              ? textMetric(
                  'bcr_$id',
                  'نسبت منفعت/هزینه؛ طبق ترتیب A سپس B',
                  'هزینه صفر است؛ نسبت تعریف نمی‌شود',
                )
              : metric(
                  'bcr_$id',
                  'نسبت منفعت/هزینه؛ طبق ترتیب A سپس B',
                  checked(benefit / cost, nonzero: benefit > 0),
                  unit: 'برابر',
                ),
        );
      }
      return decisionResult(
        id: calculatorId,
        label: 'اختلاف منفعت خالص B نسبت به A؛ علامت‌دار',
        value: delta,
        unit: 'ریال',
        basis: basis,
        details: details,
      );
    });
  }

  List<CalculationIssue> _validate(CostBenefitComparisonParameters p) =>
      toolValidate([
        ToolNumber('cost_a', 'هزینهٔ گزینهٔ A', p.costA, min: 0),
        ToolNumber('benefit_a', 'منفعت گزینهٔ A', p.benefitA, min: 0),
        ToolNumber('cost_b', 'هزینهٔ گزینهٔ B', p.costB, min: 0),
        ToolNumber('benefit_b', 'منفعت گزینهٔ B', p.benefitB, min: 0),
        ToolNumber(
          'period_days',
          'افق مشترک مقایسه',
          p.periodDays,
          min: 0,
          strictMin: true,
        ),
      ]);
}
