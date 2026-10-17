import 'dart:math' as math;

import '../calculator_domain.dart';

enum MoneyUnit {
  rial,
  toman;

  String get label => switch (this) {
    rial => 'ریال',
    toman => 'تومان',
  };
}

final class NpvParameters implements CalculatorParameters {
  NpvParameters({
    required this.initialInvestment,
    required this.discountRate,
    required Iterable<double> cashFlows,
    this.moneyUnit = MoneyUnit.rial,
  }) : cashFlows = List.unmodifiable(cashFlows);
  final double initialInvestment;

  /// Effective rate per cash-flow period, as a fraction. Must be > -1.
  final double discountRate;

  /// CF1 ... CFn, end-of-period cash flows. CF0 is NOT included here.
  final List<double> cashFlows;
  final MoneyUnit moneyUnit;
}

final class NpvEngine implements CalculatorEngine<NpvParameters> {
  const NpvEngine();
  @override
  String get calculatorId => 'npv';

  @override
  InputBinding<NpvParameters> bind(CalculatorInput input) {
    final id = input.requireChoice('money_unit');
    final unit = switch (id) {
      'rial' => MoneyUnit.rial,
      'toman' => MoneyUnit.toman,
      _ => null,
    };
    if (unit == null) {
      return RejectedInput([
        CalculationIssue(
          code: 'invalid_money_unit',
          fieldId: 'money_unit',
          message: 'واحد پول معتبر نیست.',
        ),
      ]);
    }
    final parameters = NpvParameters(
      initialInvestment: input.requireNumber('initial_investment'),
      discountRate: input.requireNumber('discount_rate'),
      cashFlows: input.requireNumberList('cash_flows'),
      moneyUnit: unit,
    );
    final issues = _validate(parameters);
    return issues.isEmpty ? BoundInput(parameters) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(NpvParameters parameters) {
    final issues = _validate(parameters);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final base = 1 + parameters.discountRate;
    var sum = -parameters.initialInvestment;
    var compensation = 0.0;
    for (var index = 0; index < parameters.cashFlows.length; index++) {
      final flow = parameters.cashFlows[index];
      if (flow == 0) continue;
      final period = index + 1;
      final denominator = math.pow(base, period).toDouble();
      double discounted;
      if (denominator.isFinite && denominator >= 2.2250738585072014e-308) {
        discounted = flow / denominator;
      } else {
        // Fallback avoids overflow/underflow and low relative precision
        // in subnormal discount factors.
        final logValue = math.log(flow.abs()) - period * math.log(base);
        discounted = flow.sign * math.exp(logValue);
      }
      if (!discounted.isFinite || discounted == 0) return _rangeFailure(index);
      // Neumaier compensated sum reduces loss in mixed-sign cash-flow series.
      final next = sum + discounted;
      if (!next.isFinite) return _rangeFailure(index);
      compensation += sum.abs() >= discounted.abs()
          ? (sum - next) + discounted
          : (discounted - next) + sum;
      if (!compensation.isFinite) return _rangeFailure(index);
      sum = next;
    }
    final value = sum + compensation;
    if (!value.isFinite) return _rangeFailure(null);
    final signText = value > 0
        ? 'مثبت'
        : value < 0
        ? 'منفی'
        : 'صفر';
    return CalculationSuccess(
      CalculationResult(
        primary: ResultMetric(
          id: 'npv',
          label: 'ارزش فعلی خالص (NPV)',
          value: NumericResultValue(value, unit: parameters.moneyUnit.label),
        ),
        details: [
          ResultMetric(
            id: 'period_count',
            label: 'تعداد دوره‌های برابر',
            value: NumericResultValue(
              parameters.cashFlows.length.toDouble(),
              unit: 'دوره',
            ),
          ),
          ResultMetric(
            id: 'discount_rate',
            label: 'نرخ مؤثر تنزیل هر دوره',
            value: NumericResultValue(
              parameters.discountRate,
              display: NumberDisplay.percentage,
            ),
          ),
        ],
        warnings: [
          CalculationWarning(
            code: 'timing_assumption',
            severity: WarningSeverity.information,
            message: 'سرمایه‌گذاری اولیه خروج وجه در زمان صفر است؛ اولین سطر جریان نقدی، پایان دورهٔ اول است. این ابزار XNPV و جریان‌های تاریخ‌دار نیست.',
          ),
          if (parameters.discountRate < 0)
            CalculationWarning(
              code: 'negative_rate',
              message: 'نرخ تنزیل منفی استفاده شده است؛ سازگاری آن با فرض‌های اقتصادی مدل را بررسی کنید.',
            ),
        ],
        interpretation:
            'ارزش فعلی خالص با فرض‌های واردشده $signText است. این نتیجه به‌تنهایی معیار قطعی تصمیم یا توصیهٔ سرمایه‌گذاری نیست.',
      ),
    );
  }

  List<CalculationIssue> _validate(NpvParameters parameters) {
    final issues = <CalculationIssue>[];
    if (!parameters.initialInvestment.isFinite ||
        parameters.initialInvestment < 0) {
      issues.add(
        CalculationIssue(
          code: 'invalid_initial_investment',
          fieldId: 'initial_investment',
          message: 'سرمایه‌گذاری اولیه باید عدد متناهی و نامنفی باشد؛ خروج وجه در زمان صفر لحاظ می‌شود.',
        ),
      );
    }
    if (!parameters.discountRate.isFinite || parameters.discountRate <= -1) {
      issues.add(
        CalculationIssue(
          code: 'invalid_discount_rate',
          fieldId: 'discount_rate',
          message: 'نرخ تنزیل هر دوره باید متناهی و بیشتر از منفی ۱۰۰٪ باشد.',
        ),
      );
    }
    if (parameters.cashFlows.isEmpty || parameters.cashFlows.length > 1000) {
      issues.add(
        CalculationIssue(
          code: 'invalid_flow_count',
          fieldId: 'cash_flows',
          message: 'تعداد جریان‌های نقدی باید بین ۱ و ۱۰۰۰ باشد.',
        ),
      );
    }
    for (var index = 0; index < parameters.cashFlows.length; index++) {
      if (!parameters.cashFlows[index].isFinite) {
        issues.add(
          CalculationIssue(
            code: 'invalid_cash_flow',
            fieldId: 'cash_flows',
            itemIndex: index,
            message: 'همهٔ جریان‌های نقدی باید عدد متناهی باشند.',
          ),
        );
      }
    }
    return issues;
  }

  CalculationFailure _rangeFailure(int? index) => CalculationFailure([
    CalculationIssue(
      code: 'numeric_range',
      fieldId: 'cash_flows',
      itemIndex: index,
      message: 'این ترکیب نرخ و جریان نقدی از محدودهٔ امن دقت عددی خارج است. واحد پول یا مقیاس مقادیر و تعداد دوره‌ها را بازبینی کنید؛ نتیجهٔ قابل اتکا تولید نشد.',
    ),
  ]);
}
