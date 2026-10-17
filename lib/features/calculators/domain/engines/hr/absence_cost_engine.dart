import '../../calculator_domain.dart';
import '../../hr/hr_support.dart';
import '../../statistics/tool_numeric.dart';

final class AbsenceCostParameters implements CalculatorParameters {
  const AbsenceCostParameters({
    required this.paidAbsentHours,
    required this.loadedHourlyCost,
    required this.incrementalCoverCost,
    required this.periodDays,
  });
  final double paidAbsentHours;
  final double loadedHourlyCost;
  final double incrementalCoverCost;
  final double periodDays;
}

final class AbsenceCostEngine
    implements CalculatorEngine<AbsenceCostParameters> {
  const AbsenceCostEngine();
  static const basis =
      'این مدل هزینهٔ مستقیم غیبت با پرداخت را برآورد می‌کند: نفرساعت غیبت با پرداخت × هزینهٔ ساعتی با بار کارفرما + هزینهٔ افزودهٔ پوشش غیبت، همگی در یک بازه و دامنه. صورت نسبت و مخرج شمارشی ندارد؛ هزینهٔ ساعتی مبنای ریال به‌ازای یک نفرساعت است و خروجی جمع ریالی دوره است. نرخ ساعتی مثبت و تخصیص بدون هم‌پوشانی فرض می‌شود؛ جزء دستمزد، سهم تخصیصی پرداخت است نه الزاماً هزینهٔ نقدی قابل‌اجتناب یا صرفه‌جویی ناشی از حذف غیبت. هزینهٔ پوشش فقط مبلغ افزوده است، نه دوباره‌شماری دستمزد غایب/حقوق عادی. غیبت بدون پرداخت، افت تولید، کیفیت، فرصت و هزینهٔ غیرمستقیم خودکار اضافه نمی‌شوند. نفرساعت صفر همراه هزینهٔ پوشش مثبت ناسازگار است و رد می‌شود؛ نبود غیبت با پوشش صفر می‌تواند هزینهٔ مستقیم صفر بدهد. این عدد تشخیص علت غیبت یا قضاوت دربارهٔ کارکنان نیست.';
  @override
  String get calculatorId => 'absence_cost';
  @override
  InputBinding<AbsenceCostParameters> bind(CalculatorInput input) {
    final p = AbsenceCostParameters(
      paidAbsentHours: input.requireNumber('paid_absent_hours'),
      loadedHourlyCost: input.requireNumber('loaded_hourly_cost'),
      incrementalCoverCost: input.requireNumber('incremental_cover_cost'),
      periodDays: input.requireNumber('period_days'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(AbsenceCostParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final paid = p.paidAbsentHours * p.loadedHourlyCost;
    if (invalidNumeric(paid, nonzero: p.paidAbsentHours > 0)) {
      return toolRange();
    }
    final total = paid + p.incrementalCoverCost;
    return hrResult(
      id: calculatorId,
      label: 'هزینهٔ مستقیم غیبت با پرداخت در بازه',
      value: total,
      basis: basis,
      periodDays: p.periodDays,
      unit: 'ریال/بازه',
      details: [
        metric(
          'paid_absence_cost',
          'هزینهٔ مستقیم زمان غیبت با پرداخت',
          paid,
          unit: 'ریال',
        ),
        metric(
          'additional_cover_cost',
          'هزینهٔ افزودهٔ پوشش؛ بدون تکرار حقوق عادی',
          p.incrementalCoverCost,
          unit: 'ریال',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(AbsenceCostParameters p) {
    final issues = validateHr([
      HrNumber(
        'paid_absent_hours',
        'نفرساعت غیبت با پرداخت',
        p.paidAbsentHours,
      ),
      HrNumber(
        'loaded_hourly_cost',
        'هزینهٔ ساعتی با بار کارفرما',
        p.loadedHourlyCost,
        positive: true,
      ),
      HrNumber(
        'incremental_cover_cost',
        'هزینهٔ اضافی پوشش غیبت',
        p.incrementalCoverCost,
      ),
      HrNumber('period_days', 'طول بازهٔ گزارش', p.periodDays, positive: true),
    ]);
    if (issues.isNotEmpty) return issues;
    if (p.paidAbsentHours == 0 && p.incrementalCoverCost > 0) {
      issues.add(
        CalculationIssue(
          code: 'cover_without_absence',
          fieldId: 'incremental_cover_cost',
          message: 'با نفرساعت غیبت صفر، هزینهٔ پوشش مثبت با این مدل سازگار نیست؛ دامنه و بازه را بررسی کنید.',
        ),
      );
    }
    return issues;
  }
}
