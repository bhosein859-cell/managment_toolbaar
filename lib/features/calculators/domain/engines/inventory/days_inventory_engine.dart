import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class DaysInventoryParameters implements CalculatorParameters {
  const DaysInventoryParameters({
    required this.averageInventory,
    required this.cogs,
    required this.periodDays,
  });
  final double averageInventory;
  final double cogs;
  final double periodDays;
}

final class DaysInventoryEngine
    implements CalculatorEngine<DaysInventoryParameters> {
  const DaysInventoryEngine();
  static const name = 'روزهای موجودی';
  static const basis =
      'موجودی و COGS باید به بهای تمام‌شده و هم‌دوره باشند؛ مبنای روزهای دوره را صریح وارد کنید (مثلاً ۳۶۰ یا ۳۶۵ برای سال انتخابی). شاخص میانگین تاریخی است، نه تضمین زمان فروش یا شاخص فسادپذیری هر قلم. COGS صفر روزهای متناهی قابل محاسبه نمی‌دهد.';
  @override
  String get calculatorId => 'days_inventory';
  @override
  InputBinding<DaysInventoryParameters> bind(CalculatorInput input) {
    final p = DaysInventoryParameters(
      averageInventory: input.requireNumber('average_inventory'),
      cogs: input.requireNumber('cogs'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(DaysInventoryParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.averageInventory == 0
        ? 0.0
        : positiveFromLog(
            math.log(p.averageInventory) -
                math.log(p.cogs) +
                math.log(p.periodDays),
          );
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      unit: 'روز',
      nonzero: p.averageInventory > 0,
      basis: basis,
    );
  }

  List<CalculationIssue> _validate(DaysInventoryParameters p) {
    final issues = toolValidate([
      ToolNumber(
        'average_inventory',
        'متوسط موجودی به بهای تمام‌شده',
        p.averageInventory,
        min: 0,
      ),
      ToolNumber(
        'cogs',
        'بهای تمام‌شدهٔ فروش همان دوره',
        p.cogs,
        min: 0,
        strictMin: true,
      ),
      ToolNumber(
        'period_days',
        'طول دورهٔ گزارش',
        p.periodDays,
        min: 0,
        strictMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
