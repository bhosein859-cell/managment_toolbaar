import 'dart:math' as math;

import '../../calculator_domain.dart';
import 'finance_support.dart';

final class WaccParameters implements CalculatorParameters {
  const WaccParameters({
    required this.equity,
    required this.debt,
    required this.equityCost,
    required this.debtCost,
    required this.taxRate,
  });
  final double equity;
  final double debt;
  final double equityCost;
  final double debtCost;
  final double taxRate;
}

final class WaccEngine implements CalculatorEngine<WaccParameters> {
  const WaccEngine();
  static const basis =
      'وزن‌ها بر مبنای ارزش بازار بدهی و حقوق صاحبان سهام در یک تاریخ‌اند، نه الزاماً ارزش دفتری. هزینه‌ها و نرخ مالیات باید با دوره، ارز و مبنای اسمی/واقعی مشترک باشند. سپر مالیاتی کامل بهره فرض شده؛ محدودیت کسر مالیاتی، ساختار پیچیده و هزینهٔ انتشار خودکار مدل نمی‌شوند. این عدد توصیهٔ شخصی برای انتخاب سرمایه‌گذاری نیست.';
  @override
  String get calculatorId => 'wacc';
  @override
  InputBinding<WaccParameters> bind(CalculatorInput input) {
    final p = WaccParameters(
      equity: input.requireNumber('equity'),
      debt: input.requireNumber('debt'),
      equityCost: input.requireNumber('equity_cost'),
      debtCost: input.requireNumber('debt_cost'),
      taxRate: input.requireNumber('tax_rate'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(WaccParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final scale = math.max(p.equity, p.debt);
    final e = p.equity / scale, d = p.debt / scale;
    if (lostNonzero(e, p.equity > 0) || lostNonzero(d, p.debt > 0)) {
      return financeRange();
    }
    final ew = e / (e + d), dw = d / (e + d);
    final afterTax = p.debt == 0 ? 0.0 : p.debtCost * (1 - p.taxRate);
    final equityPart = ew * p.equityCost, debtPart = dw * afterTax;
    if (lostNonzero(afterTax, p.debt > 0 && p.debtCost > 0 && p.taxRate < 1) ||
        lostNonzero(equityPart, ew > 0 && p.equityCost > 0) ||
        lostNonzero(debtPart, dw > 0 && afterTax > 0)) {
      return financeRange();
    }
    final value = equityPart + debtPart;
    return financeResult(
      id: calculatorId,
      label: 'هزینهٔ سرمایهٔ موزون',
      value: value,
      percentage: true,
      basis: basis,
      details: [
        financeMetric(
          'equity_weight',
          'وزن حقوق صاحبان سهام',
          ew,
          percentage: true,
        ),
        financeMetric('debt_weight', 'وزن بدهی', dw, percentage: true),
      ],
    );
  }

  List<CalculationIssue> _validate(WaccParameters p) {
    final issues = validateFinance([
      FinanceField('equity', 'ارزش بازار حقوق صاحبان سهام', p.equity, min: 0),
      FinanceField('debt', 'ارزش بازار بدهی', p.debt, min: 0),
      FinanceField(
        'equity_cost',
        'نرخ هزینهٔ حقوق صاحبان سهام',
        p.equityCost,
        min: 0,
      ),
      FinanceField(
        'debt_cost',
        'نرخ هزینهٔ بدهی پیش از مالیات',
        p.debtCost,
        min: 0,
      ),
      FinanceField(
        'tax_rate',
        'نرخ مؤثر مالیات شرکت',
        p.taxRate,
        min: 0,
        max: 1,
      ),
    ]);
    if (issues.isNotEmpty) return issues;
    if (p.equity == 0 && p.debt == 0) {
      issues.add(
        CalculationIssue(
          code: 'zero_capital',
          fieldId: 'equity',
          message: 'مجموع سرمایهٔ بدهی و حقوق صاحبان سهام باید مثبت باشد.',
        ),
      );
    }
    return issues;
  }
}
