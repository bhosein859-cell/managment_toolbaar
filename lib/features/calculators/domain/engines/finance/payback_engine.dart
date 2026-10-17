import '../../calculator_domain.dart';
import 'finance_support.dart';

final class PaybackParameters implements CalculatorParameters {
  PaybackParameters({
    required this.initialInvestment,
    required Iterable<double> cashFlows,
  }) : cashFlows = List.unmodifiable(cashFlows);
  final double initialInvestment;
  final List<double> cashFlows;
}

final class PaybackEngine implements CalculatorEngine<PaybackParameters> {
  const PaybackEngine();
  static const basis =
      'بازگشت ساده و بدون تنزیل است؛ سرمایه‌گذاری خروج زمان صفر و سطرهای فهرست جریان خالص نامنفی دوره‌های بعدند. برای بخش کسری، دریافت یکنواخت در داخل دوره فرض شده؛ اگر دریافت فقط پایان دوره است، زمان واقعی همان پایان دوره خواهد بود. جریان منفی بعدی در این نسخه پشتیبانی نمی‌شود؛ بازگشت ساده ارزش زمانی پول یا سودآوری کل را نمی‌سنجد.';
  @override
  String get calculatorId => 'payback';
  @override
  InputBinding<PaybackParameters> bind(CalculatorInput input) {
    final p = PaybackParameters(
      initialInvestment: input.requireNumber('initial_investment'),
      cashFlows: input.requireNumberList('cash_flows'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(PaybackParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (p.initialInvestment == 0) {
      return financeResult(
        id: calculatorId,
        label: 'دورهٔ بازگشت ساده',
        value: 0,
        unit: 'دوره',
        basis: basis,
      );
    }
    var remaining = p.initialInvestment;
    for (var i = 0; i < p.cashFlows.length; i++) {
      final flow = p.cashFlows[i];
      if (flow >= remaining) {
        final fraction = remaining / flow;
        if (lostNonzero(fraction, true)) return financeRange();
        return financeResult(
          id: calculatorId,
          label: 'دورهٔ بازگشت ساده',
          value: i + fraction,
          unit: 'دوره',
          basis: basis,
          details: [
            financeMetric(
              'recovery_period_end',
              'پایان دورهٔ رسیدن به بازگشت (دریافت انتهای دوره)',
              i + 1.0,
              unit: 'دوره',
            ),
          ],
        );
      }
      remaining -= flow;
    }
    return financeFailure(
      'not_recovered',
      'در افق جریان‌های واردشده، سرمایه بازنمی‌گردد؛ دورهٔ ساختگی یا بی‌نهایت نمایش داده نشد.',
      fieldId: 'cash_flows',
    );
  }

  List<CalculationIssue> _validate(PaybackParameters p) {
    final issues = validateFinance([
      FinanceField(
        'initial_investment',
        'سرمایه‌گذاری اولیه',
        p.initialInvestment,
        min: 0,
      ),
    ]);
    if (p.cashFlows.isEmpty || p.cashFlows.length > 1000) {
      issues.add(
        CalculationIssue(
          code: 'invalid_flow_count',
          fieldId: 'cash_flows',
          message: '۱ تا ۱۰۰۰ جریان نامنفی لازم است.',
        ),
      );
    }
    for (var i = 0; i < p.cashFlows.length; i++) {
      if (!p.cashFlows[i].isFinite || p.cashFlows[i] < 0) {
        issues.add(
          CalculationIssue(
            code: 'invalid_cash_flow',
            fieldId: 'cash_flows',
            itemIndex: i,
            message: 'بازگشت سادهٔ این ابزار فقط جریان‌های خالص متناهی و نامنفی را می‌پذیرد.',
          ),
        );
      }
    }
    return issues;
  }
}
