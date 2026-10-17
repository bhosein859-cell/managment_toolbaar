import '../../calculator_domain.dart';
import '../../engineering_economics/engineering_math.dart';
import '../../statistics/tool_numeric.dart';

final class InflationAdjustmentParameters implements CalculatorParameters {
  const InflationAdjustmentParameters({
    required this.amount,
    required this.rate,
    required this.periods,
  });
  final double amount, rate, periods;
}

final class InflationAdjustmentEngine
    implements CalculatorEngine<InflationAdjustmentParameters> {
  const InflationAdjustmentEngine();
  static const basis =
      'مبلغ اسمی در پایان n دوره با تورم مؤثر ثابت π به قدرت خرید زمان صفر تبدیل می‌شود. این نرخ تورم است، نه نرخ بازده/تنزیل سرمایه‌گذاری؛ نرخ واقعی فیشر محاسبه نمی‌شود. تورم بالاتر از منفی ۱۰۰٪، از جمله کاهش قیمت مجاز است. دوره صفر یا تورم صفر مبلغ را تغییر نمی‌دهد. سبد قیمت ثابت، نرخ یکنواخت و واحد پول یکسان فرض می‌شود.';
  @override
  String get calculatorId => 'inflation_adjustment';
  @override
  InputBinding<InflationAdjustmentParameters> bind(CalculatorInput input) {
    final p = InflationAdjustmentParameters(
      amount: input.requireNumber('amount'),
      rate: input.requireNumber('rate'),
      periods: input.requireNumber('periods'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  List<CalculationIssue> _validate(InflationAdjustmentParameters p) => [
    ...toolValidate([
      ToolNumber('amount', 'مبلغ اسمی در پایان n دوره', p.amount, min: 0),
      ToolNumber(
        'rate',
        'نرخ تورم مؤثر هر دوره',
        p.rate,
        min: -1,
        strictMin: true,
      ),
      ToolNumber(
        'periods',
        'تعداد دوره‌های هم‌اندازه',
        p.periods,
        min: 0,
        max: 10000,
        integer: true,
      ),
    ]),
  ];
  @override
  CalculationOutcome calculate(InflationAdjustmentParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return economicSafe(() {
      final factor = economicFactorValue(EconomicFactor.pf, p.rate, p.periods),
          real = economicConverted(p.amount, factor);
      return economicResult(
        id: calculatorId,
        label: 'قدرت خرید به قیمت‌های زمان صفر',
        value: real,
        unit: 'ریال',
        basis: basis,
        details: [
          metric(
            'deflator',
            'عامل تبدیل به قدرت خرید پایه',
            factor,
            unit: 'برابر',
          ),
          metric(
            'nominal_amount',
            'مبلغ اسمی در پایان n',
            p.amount,
            unit: 'ریال',
          ),
        ],
      );
    });
  }
}
