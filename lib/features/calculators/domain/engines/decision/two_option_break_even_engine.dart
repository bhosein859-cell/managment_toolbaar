import '../../calculator_domain.dart';
import '../../decision/decision_math.dart';
import '../../statistics/tool_numeric.dart';

final class TwoOptionBreakEvenParameters implements CalculatorParameters {
  const TwoOptionBreakEvenParameters({
    required this.fixedA,
    required this.variableA,
    required this.fixedB,
    required this.variableB,
    required this.periodDays,
  });
  final double fixedA;
  final double variableA;
  final double fixedB;
  final double variableB;
  final double periodDays;
}

final class TwoOptionBreakEvenEngine
    implements CalculatorEngine<TwoOptionBreakEvenParameters> {
  const TwoOptionBreakEvenEngine();
  static const basis =
      'تقاطع دو تابع هزینهٔ خطی C_A=F_A+v_A Q و C_B=F_B+v_B Q در دامنهٔ فیزیکی Q≥۰ است، نه نقطهٔ سود سربه‌سر یک کسب‌وکار. هزینه‌های ثابت هم‌افق و واحد مقدار یکسان، نرخ متغیر ثابت، ظرفیت کافی و نبود پله/تخفیف/اثر زمان فرض می‌شوند. جواب پیوسته است؛ گردکردن به بسته یا ظرفیت خودکار انجام نمی‌شود. شیب برابر و ثابت برابر یعنی همهٔ مقادیر برابرند و نقطهٔ یکتایی نداریم؛ شیب برابر با ثابت متفاوت تقاطع ندارد. جواب منفی یعنی تقاطع در دامنهٔ غیرمنفی وجود ندارد و با عدد منفی قابل اجرا جایگزین نمی‌شود. Q=۰ در صورت برابر بودن ثابت‌ها می‌تواند مرز معتبر باشد. اطلاعات هزینه به‌تنهایی توصیهٔ قطعی انتخاب نیست.';
  @override
  String get calculatorId => 'two_option_break_even';
  @override
  InputBinding<TwoOptionBreakEvenParameters> bind(CalculatorInput input) {
    final p = TwoOptionBreakEvenParameters(
      fixedA: input.requireNumber('fixed_a'),
      variableA: input.requireNumber('variable_a'),
      fixedB: input.requireNumber('fixed_b'),
      variableB: input.requireNumber('variable_b'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(TwoOptionBreakEvenParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return safelyDecide(() {
      final slope = p.variableA - p.variableB, numerator = p.fixedB - p.fixedA;
      if (slope == 0) {
        throw DecisionMathError(
          numerator == 0 ? 'identical_costs' : 'parallel_costs',
          numerator == 0
              ? 'دو تابع هزینه یکسان‌اند؛ همهٔ مقادیر برابر و نقطهٔ سربه‌سر یکتایی تعریف نمی‌شود.'
              : 'شیب‌ها برابر و ثابت‌ها متفاوت‌اند؛ دو گزینه هیچ تقاطعی ندارند.',
        );
      }
      final q = checked(numerator / slope, nonzero: numerator != 0);
      if (q < 0) {
        throw DecisionMathError(
          'no_nonnegative_crossing',
          'تقاطع محاسباتی منفی است؛ در دامنهٔ مقدار غیرمنفی نقطهٔ تقاطع وجود ندارد.',
        );
      }
      final va = checked(p.variableA * q, nonzero: p.variableA > 0 && q > 0),
          vb = checked(p.variableB * q, nonzero: p.variableB > 0 && q > 0),
          a = checked(p.fixedA + va),
          b = checked(p.fixedB + vb);
      return decisionResult(
        id: calculatorId,
        label: 'مقدار پیوستهٔ تقاطع هزینهٔ A و B',
        value: q,
        unit: 'واحد',
        basis: basis,
        details: [
          metric('cost_a', 'هزینهٔ A در تقاطع', a, unit: 'ریال'),
          metric('cost_b', 'هزینهٔ B در تقاطع', b, unit: 'ریال'),
          metric(
            'period_days',
            'افق مشترک هزینه‌های ثابت',
            p.periodDays,
            unit: 'روز',
          ),
          textMetric(
            'above_crossing',
            'در مقدار بیشتر از تقاطع، در همین مدل',
            slope > 0
                ? 'B هزینهٔ کمتری دارد؛ بدون لحاظ محدودیت‌های بیرونی'
                : 'A هزینهٔ کمتری دارد؛ بدون لحاظ محدودیت‌های بیرونی',
          ),
          textMetric(
            'below_crossing',
            'در مقدار کمتر از تقاطع',
            q == 0
                ? 'در دامنهٔ غیرمنفی مقدار کمتری از مرز صفر نداریم'
                : slope > 0
                ? 'A در همین مدل هزینهٔ کمتری دارد'
                : 'B در همین مدل هزینهٔ کمتری دارد',
          ),
        ],
      );
    });
  }

  List<CalculationIssue> _validate(TwoOptionBreakEvenParameters p) =>
      toolValidate([
        ToolNumber('fixed_a', 'هزینهٔ ثابت A', p.fixedA, min: 0),
        ToolNumber('variable_a', 'هزینهٔ متغیر واحد A', p.variableA, min: 0),
        ToolNumber('fixed_b', 'هزینهٔ ثابت B', p.fixedB, min: 0),
        ToolNumber('variable_b', 'هزینهٔ متغیر واحد B', p.variableB, min: 0),
        ToolNumber(
          'period_days',
          'افق مشترک مقایسه',
          p.periodDays,
          min: 0,
          strictMin: true,
        ),
      ]);
}
