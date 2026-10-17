import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../decision/decision_math.dart';
import '../../decision/decision_table.dart';
import '../../statistics/tool_numeric.dart';

final class WeightedScoringParameters implements CalculatorParameters {
  const WeightedScoringParameters({required this.table});
  final DecisionTable table;
}

final class WeightedScoringEngine
    implements CalculatorEngine<WeightedScoringParameters> {
  const WeightedScoringEngine();
  static const basis =
      'فقط وزن‌ها به جمع یک نرمال می‌شوند؛ خود امتیازهای ماتریس بدون min-max یا نرمال برداری وارد جمع وزن‌دار می‌شوند. تمام امتیازها باید از پیش روی مقیاس کاردینال مشترک با جهت بیشتر=بهتر باشند؛ عدد منفی مجاز است. هزینهٔ خام یا ترکیب ریال/روز/کیفیت را بدون تبدیل مطلوبیت وارد نکنید. مدل جبرانی و جمع‌پذیر است؛ مزیت یک معیار می‌تواند ضعف دیگری را جبران کند. وزن‌ها نسبی، متناهی و نامنفی‌اند؛ حداقل یکی مثبت و تعدادشان برابر معیارهاست. با تقسیم مقیاس‌شده بر جمع به یک نرمال می‌شوند؛ وزن منفی/همه‌صفر رد می‌شود و وزن صفر سهمی ندارد. ماتریس سطری است و دقیقاً گزینه×معیار خانه می‌خواهد. رتبه‌های نزدیک در تلرانس نسبی ۱۰ به توان منفی ۱۰، بدون کف مطلق، هم‌رتبه‌اند؛ ترتیب ورودی صرفاً ترتیب نمایش تساوی است.';
  @override
  String get calculatorId => 'weighted_scoring';
  @override
  InputBinding<WeightedScoringParameters> bind(CalculatorInput input) {
    final p = WeightedScoringParameters(
      table: bindTable(input, withDirections: false),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(WeightedScoringParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return safelyDecide(() {
      final n = p.table.alternatives.toInt(),
          m = p.table.criteria.toInt(),
          w = normalizedWeights(p.table.weights),
          scores = [
            for (var i = 0; i < n; i++)
              weightedValue(p.table.values.sublist(i * m, (i + 1) * m), w),
          ];
      return decisionResult(
        id: calculatorId,
        label: 'بیشترین امتیاز وزن‌دار روی مقیاس ورودی',
        value: scores.reduce(math.max),
        basis: basis,
        details: [
          ...rankingMetrics(scores),
          seriesMetric(
            'normalized_weights',
            'وزن‌های نرمال‌شده؛ امتیازها تبدیل نشده‌اند',
            w,
          ),
        ],
      );
    });
  }

  List<CalculationIssue> _validate(WeightedScoringParameters p) {
    final issues = validateTable(
      p.table,
      withDirections: false,
      nonnegative: false,
    );
    if (issues.isNotEmpty) return issues;
    return issues;
  }
}
