import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class RopParameters implements CalculatorParameters {
  const RopParameters({
    required this.dailyDemand,
    required this.leadTime,
    required this.safetyStock,
  });
  final double dailyDemand;
  final double leadTime;
  final double safetyStock;
}

final class RopEngine implements CalculatorEngine<RopParameters> {
  const RopEngine();
  static const name = 'نقطهٔ سفارش مجدد — ROP';
  static const basis =
      'تقاضا و زمان تأمین بر مبنای روزهای یکسان و ذخیرهٔ اطمینان هم‌واحدند. در بازنگری پیوسته معمولاً موقعیت موجودی (موجودی دست + سفارش در راه − عقب‌افتادگی) با ROP مقایسه می‌شود، نه فقط موجودی فیزیکی. این ابزار سفارش واقعی صادر یا عدم‌قطعیت را خودکار برآورد نمی‌کند؛ SS باید با روش مناسب تعیین شود.';
  @override
  String get calculatorId => 'rop';
  @override
  InputBinding<RopParameters> bind(CalculatorInput input) {
    final p = RopParameters(
      dailyDemand: input.requireNumber('daily_demand'),
      leadTime: input.requireNumber('lead_time'),
      safetyStock: input.requireNumber('safety_stock'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(RopParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final during = p.dailyDemand * p.leadTime;
    if (invalidNumeric(during, nonzero: p.dailyDemand > 0 && p.leadTime > 0)) {
      return toolRange();
    }
    return toolResult(
      id: calculatorId,
      label: name,
      value: during + p.safetyStock,
      unit: 'واحد',
      basis: basis,
    );
  }

  List<CalculationIssue> _validate(RopParameters p) {
    final issues = toolValidate([
      ToolNumber('daily_demand', 'تقاضای متوسط روزانه', p.dailyDemand, min: 0),
      ToolNumber('lead_time', 'زمان تأمین', p.leadTime, min: 0),
      ToolNumber(
        'safety_stock',
        'ذخیرهٔ اطمینان انتخابی',
        p.safetyStock,
        min: 0,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
