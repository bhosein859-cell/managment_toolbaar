import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../decision/decision_math.dart';
import '../../decision/decision_table.dart';
import '../../statistics/tool_numeric.dart';

final class WeightSensitivityParameters implements CalculatorParameters {
  WeightSensitivityParameters({
    required this.table,
    required this.selectedCriterion,
    required Iterable<double> sweepWeights,
  }) : sweepWeights = List.unmodifiable(sweepWeights);
  final DecisionTable table;
  final double selectedCriterion;
  final List<double> sweepWeights;
}

final class WeightSensitivityEngine
    implements CalculatorEngine<WeightSensitivityParameters> {
  const WeightSensitivityEngine();
  static const basis =
      'تحلیل سناریویی یک‌عامل‌درهر‌بار روی مدل SAW/min-max است، نه تحلیل حساسیت همهٔ الگوریتم‌ها یا آستانه‌یابی پیوسته. داده و نوع معیار ثابت‌اند؛ وزن یک معیار با مقادیر صریح صفر تا یک جایگزین می‌شود و سهم باقی‌مانده به نسبت وزن اولیهٔ سایر معیارها توزیع می‌شود. حداقل یک معیار دیگر باید وزن مثبت داشته باشد؛ در غیر این صورت نسبت بازتوزیع تعریف نمی‌شود. همهٔ برندگان/هم‌رتبه‌های نمونه‌ها گزارش می‌شوند. ثبات در این نقاط نمونه اثبات پایداری بین نقاط یا در برابر تغییر همزمان چند وزن/داده نیست. وزن‌ها نسبی، متناهی و نامنفی‌اند؛ حداقل یکی مثبت و تعدادشان برابر معیارهاست. با تقسیم مقیاس‌شده بر جمع به یک نرمال می‌شوند؛ وزن منفی/همه‌صفر رد می‌شود و وزن صفر سهمی ندارد. ماتریس سطری است و دقیقاً گزینه×معیار خانه می‌خواهد. رتبه‌های نزدیک در تلرانس نسبی ۱۰ به توان منفی ۱۰، بدون کف مطلق، هم‌رتبه‌اند؛ ترتیب ورودی صرفاً ترتیب نمایش تساوی است.';
  @override
  String get calculatorId => 'weight_sensitivity';
  @override
  InputBinding<WeightSensitivityParameters> bind(CalculatorInput input) {
    final p = WeightSensitivityParameters(
      table: bindTable(input, withDirections: true),
      selectedCriterion: input.requireNumber('selected_criterion'),
      sweepWeights: List.unmodifiable(input.requireNumberList('sweep_weights')),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(WeightSensitivityParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return safelyDecide(() {
      final t = minMaxTable(p.table),
          baseScores = scoreRows(t.rows, t.weights),
          selected = p.selectedCriterion.toInt() - 1;
      final other = normalizedWeights([
        for (var j = 0; j < t.weights.length; j++)
          if (j != selected) p.table.weights[j],
      ]);
      final details = <ResultMetric>[
        ...rankingMetrics(baseScores),
        seriesMetric('baseline_weights', 'وزن پایهٔ نرمال‌شده', t.weights),
      ];
      for (var k = 0; k < p.sweepWeights.length; k++) {
        final target = p.sweepWeights[k];
        var index = 0;
        final weights = <double>[];
        for (var j = 0; j < t.weights.length; j++) {
          if (j == selected) {
            weights.add(target);
          } else {
            final original = other[index++];
            weights.add(
              checked(
                (1 - target) * original,
                nonzero: target < 1 && original > 0,
              ),
            );
          }
        }
        final scores = scoreRows(t.rows, weights);
        details.addAll([
          metric('scenario_${k + 1}_weight', 'وزن منتخب این سناریو', target),
          seriesMetric(
            'scenario_${k + 1}_scores',
            'امتیازهای سناریو به ترتیب گزینه‌ها',
            scores,
          ),
          seriesMetric(
            'scenario_${k + 1}_top',
            'تمام گزینه‌های بالاترین گروه این سناریو',
            rankGroups(scores).first.map((i) => i + 1.0),
          ),
        ]);
      }
      return decisionResult(
        id: calculatorId,
        label: 'بیشترین امتیاز در وزن‌های پایه، نه تضمین پایداری',
        value: baseScores.reduce(math.max),
        basis: basis,
        details: details,
        warnings: constantWarnings(t.constantColumns),
      );
    });
  }

  List<CalculationIssue> _validate(WeightSensitivityParameters p) {
    final issues = validateTable(
      p.table,
      withDirections: true,
      nonnegative: false,
    );
    if (issues.isNotEmpty) return issues;
    issues.addAll(
      toolValidate([
        ToolNumber(
          'selected_criterion',
          'شمارهٔ معیار',
          p.selectedCriterion,
          min: 1,
          max: p.table.criteria,
          integer: true,
        ),
      ]),
    );
    if (issues.isNotEmpty) return issues;
    if (p.sweepWeights.isEmpty ||
        p.sweepWeights.length > 21 ||
        p.sweepWeights.any((v) => !v.isFinite || v < 0 || v > 1)) {
      issues.add(
        decisionIssue(
          'invalid_sweep',
          '۱ تا ۲۱ وزن سناریو، هرکدام کسر متناهی بین صفر و یک لازم است.',
          'sweep_weights',
        ),
      );
    }
    final index = p.selectedCriterion.toInt() - 1;
    if (![
      for (var j = 0; j < p.table.weights.length; j++)
        if (j != index) p.table.weights[j],
    ].any((v) => v > 0)) {
      issues.add(
        decisionIssue(
          'undefined_redistribution',
          'حداقل یکی از سایر معیارها باید وزن مثبت داشته باشد تا نسبت بازتوزیع تعریف شود.',
          'weights',
        ),
      );
    }
    return issues;
  }
}
