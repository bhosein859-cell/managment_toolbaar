import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class EoqParameters implements CalculatorParameters {
  const EoqParameters({
    required this.annualDemand,
    required this.orderCost,
    required this.holdingCost,
  });
  final double annualDemand;
  final double orderCost;
  final double holdingCost;
}

final class EoqEngine implements CalculatorEngine<EoqParameters> {
  const EoqEngine();
  static const name = 'مقدار اقتصادی سفارش — EOQ';
  static const basis =
      'مدل کلاسیک تک‌قلم با تقاضای سالانهٔ ثابت، تأمین یک‌باره، نبود کمبود/تخفیف مقداری و هزینهٔ ثابت هر سفارش است. H هزینهٔ سالانهٔ هر واحد است، نه نرخ درصدی. هزینهٔ خرید ثابت D×قیمت در هزینهٔ مرتبط نمایش‌داده‌شده نیست. مقدار پیوسته است؛ بسته‌بندی، ظرفیت، حداقل سفارش و گردکردن خودکار اعمال نمی‌شوند.';
  @override
  String get calculatorId => 'eoq';
  @override
  InputBinding<EoqParameters> bind(CalculatorInput input) {
    final p = EoqParameters(
      annualDemand: input.requireNumber('annual_demand'),
      orderCost: input.requireNumber('order_cost'),
      holdingCost: input.requireNumber('holding_cost'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(EoqParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final logQ =
        (math.log(2) +
            math.log(p.annualDemand) +
            math.log(p.orderCost) -
            math.log(p.holdingCost)) /
        2;
    final value = positiveFromLog(logQ);
    if (invalidNumeric(value, nonzero: true)) return toolRange();
    final ordering = positiveFromLog(
      math.log(p.annualDemand) - logQ + math.log(p.orderCost),
    );
    final holding = positiveFromLog(
      logQ - math.log(2) + math.log(p.holdingCost),
    );
    final cost = ordering + holding;
    if (invalidNumeric(ordering, nonzero: true) ||
        invalidNumeric(holding, nonzero: true) ||
        !cost.isFinite) {
      return toolRange();
    }
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      unit: 'واحد/سفارش',
      basis: basis,
      details: [
        metric(
          'ordering_cost',
          'هزینهٔ سفارش سالانه',
          ordering,
          unit: 'ریال/سال',
        ),
        metric(
          'holding_cost',
          'هزینهٔ نگهداری چرخه‌ای سالانه',
          holding,
          unit: 'ریال/سال',
        ),
        metric(
          'relevant_cost',
          'جمع هزینهٔ مرتبط، بدون خرید',
          cost,
          unit: 'ریال/سال',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(EoqParameters p) {
    final issues = toolValidate([
      ToolNumber(
        'annual_demand',
        'تقاضای سالانه',
        p.annualDemand,
        min: 0,
        strictMin: true,
      ),
      ToolNumber(
        'order_cost',
        'هزینهٔ ثابت هر سفارش',
        p.orderCost,
        min: 0,
        strictMin: true,
      ),
      ToolNumber(
        'holding_cost',
        'هزینهٔ سالانهٔ نگهداری هر واحد',
        p.holdingCost,
        min: 0,
        strictMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
