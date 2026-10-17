import 'dart:math' as math;

import '../../calculator_domain.dart';
import 'finance_support.dart';

final class CompoundInterestParameters implements CalculatorParameters {
  const CompoundInterestParameters({
    required this.principal,
    required this.periodRate,
    required this.periods,
  });
  final double principal;
  final double periodRate;
  final double periods;
}

final class CompoundInterestEngine
    implements CalculatorEngine<CompoundInterestParameters> {
  const CompoundInterestEngine();
  static const basis =
      'نرخ مؤثر مربوط به همان دورهٔ شمارش است، نه نرخ اسمی سالانهٔ تقسیم‌شده بدون قرارداد مشخص. مالیات، کارمزد، تورم و جریان میان‌دوره‌ای لحاظ نشده‌اند. نرخ منفی بیشتر از منفی صد درصد مجاز است؛ نتیجه ارزش آتی نظری است، نه پیش‌بینی یا توصیهٔ سرمایه‌گذاری.';
  @override
  String get calculatorId => 'compound_interest';
  @override
  InputBinding<CompoundInterestParameters> bind(CalculatorInput input) {
    final p = CompoundInterestParameters(
      principal: input.requireNumber('principal'),
      periodRate: input.requireNumber('period_rate'),
      periods: input.requireNumber('periods'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(CompoundInterestParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (p.principal == 0 || p.periods == 0 || p.periodRate == 0) {
      return financeResult(
        id: calculatorId,
        label: 'ارزش آتی',
        value: p.principal,
        unit: 'ریال',
        basis: basis,
        details: [
          financeMetric('interest', 'سود/زیان انباشته', 0, unit: 'ریال'),
        ],
      );
    }
    final growth = p.periods * financeLog1p(p.periodRate);
    final small = growth.abs() < 0.5;
    final interestSmall = small ? p.principal * financeExpm1(growth) : 0.0;
    final fv = small
        ? p.principal + interestSmall
        : math.exp(math.log(p.principal) + growth);
    final interest = small ? interestSmall : fv - p.principal;
    if (lostNonzero(fv, true) || lostNonzero(interest, true)) {
      return financeRange();
    }
    return financeResult(
      id: calculatorId,
      label: 'ارزش آتی',
      value: fv,
      unit: 'ریال',
      basis: basis,
      details: [
        financeMetric('interest', 'سود/زیان انباشته', interest, unit: 'ریال'),
      ],
    );
  }

  List<CalculationIssue> _validate(CompoundInterestParameters p) {
    final issues = validateFinance([
      FinanceField('principal', 'اصل پول', p.principal, min: 0),
      FinanceField(
        'period_rate',
        'نرخ مؤثر ثابت هر دوره',
        p.periodRate,
        min: -1,
        exclusiveMin: true,
      ),
      FinanceField(
        'periods',
        'تعداد دوره‌های کامل',
        p.periods,
        min: 0,
        max: 1000000,
        integer: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
