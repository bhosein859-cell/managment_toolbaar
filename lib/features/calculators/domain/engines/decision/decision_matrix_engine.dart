import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../decision/decision_math.dart';
import '../../decision/decision_table.dart';
import '../../statistics/tool_numeric.dart';

final class DecisionMatrixParameters implements CalculatorParameters {
  const DecisionMatrixParameters({required this.table});
  final DecisionTable table;
}

final class DecisionMatrixEngine
    implements CalculatorEngine<DecisionMatrixParameters> {
  const DecisionMatrixEngine();
  static const basis =
      'روش SAW با min-max: برای معیار منفعت (x−min)/(max−min) و برای هزینه (max−x)/(max−min)؛ سپس جمع وزن‌دار مطلوبیت‌های صفر تا یک. دادهٔ امتیازی منفی نیز مجاز است. ستون ثابت مطلوبیت صفر برای همه دارد؛ وزن آن خودکار بازتوزیع نمی‌شود. اگر همهٔ معیارها ثابت باشند، امتیازها صفر و هم‌رتبه‌اند، نه انتخاب برتر. وزن‌ها نسبی، متناهی و نامنفی‌اند؛ حداقل یکی مثبت و تعدادشان برابر معیارهاست. با تقسیم مقیاس‌شده بر جمع به یک نرمال می‌شوند؛ وزن منفی/همه‌صفر رد می‌شود و وزن صفر سهمی ندارد. ماتریس سطری است و دقیقاً گزینه×معیار خانه می‌خواهد. رتبه‌های نزدیک در تلرانس نسبی ۱۰ به توان منفی ۱۰، بدون کف مطلق، هم‌رتبه‌اند؛ ترتیب ورودی صرفاً ترتیب نمایش تساوی است.';
  @override
  String get calculatorId => 'decision_matrix';
  @override
  InputBinding<DecisionMatrixParameters> bind(CalculatorInput input) {
    final p = DecisionMatrixParameters(
      table: bindTable(input, withDirections: true),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(DecisionMatrixParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return safelyDecide(() {
      final t = minMaxTable(p.table), scores = scoreRows(t.rows, t.weights);
      return decisionResult(
        id: calculatorId,
        label: 'بیشترین امتیاز مدل min-max',
        value: scores.reduce(math.max),
        basis: basis,
        details: [
          ...rankingMetrics(scores),
          seriesMetric('normalized_weights', 'وزن‌های نرمال‌شده', t.weights),
          seriesMetric(
            'normalized_matrix',
            'ماتریس مطلوبیت سطری min-max',
            t.rows.expand((r) => r),
          ),
          if (t.constantColumns.isNotEmpty)
            seriesMetric(
              'constant_columns',
              'شمارهٔ معیارهای ثابت',
              t.constantColumns,
            ),
        ],
        warnings: constantWarnings(t.constantColumns),
      );
    });
  }

  List<CalculationIssue> _validate(DecisionMatrixParameters p) {
    final issues = validateTable(
      p.table,
      withDirections: true,
      nonnegative: false,
    );
    if (issues.isNotEmpty) return issues;
    return issues;
  }
}
