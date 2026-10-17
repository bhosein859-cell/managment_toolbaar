import '../../calculator_domain.dart';
import '../../engineering_economics/engineering_math.dart';
import '../../statistics/tool_numeric.dart';

final class TimeValueMoneyParameters implements CalculatorParameters {
  const TimeValueMoneyParameters({
    required this.amount,
    required this.rate,
    required this.periods,
  });
  final double amount, rate, periods;
}

final class TimeValueMoneyEngine
    implements CalculatorEngine<TimeValueMoneyParameters> {
  const TimeValueMoneyEngine();
  static const basis =
      'جریان تک‌مبلغی است: P در زمان صفر و F در پایان دورهٔ n؛ ترکیب گسسته با نرخ مؤثر ثابت i در هر دوره. مالیات، کارمزد، ریسک و تورم جداگانه‌اند. n=۰ یعنی همان لحظه و عامل یک؛ نرخ صفر عامل یک. مبلغ ورودی قدر مطلق دریافت یا پرداخت هم‌جهت است، نه جریان مختلط.';
  @override
  String get calculatorId => 'time_value_money';
  @override
  InputBinding<TimeValueMoneyParameters> bind(CalculatorInput input) {
    final p = TimeValueMoneyParameters(
      amount: input.requireNumber('amount'),
      rate: input.requireNumber('rate'),
      periods: input.requireNumber('periods'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  List<CalculationIssue> _validate(TimeValueMoneyParameters p) => [
    ...toolValidate([
      ToolNumber('amount', 'مبلغ امروز P در زمان صفر', p.amount, min: 0),
      ToolNumber('rate', 'نرخ مؤثر هر دوره', p.rate, min: -1, strictMin: true),
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
  CalculationOutcome calculate(TimeValueMoneyParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return economicSafe(() {
      final factor = economicFactorValue(EconomicFactor.fp, p.rate, p.periods),
          future = economicConverted(p.amount, factor),
          interest = economicChecked(
            p.amount * economicExpm1(p.periods * economicLog1p(p.rate)),
            nonzero: p.amount > 0 && p.rate != 0 && p.periods > 0,
          );
      return economicResult(
        id: calculatorId,
        label: 'ارزش آیندهٔ مبلغ امروز؛ رشد مرکب',
        value: future,
        unit: 'ریال',
        basis: basis,
        details: [
          metric('compound_factor', 'عامل رشد مرکب F/P', factor, unit: 'برابر'),
          metric(
            'present_amount',
            'مبلغ امروز در زمان صفر',
            p.amount,
            unit: 'ریال',
          ),
          metric(
            'interest',
            'افزایش یا کاهش مبلغ، علامت‌دار',
            interest,
            unit: 'ریال',
          ),
        ],
      );
    });
  }
}
