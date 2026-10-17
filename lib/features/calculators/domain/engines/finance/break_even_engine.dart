import '../../calculator_domain.dart';
import 'finance_support.dart';

final class BreakEvenParameters implements CalculatorParameters {
  const BreakEvenParameters({
    required this.fixedCost,
    required this.unitPrice,
    required this.variableCost,
  });
  final double fixedCost;
  final double unitPrice;
  final double variableCost;
}

final class BreakEvenEngine implements CalculatorEngine<BreakEvenParameters> {
  const BreakEvenEngine();
  static const basis =
      'مدل تک‌محصول یا ترکیب فروش ثابت با واحد معادل است؛ قیمت و هزینهٔ متغیر ثابت و کل تولید فروخته‌شده فرض می‌شوند. هزینهٔ ثابت مربوط به همان بازه است. مالیات، تغییر موجودی و محدودیت ظرفیت لحاظ نشده‌اند. مقدار پیوسته و شمار واحد کاملِ گرد‌شده رو به بالا جدا نمایش داده می‌شوند؛ این‌ها پیش‌بینی فروش یا توصیه نیستند.';
  @override
  String get calculatorId => 'break_even';
  @override
  InputBinding<BreakEvenParameters> bind(CalculatorInput input) {
    final p = BreakEvenParameters(
      fixedCost: input.requireNumber('fixed_cost'),
      unitPrice: input.requireNumber('unit_price'),
      variableCost: input.requireNumber('variable_cost'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(BreakEvenParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final margin = p.unitPrice - p.variableCost;
    final units = p.fixedCost / margin;
    if (lostNonzero(units, p.fixedCost > 0) || units > 9007199254740991) {
      return financeRange();
    }
    final whole = units.ceilToDouble();
    final revenue = units * p.unitPrice;
    if (lostNonzero(revenue, units > 0)) return financeRange();
    return financeResult(
      id: calculatorId,
      label: 'فروش سربه‌سر پیوسته',
      value: units,
      unit: 'واحد',
      basis: basis,
      details: [
        financeMetric(
          'whole_units',
          'حداقل واحد کامل (رو به بالا)',
          whole,
          unit: 'واحد',
        ),
        financeMetric(
          'break_even_revenue',
          'درآمد سربه‌سر پیوسته',
          revenue,
          unit: 'ریال',
        ),
        financeMetric(
          'contribution',
          'حاشیهٔ مشارکت هر واحد',
          margin,
          unit: 'ریال/واحد',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(BreakEvenParameters p) {
    final issues = validateFinance([
      FinanceField('fixed_cost', 'هزینهٔ ثابت بازه', p.fixedCost, min: 0),
      FinanceField(
        'unit_price',
        'قیمت فروش هر واحد',
        p.unitPrice,
        min: 0,
        exclusiveMin: true,
      ),
      FinanceField(
        'variable_cost',
        'هزینهٔ متغیر هر واحد',
        p.variableCost,
        min: 0,
      ),
    ]);
    if (issues.isNotEmpty) return issues;
    if (p.unitPrice <= p.variableCost) {
      issues.add(
        CalculationIssue(
          code: 'nonpositive_margin',
          fieldId: 'unit_price',
          message: 'قیمت باید از هزینهٔ متغیر بیشتر باشد؛ آستانهٔ فروش سربه‌سر متناهی با حاشیهٔ غیرمثبت گزارش نمی‌شود.',
        ),
      );
    }
    return issues;
  }
}
