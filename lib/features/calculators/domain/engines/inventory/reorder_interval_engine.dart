import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class ReorderIntervalParameters implements CalculatorParameters {
  const ReorderIntervalParameters({
    required this.orderQuantity,
    required this.annualDemand,
    required this.yearDays,
  });
  final double orderQuantity;
  final double annualDemand;
  final double yearDays;
}

final class ReorderIntervalEngine
    implements CalculatorEngine<ReorderIntervalParameters> {
  const ReorderIntervalEngine();
  static const name = 'فاصلهٔ زمانی بازسفارش';
  static const basis =
      'مصرف یکنواخت، مقدار سفارش ثابت و نبود کمبود فرض شده‌اند؛ Q می‌تواند EOQ یا مقدار سیاست سازمان باشد. این زمان، فاصلهٔ متوسط سفارش است نه زمان تأمین؛ برنامهٔ تقویمی واقعی یا مدل بهینهٔ بازنگری ادواری نیست. روزهای مبنای سال باید با تقاضا و روز کاری/تقویمی سازگار باشند.';
  @override
  String get calculatorId => 'reorder_interval';
  @override
  InputBinding<ReorderIntervalParameters> bind(CalculatorInput input) {
    final p = ReorderIntervalParameters(
      orderQuantity: input.requireNumber('order_quantity'),
      annualDemand: input.requireNumber('annual_demand'),
      yearDays: input.requireNumber('year_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(ReorderIntervalParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = positiveFromLog(
      math.log(p.orderQuantity) -
          math.log(p.annualDemand) +
          math.log(p.yearDays),
    );
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      unit: 'روز/سفارش',
      nonzero: true,
      basis: basis,
    );
  }

  List<CalculationIssue> _validate(ReorderIntervalParameters p) {
    final issues = toolValidate([
      ToolNumber(
        'order_quantity',
        'مقدار ثابت هر سفارش',
        p.orderQuantity,
        min: 0,
        strictMin: true,
      ),
      ToolNumber(
        'annual_demand',
        'تقاضای سالانه',
        p.annualDemand,
        min: 0,
        strictMin: true,
      ),
      ToolNumber(
        'year_days',
        'روزهای مبنای سال',
        p.yearDays,
        min: 0,
        strictMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
