import '../../calculator_domain.dart';
import 'finance_support.dart';

final class LoanPaymentParameters implements CalculatorParameters {
  const LoanPaymentParameters({
    required this.principal,
    required this.periodRate,
    required this.periods,
  });
  final double principal;
  final double periodRate;
  final double periods;
}

final class LoanPaymentEngine
    implements CalculatorEngine<LoanPaymentParameters> {
  const LoanPaymentEngine();
  static const basis =
      'پرداخت‌ها پایان دوره و هم‌فاصله‌اند؛ نرخ مؤثر هر قسط ثابت و نامنفی است. نرخ اسمی سالانه را بدون قرارداد تبدیل وارد نکنید. کارمزد، بیمه، مالیات، دورهٔ تنفس، ماندهٔ بالونی و گردکردن بانکی مدل نشده‌اند؛ مبلغ نظری است و جای قرارداد واقعی یا توصیهٔ اخذ وام نیست.';
  @override
  String get calculatorId => 'loan_payment';
  @override
  InputBinding<LoanPaymentParameters> bind(CalculatorInput input) {
    final p = LoanPaymentParameters(
      principal: input.requireNumber('principal'),
      periodRate: input.requireNumber('period_rate'),
      periods: input.requireNumber('periods'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(LoanPaymentParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (p.principal == 0) {
      return financeResult(
        id: calculatorId,
        label: 'قسط نظری پایان دوره',
        value: 0,
        unit: 'ریال/قسط',
        basis: basis,
        details: [
          financeMetric('total_paid', 'مجموع پرداخت نظری', 0, unit: 'ریال'),
          financeMetric('total_interest', 'مجموع بهرهٔ نظری', 0, unit: 'ریال'),
        ],
      );
    }
    final denominator = p.periodRate == 0
        ? 1.0
        : -financeExpm1(-p.periods * financeLog1p(p.periodRate));
    final payment = p.periodRate == 0
        ? p.principal / p.periods
        : p.principal * (p.periodRate / denominator);
    final total = p.periodRate == 0 ? p.principal : payment * p.periods;
    final interest = p.periodRate == 0 ? 0.0 : total - p.principal;
    if (lostNonzero(payment, true) ||
        !total.isFinite ||
        !interest.isFinite ||
        (p.periodRate > 0 && interest <= total.abs() * 2e-15)) {
      return financeRange();
    }
    return financeResult(
      id: calculatorId,
      label: 'قسط نظری پایان دوره',
      value: payment,
      unit: 'ریال/قسط',
      basis: basis,
      details: [
        financeMetric('total_paid', 'مجموع پرداخت نظری', total, unit: 'ریال'),
        financeMetric(
          'total_interest',
          'مجموع بهرهٔ نظری',
          interest,
          unit: 'ریال',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(LoanPaymentParameters p) {
    final issues = validateFinance([
      FinanceField('principal', 'اصل وام', p.principal, min: 0),
      FinanceField(
        'period_rate',
        'نرخ مؤثر هر فاصلهٔ پرداخت',
        p.periodRate,
        min: 0,
      ),
      FinanceField(
        'periods',
        'تعداد اقساط پایان دوره',
        p.periods,
        min: 0,
        max: 1000000,
        exclusiveMin: true,
        integer: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
