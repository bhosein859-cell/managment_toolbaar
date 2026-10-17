import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../decision/decision_math.dart';
import '../../decision/decision_table.dart';
import '../../statistics/tool_numeric.dart';

final class TopsisParameters implements CalculatorParameters {
  const TopsisParameters({required this.table});
  final DecisionTable table;
}

final class TopsisEngine implements CalculatorEngine<TopsisParameters> {
  const TopsisEngine();
  static const basis =
      'TOPSIS این فرم دادهٔ نامنفی می‌پذیرد. هر ستون با نرم اقلیدسی برداری نرمال و در وزن نرمال‌شده ضرب می‌شود؛ ایده‌آل مثبت/منفی با نوع هزینه/منفعت انتخاب می‌شوند. فاصلهٔ اقلیدسی و C=Dminus/(Dplus+Dminus) محاسبه می‌شود؛ معیارها مستقل از نظر جمع‌پذیری و مقیاس عددی معنادار فرض می‌شوند. ستون صفر یا ثابت فاصلهٔ تمایز صفر دارد؛ وزن‌ها بازتوزیع نمی‌شوند. اگر همهٔ فاصله‌ها صفر شوند، نزدیکی تعریف نشده است و رتبهٔ ساختگی یا ۰٫۵ حدسی داده نمی‌شود. وزن‌ها نسبی، متناهی و نامنفی‌اند؛ حداقل یکی مثبت و تعدادشان برابر معیارهاست. با تقسیم مقیاس‌شده بر جمع به یک نرمال می‌شوند؛ وزن منفی/همه‌صفر رد می‌شود و وزن صفر سهمی ندارد. ماتریس سطری است و دقیقاً گزینه×معیار خانه می‌خواهد. رتبه‌های نزدیک در تلرانس نسبی ۱۰ به توان منفی ۱۰، بدون کف مطلق، هم‌رتبه‌اند؛ ترتیب ورودی صرفاً ترتیب نمایش تساوی است.';
  @override
  String get calculatorId => 'topsis';
  @override
  InputBinding<TopsisParameters> bind(CalculatorInput input) {
    final p = TopsisParameters(table: bindTable(input, withDirections: true));
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(TopsisParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return safelyDecide(() {
      final n = p.table.alternatives.toInt(),
          m = p.table.criteria.toInt(),
          w = normalizedWeights(p.table.weights),
          v = List.generate(n, (_) => List<double>.filled(m, 0)),
          constants = <double>[];
      for (var j = 0; j < m; j++) {
        final col = [for (var i = 0; i < n; i++) p.table.values[i * m + j]];
        if (col.every((x) => x == col.first)) constants.add(j + 1.0);
        if (w[j] == 0) continue;
        final scale = col.reduce(math.max);
        if (scale == 0) continue;
        final scaled = [
              for (final x in col) checked(x / scale, nonzero: x > 0),
            ],
            norm = vectorNorm(scaled);
        for (var i = 0; i < n; i++) {
          final r = checked(scaled[i] / norm, nonzero: col[i] > 0);
          v[i][j] = checked(r * w[j], nonzero: r > 0);
        }
      }
      final positive = <double>[], negative = <double>[];
      for (var j = 0; j < m; j++) {
        final col = [for (var i = 0; i < n; i++) v[i][j]],
            lo = col.reduce(math.min),
            hi = col.reduce(math.max);
        positive.add(p.table.directions[j] == 1 ? hi : lo);
        negative.add(p.table.directions[j] == 1 ? lo : hi);
      }
      final plus = <double>[], minus = <double>[], scores = <double>[];
      for (var i = 0; i < n; i++) {
        final dp = vectorNorm([
              for (var j = 0; j < m; j++) v[i][j] - positive[j],
            ]),
            dm = vectorNorm([
              for (var j = 0; j < m; j++) v[i][j] - negative[j],
            ]);
        if (dp + dm == 0) {
          throw DecisionMathError(
            'undefined_closeness',
            'فاصله از هر دو ایده‌آل صفر است؛ معیار فعالِ متمایزکننده نداریم و TOPSIS رتبهٔ تعریف‌شده‌ای نمی‌دهد.',
          );
        }
        plus.add(dp);
        minus.add(dm);
        scores.add(checked(dm / (dp + dm), nonzero: dm > 0));
      }
      return decisionResult(
        id: calculatorId,
        label: 'بیشترین ضریب نزدیکی TOPSIS',
        value: scores.reduce(math.max),
        basis: basis,
        details: [
          ...rankingMetrics(scores),
          seriesMetric('normalized_weights', 'وزن‌های نرمال‌شده', w),
          seriesMetric(
            'weighted_matrix',
            'ماتریس نرمال برداریِ وزن‌دار، سطری',
            v.expand((r) => r),
          ),
          seriesMetric(
            'positive_ideal',
            'ایده‌آل مثبت طبق نوع معیار',
            positive,
          ),
          seriesMetric('negative_ideal', 'ایده‌آل منفی', negative),
          seriesMetric('distance_plus', 'فاصله از ایده‌آل مثبت', plus),
          seriesMetric('distance_minus', 'فاصله از ایده‌آل منفی', minus),
        ],
        warnings: constantWarnings(constants),
      );
    });
  }

  List<CalculationIssue> _validate(TopsisParameters p) {
    final issues = validateTable(
      p.table,
      withDirections: true,
      nonnegative: true,
    );
    if (issues.isNotEmpty) return issues;
    return issues;
  }
}
