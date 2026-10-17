import 'dart:math' as math;

import '../calculator_domain.dart';
import '../statistics/tool_numeric.dart';
import 'decision_math.dart';

final class DecisionTable {
  DecisionTable({
    required this.alternatives,
    required this.criteria,
    required Iterable<double> values,
    required Iterable<double> weights,
    Iterable<double> directions = const [],
  }) : values = List.unmodifiable(values),
       weights = List.unmodifiable(weights),
       directions = List.unmodifiable(directions);
  final double alternatives, criteria;
  final List<double> values, weights, directions;
}

DecisionTable bindTable(CalculatorInput input, {bool withDirections = true}) =>
    DecisionTable(
      alternatives: input.requireNumber('alternatives'),
      criteria: input.requireNumber('criteria'),
      values: input.requireNumberList('matrix'),
      weights: input.requireNumberList('weights'),
      directions: withDirections ? input.requireNumberList('directions') : [],
    );
List<CalculationIssue> validateTable(
  DecisionTable p, {
  bool withDirections = true,
  bool nonnegative = false,
}) {
  final issues = decisionNumbers([
    ToolNumber(
      'alternatives',
      'تعداد گزینه',
      p.alternatives,
      min: 2,
      max: 20,
      integer: true,
    ),
    ToolNumber(
      'criteria',
      'تعداد معیار',
      p.criteria,
      min: 1,
      max: 20,
      integer: true,
    ),
  ]);
  if (issues.isNotEmpty) return issues;
  final n = p.alternatives.toInt(), m = p.criteria.toInt();
  if (p.values.length != n * m) {
    issues.add(
      decisionIssue(
        'matrix_shape',
        'تعداد خانه‌های ماتریس باید دقیقاً تعداد گزینه × تعداد معیار باشد؛ ترتیب سطری است.',
        'matrix',
      ),
    );
  }
  if (p.weights.length != m) {
    issues.add(
      decisionIssue(
        'weight_shape',
        'تعداد وزن‌ها باید دقیقاً برابر تعداد معیار باشد.',
        'weights',
      ),
    );
  }
  if (withDirections && p.directions.length != m) {
    issues.add(
      decisionIssue(
        'direction_shape',
        'برای هر معیار یک نوع ۱ منفعت یا منفی ۱ هزینه لازم است.',
        'directions',
      ),
    );
  }
  if (p.values.any((v) => !v.isFinite || (nonnegative && v < 0))) {
    issues.add(
      decisionIssue(
        'invalid_matrix_value',
        nonnegative
            ? 'TOPSIS این فرم دادهٔ متناهی و نامنفی می‌خواهد؛ مقیاس/دادهٔ منفی را بدون تعریف تبدیل وارد نکنید.'
            : 'همهٔ خانه‌های ماتریس باید عدد متناهی باشند.',
        'matrix',
      ),
    );
  }
  if (p.weights.any((v) => !v.isFinite || v < 0) ||
      !p.weights.any((v) => v > 0)) {
    issues.add(
      decisionIssue(
        'invalid_weights',
        'وزن‌ها باید متناهی و نامنفی، و حداقل یکی مثبت باشد؛ وزن منفی یا همه‌صفر معتبر نیست.',
        'weights',
      ),
    );
  }
  if (withDirections && p.directions.any((v) => v != 1 && v != -1)) {
    issues.add(
      decisionIssue(
        'invalid_direction',
        'نوع هر معیار فقط ۱ برای منفعت یا منفی ۱ برای هزینه است.',
        'directions',
      ),
    );
  }
  return issues;
}

final class NormalizedTable {
  NormalizedTable(this.rows, this.weights, this.constantColumns);
  final List<List<double>> rows;
  final List<double> weights;
  final List<double> constantColumns;
}

NormalizedTable minMaxTable(DecisionTable p) {
  final n = p.alternatives.toInt(), m = p.criteria.toInt();
  final rows = List.generate(n, (_) => List<double>.filled(m, 0)),
      constants = <double>[];
  for (var j = 0; j < m; j++) {
    final col = [for (var i = 0; i < n; i++) p.values[i * m + j]],
        lo = col.reduce(math.min),
        hi = col.reduce(math.max);
    if (lo == hi) {
      constants.add(j + 1.0);
      continue;
    }
    final scale = col.map((x) => x.abs()).reduce(math.max),
        scaled = [for (final v in col) checked(v / scale, nonzero: v != 0)];
    final min = scaled.reduce(math.min),
        max = scaled.reduce(math.max),
        width = max - min;
    for (var i = 0; i < n; i++) {
      final diff = p.directions[j] == 1 ? scaled[i] - min : max - scaled[i];
      final exactZero = p.directions[j] == 1 ? col[i] == lo : col[i] == hi;
      rows[i][j] = checked(diff / width, nonzero: !exactZero);
    }
  }
  return NormalizedTable(rows, normalizedWeights(p.weights), constants);
}

List<double> scoreRows(List<List<double>> rows, List<double> weights) => [
  for (final row in rows) weightedValue(row, weights),
];
List<CalculationWarning> constantWarnings(List<double> columns) =>
    columns.isEmpty
    ? []
    : [
        CalculationWarning(
          code: 'constant_criteria',
          message: 'معیار ثابت اطلاعات تمایز ندارد؛ در min-max سهم آن صفر و در TOPSIS فاصلهٔ آن صفر است. وزن‌ها خودکار بین معیارهای دیگر بازتوزیع نمی‌شوند. اگر همهٔ امتیازها یکسان‌اند، مدل ترجیح متمایز نمی‌دهد.',
        ),
      ];
