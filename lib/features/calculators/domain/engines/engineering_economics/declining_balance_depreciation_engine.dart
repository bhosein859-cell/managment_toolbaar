import '../../calculator_domain.dart';
import '../../engineering_economics/engineering_math.dart';
import '../../statistics/tool_numeric.dart';

final class DecliningBalanceDepreciationParameters
    implements CalculatorParameters {
  const DecliningBalanceDepreciationParameters({
    required this.cost,
    required this.salvage,
    required this.depreciationRate,
    required this.life,
    required this.year,
  });
  final double cost, salvage, depreciationRate, life, year;
}

final class DecliningBalanceDepreciationEngine
    implements CalculatorEngine<DecliningBalanceDepreciationParameters> {
  const DecliningBalanceDepreciationEngine();
  static const basis =
      'ماندهٔ نزولی با نرخ سالانهٔ ثابت انتخابی d و کف اسقاط S؛ نه الزاماً روش دوبرابر و نه روش مالیاتی خاص. سال صفر بدون هزینه؛ هزینهٔ هر سال هرگز از فاصله تا اسقاط بیشتر نیست. در پایان عمر، تغییر روش به خط مستقیم یا حذف اجباری مانده انجام نمی‌شود؛ اگر ارزش دفتری بالاتر از اسقاط بماند هشدار داده می‌شود. عمر فقط دامنهٔ گزارش است، نه تضمین رسیدن به اسقاط.';
  @override
  String get calculatorId => 'declining_balance_depreciation';
  @override
  InputBinding<DecliningBalanceDepreciationParameters> bind(
    CalculatorInput input,
  ) {
    final p = DecliningBalanceDepreciationParameters(
      cost: input.requireNumber('cost'),
      salvage: input.requireNumber('salvage'),
      depreciationRate: input.requireNumber('depreciation_rate'),
      life: input.requireNumber('life'),
      year: input.requireNumber('year'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  List<CalculationIssue> _validate(
    DecliningBalanceDepreciationParameters p,
  ) => [
    ...toolValidate([
      ToolNumber('cost', 'بهای تمام‌شده دارایی', p.cost, min: 0),
      ToolNumber('salvage', 'ارزش اسقاط؛ کف ارزش دفتری', p.salvage, min: 0),
      ToolNumber(
        'depreciation_rate',
        'نرخ ثابت استهلاک مانده نزولی',
        p.depreciationRate,
        min: 0.0,
        max: 1.0,
      ),
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
  CalculationOutcome calculate(DecliningBalanceDepreciationParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return economicSafe(() {
      final d = p.depreciationRate;
      double bookAt(double year) {
        if (year == 0 || d == 0 || p.cost == p.salvage) return p.cost;
        if (d == 1 || p.cost == 0) return p.salvage;
        return decliningBook(p.cost, p.salvage, d, year);
      }

      final begin = p.year == 0 ? p.cost : bookAt(p.year - 1),
          book = bookAt(p.year);
      final available = begin - p.salvage,
          uncapped = p.year == 0 || available == 0 || d == 0
              ? 0.0
              : economicChecked(begin * d, nonzero: true),
          expense = p.year == 0
              ? 0.0
              : (uncapped < available ? uncapped : available);
      double accumulated;
      if (p.year == 0 || d == 0 || p.cost == p.salvage) {
        accumulated = 0;
      } else if (d == 1 || book == p.salvage) {
        accumulated = p.cost - p.salvage;
      } else {
        accumulated = economicChecked(
          p.cost * (-economicExpm1(p.year * economicLog1p(-d))),
          nonzero: p.cost > 0,
        );
      }
      return economicResult(
        id: calculatorId,
        label: 'هزینهٔ استهلاک مانده نزولی در سال انتخابی',
        value: expense,
        unit: 'ریال/سال',
        basis: basis,
        details: [
          metric('book_begin', 'ارزش دفتری ابتدای سال', begin, unit: 'ریال'),
          metric(
            'book_end',
            'ارزش دفتری پایان سال با کف اسقاط',
            book,
            unit: 'ریال',
          ),
          metric(
            'accumulated',
            'استهلاک انباشته تا پایان سال',
            accumulated,
            unit: 'ریال',
          ),
        ],
        warnings: [
          if (p.year == p.life && book > p.salvage)
            CalculationWarning(
              code: 'residual_above_salvage',
              message: 'در پایان عمر، ارزش دفتری هنوز از اسقاط بالاتر است؛ تغییر روش یا حذف مانده خودکار انجام نشد.',
            ),
        ],
      );
    });
  }
}
