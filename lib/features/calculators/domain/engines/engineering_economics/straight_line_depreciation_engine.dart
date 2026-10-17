import '../../calculator_domain.dart';
import '../../engineering_economics/engineering_math.dart';
import '../../statistics/tool_numeric.dart';

final class StraightLineDepreciationParameters implements CalculatorParameters {
  const StraightLineDepreciationParameters({
    required this.cost,
    required this.salvage,
    required this.life,
    required this.year,
  });
  final double cost, salvage, life, year;
}

final class StraightLineDepreciationEngine
    implements CalculatorEngine<StraightLineDepreciationParameters> {
  const StraightLineDepreciationEngine();
  static const basis =
      'استهلاک حسابداری خط مستقیم با سال‌های کامل: بهای C، اسقاط S و عمر L. هزینهٔ سال انتخابی برای k≥۱ برابر (C−S)/L؛ سال صفر هزینه ندارد. ارزش دفتری پایان عمر دقیقاً اسقاط است. استهلاک جریان نقدی نیست و قواعد مالیاتی/نیم‌سال/تجدید ارزیابی لحاظ نمی‌شود.';
  @override
  String get calculatorId => 'straight_line_depreciation';
  @override
  InputBinding<StraightLineDepreciationParameters> bind(CalculatorInput input) {
    final p = StraightLineDepreciationParameters(
      cost: input.requireNumber('cost'),
      salvage: input.requireNumber('salvage'),
      life: input.requireNumber('life'),
      year: input.requireNumber('year'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  List<CalculationIssue> _validate(StraightLineDepreciationParameters p) => [
    ...toolValidate([
      ToolNumber('cost', 'بهای تمام‌شده دارایی', p.cost, min: 0),
      ToolNumber('salvage', 'ارزش اسقاط؛ کف ارزش دفتری', p.salvage, min: 0),
      ToolNumber('life', 'عمر مفید', p.life, min: 1, max: 10000, integer: true),
      ToolNumber(
        'year',
        'سال مورد بررسی',
        p.year,
        min: 0,
        max: 10000,
        integer: true,
      ),
    ]),
    if (p.salvage > p.cost)
      CalculationIssue(
        code: 'salvage_exceeds_cost',
        fieldId: 'salvage',
        message: 'ارزش اسقاط نمی‌تواند بیشتر از بهای اولیه باشد.',
      ),
    if (p.year > p.life)
      CalculationIssue(
        code: 'year_exceeds_life',
        fieldId: 'year',
        message: 'سال مورد بررسی نمی‌تواند از عمر مفید بیشتر باشد.',
      ),
  ];
  @override
  CalculationOutcome calculate(StraightLineDepreciationParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return economicSafe(() {
      final base = p.cost - p.salvage,
          annual = economicChecked(base / p.life, nonzero: base > 0),
          expense = p.year == 0 ? 0.0 : annual,
          accumulated = p.year == p.life
              ? base
              : economicChecked(
                  base * (p.year / p.life),
                  nonzero: base > 0 && p.year > 0,
                ),
          book = p.year == 0
              ? p.cost
              : p.year == p.life
              ? p.salvage
              : economicChecked(p.salvage + base * (1 - p.year / p.life)),
          begin = p.year == 0
              ? p.cost
              : economicChecked(p.salvage + base * (1 - (p.year - 1) / p.life));
      return economicResult(
        id: calculatorId,
        label: 'هزینهٔ استهلاک در سال انتخابی',
        value: expense,
        unit: 'ریال/سال',
        basis: basis,
        details: [
          metric(
            'annual_depreciation',
            'استهلاک سالانهٔ خط مستقیم',
            annual,
            unit: 'ریال/سال',
          ),
          metric('book_begin', 'ارزش دفتری ابتدای سال', begin, unit: 'ریال'),
          metric('book_end', 'ارزش دفتری پایان سال', book, unit: 'ریال'),
          metric(
            'accumulated',
            'استهلاک انباشته تا پایان سال',
            accumulated,
            unit: 'ریال',
          ),
        ],
      );
    });
  }
}
