import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class InventoryTurnoverParameters implements CalculatorParameters {
  const InventoryTurnoverParameters({
    required this.cogs,
    required this.averageInventory,
  });
  final double cogs;
  final double averageInventory;
}

final class InventoryTurnoverEngine
    implements CalculatorEngine<InventoryTurnoverParameters> {
  const InventoryTurnoverEngine();
  static const name = 'نرخ گردش موجودی';
  static const basis =
      'صورت COGS است، نه درآمد فروش؛ مخرج متوسط موجودی با همان مبنای ارزش‌گذاری و بازه است. میانگین اول/آخر دوره تنها یک برآورد است و در فصل‌گرایی ممکن است میانگین دوره‌ای دقیق‌تر لازم شود. خروجی بار در دورهٔ انتخابی است، نه الزاماً سالانه؛ معیار صنعت/سیاست بدون داده اعمال نمی‌شود.';
  @override
  String get calculatorId => 'inventory_turnover';
  @override
  InputBinding<InventoryTurnoverParameters> bind(CalculatorInput input) {
    final p = InventoryTurnoverParameters(
      cogs: input.requireNumber('cogs'),
      averageInventory: input.requireNumber('average_inventory'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(InventoryTurnoverParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.cogs / p.averageInventory;
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      unit: 'بار/دوره',
      nonzero: p.cogs > 0,
      basis: basis,
    );
  }

  List<CalculationIssue> _validate(InventoryTurnoverParameters p) {
    final issues = toolValidate([
      ToolNumber('cogs', 'بهای تمام‌شدهٔ فروش دوره', p.cogs, min: 0),
      ToolNumber(
        'average_inventory',
        'ارزش متوسط موجودی به بهای تمام‌شده',
        p.averageInventory,
        min: 0,
        strictMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
