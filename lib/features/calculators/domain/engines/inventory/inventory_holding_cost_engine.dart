import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class InventoryHoldingCostParameters implements CalculatorParameters {
  const InventoryHoldingCostParameters({
    required this.averageValue,
    required this.annualRate,
    required this.periodDays,
    required this.yearDays,
  });
  final double averageValue;
  final double annualRate;
  final double periodDays;
  final double yearDays;
}

final class InventoryHoldingCostEngine
    implements CalculatorEngine<InventoryHoldingCostParameters> {
  const InventoryHoldingCostEngine();
  static const name = 'هزینهٔ نگهداری موجودی';
  static const basis =
      'نرخ سالانه باید اجزای انتخابی سازمان مانند سرمایه، بیمه، انبارداری و کهنگی را بدون دوباره‌شماری پوشش دهد. تخصیص به روزها خطی است، نه سود مرکب؛ هزینهٔ ثابت مستقل از موجودی خودکار اضافه نمی‌شود. مبنای ۳۶۰/۳۶۵ یا روز کاری سال باید با نرخ و دوره سازگار باشد و میانگین ارزش موجودی هم‌دوره باشد.';
  @override
  String get calculatorId => 'inventory_holding_cost';
  @override
  InputBinding<InventoryHoldingCostParameters> bind(CalculatorInput input) {
    final p = InventoryHoldingCostParameters(
      averageValue: input.requireNumber('average_value'),
      annualRate: input.requireNumber('annual_rate'),
      periodDays: input.requireNumber('period_days'),
      yearDays: input.requireNumber('year_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(InventoryHoldingCostParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.averageValue == 0 || p.annualRate == 0 || p.periodDays == 0
        ? 0.0
        : positiveFromLog(
            math.log(p.averageValue) +
                math.log(p.annualRate) +
                math.log(p.periodDays) -
                math.log(p.yearDays),
          );
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      unit: 'ریال/دوره',
      nonzero: p.averageValue > 0 && p.annualRate > 0 && p.periodDays > 0,
      basis: basis,
    );
  }

  List<CalculationIssue> _validate(InventoryHoldingCostParameters p) {
    final issues = toolValidate([
      ToolNumber('average_value', 'متوسط ارزش موجودی', p.averageValue, min: 0),
      ToolNumber(
        'annual_rate',
        'نرخ سالانهٔ هزینهٔ نگهداری',
        p.annualRate,
        min: 0,
      ),
      ToolNumber('period_days', 'روزهای دورهٔ هزینه', p.periodDays, min: 0),
      ToolNumber(
        'year_days',
        'تعداد روز مبنای سال',
        p.yearDays,
        min: 0,
        strictMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
