import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class XbarControlParameters implements CalculatorParameters {
  XbarControlParameters({
    required this.subgroupSize,
    required Iterable<double> observations,
  }) : observations = List.unmodifiable(observations);
  final double subgroupSize;

  /// Time-ordered equal rational subgroups: n consecutive observations each.
  final List<double> observations;
}

final class XbarControlEngine
    implements CalculatorEngine<XbarControlParameters> {
  const XbarControlEngine();
  static const basis =
      'روش X-bar/R با زیرگروه‌های عقلانی هم‌اندازه و ترتیب زمانی است. هر n سطر یک زیرگروه؛ مشاهده‌ها مستقل و درون گروه تقریباً نرمال، اندازه‌گیری معتبر و دورهٔ مبنا همگن فرض می‌شوند. سیگما از Rbar/d2 و حدود از میانگین کل ±۳ سیگمای میانگین برآورد می‌شوند؛ d2 جدول با سه رقم اعشار برای n=۲ تا ۱۰ است. این‌ها حدود کنترل تخمینی‌اند، نه حدود مشخصات مهندسی. فقط عبور سختِ یک میانگین از حدود سه‌سیگما علامت‌گذاری می‌شود؛ قواعد روند/دنباله و نمودار R کامل اجرا نمی‌شوند. نبود علامت، اثبات کنترل یا کیفیت خوب نیست؛ دادهٔ کم صرفاً نمونهٔ آموزشی است.';
  // Conventional normal-range expectation constants, rounded to 3 decimals.
  static const d2 = {
    2: 1.128,
    3: 1.693,
    4: 2.059,
    5: 2.326,
    6: 2.534,
    7: 2.704,
    8: 2.847,
    9: 2.970,
    10: 3.078,
  };
  @override
  String get calculatorId => 'xbar_control';
  @override
  InputBinding<XbarControlParameters> bind(CalculatorInput input) {
    final p = XbarControlParameters(
      subgroupSize: input.requireNumber('subgroup_size'),
      observations: input.requireNumberList('observations'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(XbarControlParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final n = p.subgroupSize.toInt();
    final means = <double>[], ranges = <double>[];
    for (var i = 0; i < p.observations.length; i += n) {
      final group = p.observations.sublist(i, i + n);
      final mean = scaledMean(group),
          range = group.reduce(math.max) - group.reduce(math.min);
      if (!mean.isFinite || !range.isFinite) return toolRange();
      means.add(mean);
      ranges.add(range);
    }
    final center = scaledMean(means), rbar = scaledMean(ranges);
    if (!center.isFinite || !rbar.isFinite) return toolRange();
    if (rbar == 0) {
      return toolFailure(
        'zero_range',
        'دامنهٔ همهٔ زیرگروه‌ها صفر است؛ سیگما و حدود کنترلِ برآوردی قابل اتکا از روش R به دست نمی‌آید.',
        fieldId: 'observations',
      );
    }
    final divisor = d2[n]!,
        sigma = rbar / divisor,
        a2 = 3 / (divisor * math.sqrt(n));
    final half = a2 * rbar, lower = center - half, upper = center + half;
    if (invalidNumeric(sigma, nonzero: true) ||
        invalidNumeric(half, nonzero: true) ||
        !lower.isFinite ||
        !upper.isFinite ||
        lower == upper) {
      return toolRange();
    }
    final outside = [
      for (var i = 0; i < means.length; i++)
        if (means[i] < lower || means[i] > upper) i + 1.0,
    ];
    return toolResult(
      id: calculatorId,
      label: 'خط مرکزی میانگین‌ها',
      value: center,
      unit: 'واحد مشترک',
      basis: basis,
      details: [
        metric('lcl', 'حد کنترل پایین میانگین', lower, unit: 'واحد مشترک'),
        metric('ucl', 'حد کنترل بالای میانگین', upper, unit: 'واحد مشترک'),
        metric('rbar', 'میانگین دامنه‌ها', rbar, unit: 'واحد مشترک'),
        metric(
          'sigma_within',
          'سیگمای تخمینی از دامنه',
          sigma,
          unit: 'واحد مشترک',
        ),
        metric('d2', 'ثابت d2 با سه رقم اعشار', divisor),
        metric('a2', 'ضریب A2 محاسبه‌شده از d2', a2),
        seriesMetric(
          'subgroup_means',
          'میانگین زیرگروه‌ها به ترتیب زمانی',
          means,
          unit: 'واحد مشترک',
        ),
        seriesMetric(
          'subgroup_ranges',
          'دامنهٔ زیرگروه‌ها به ترتیب زمانی',
          ranges,
          unit: 'واحد مشترک',
        ),
        metric(
          'signal_count',
          'تعداد عبور از حدود، نه رتبهٔ خوب/بد',
          outside.length.toDouble(),
        ),
        if (outside.isNotEmpty)
          seriesMetric(
            'outside_subgroups',
            'شمارهٔ یک‌مبنای زیرگروه‌های خارج از حدود',
            outside,
          )
        else
          textMetric(
            'no_signal',
            'قاعدهٔ تک‌نقطهٔ سه‌سیگما',
            'عبور مشاهده نشد؛ این نتیجه اثبات کنترل آماری نیست',
          ),
      ],
    );
  }

  List<CalculationIssue> _validate(XbarControlParameters p) {
    final issues = toolValidate([
      ToolNumber(
        'subgroup_size',
        'اندازهٔ زیرگروه',
        p.subgroupSize,
        min: 2,
        max: 10,
        integer: true,
      ),
    ]);
    if (p.observations.length > 1000 || p.observations.length < 4) {
      issues.add(
        CalculationIssue(
          code: 'invalid_count',
          fieldId: 'observations',
          message: '۴ تا ۱۰۰۰ مشاهده و حداقل دو زیرگروه لازم است.',
        ),
      );
    }
    for (var i = 0; i < p.observations.length; i++) {
      if (!p.observations[i].isFinite) {
        issues.add(
          CalculationIssue(
            code: 'invalid_observation',
            fieldId: 'observations',
            itemIndex: i,
            message: 'همهٔ مشاهده‌ها باید متناهی باشند.',
          ),
        );
      }
    }
    if (issues.isNotEmpty) return issues;
    final n = p.subgroupSize.toInt();
    if (p.observations.length % n != 0 || p.observations.length / n < 2) {
      issues.add(
        CalculationIssue(
          code: 'unequal_subgroups',
          fieldId: 'observations',
          message: 'تعداد مشاهده‌ها باید مضرب اندازهٔ زیرگروه و شامل حداقل دو زیرگروه کامل باشد.',
        ),
      );
    }
    return issues;
  }
}
