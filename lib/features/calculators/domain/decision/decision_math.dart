import 'dart:math' as math;

import '../calculator_domain.dart';
import '../statistics/tool_numeric.dart';

const decisionCaution =
    'رتبه و ارزش، مشروط به داده، مقیاس، وزن و فرض‌های همین مدل‌اند؛ توصیهٔ قطعی، تضمین نتیجه یا جایگزین قضاوت انسانی، محدودیت‌های اجرایی و بررسی آثار کیفی/توزیعی نیستند. تغییر گزینه‌ها یا معیارها می‌تواند رتبه را عوض کند.';

final class DecisionMathError implements Exception {
  DecisionMathError([
    String code = 'numeric_range',
    String message = 'مقیاس داده اجازهٔ محاسبهٔ عددی قابل اتکا نمی‌دهد؛ بی‌نهایت یا صفر ساختگی نمایش داده نشد.',
  ]) : issue = CalculationIssue(code: code, message: message);
  final CalculationIssue issue;
}

double checked(double x, {bool nonzero = false}) {
  if (!x.isFinite || (nonzero && x == 0)) throw DecisionMathError();
  return x;
}

CalculationOutcome safelyDecide(CalculationOutcome Function() body) {
  try {
    return body();
  } on DecisionMathError catch (e) {
    return CalculationFailure([e.issue]);
  }
}

CalculationIssue decisionIssue(String code, String message, String fieldId) =>
    CalculationIssue(code: code, message: message, fieldId: fieldId);
List<CalculationIssue> decisionNumbers(List<ToolNumber> fields) =>
    toolValidate(fields);
List<double> normalizedWeights(List<double> values) {
  final scale = values.reduce(math.max);
  final scaled = [for (final x in values) checked(x / scale, nonzero: x > 0)];
  final sum = compensatedSum(scaled);
  return [
    for (var i = 0; i < scaled.length; i++)
      checked(scaled[i] / sum, nonzero: values[i] > 0),
  ];
}

/// Convex combination of signed finite observations, with cancellation protection.
double weightedValue(List<double> values, List<double> weights) {
  final scale = [
    for (var i = 0; i < values.length; i++)
      if (weights[i] > 0) values[i].abs(),
  ].reduce(math.max);
  if (scale == 0) return 0;
  final terms = <double>[];
  for (var i = 0; i < values.length; i++) {
    if (weights[i] == 0) {
      terms.add(0);
      continue;
    }
    final ratio = checked(values[i] / scale, nonzero: values[i] != 0);
    terms.add(checked(ratio * weights[i], nonzero: ratio != 0));
  }
  final sum = compensatedSum(terms);
  return checked(sum * scale, nonzero: sum != 0);
}

double vectorNorm(List<double> values) {
  final scale = values.map((v) => v.abs()).reduce(math.max);
  if (scale == 0) return 0;
  return checked(
    scale *
        math.sqrt(
          compensatedSum(
            values.map((v) {
              final r = v / scale;
              return r * r;
            }),
          ),
        ),
    nonzero: true,
  );
}

const relativeRankTolerance = 1e-10;
bool nearScore(double a, double b) =>
    a == b ||
    (a - b).abs() <= relativeRankTolerance * math.max(a.abs(), b.abs());
List<List<int>> rankGroups(List<double> scores) {
  final sorted = List<int>.generate(scores.length, (i) => i)
    ..sort((a, b) {
      final c = scores[b].compareTo(scores[a]);
      return c == 0 ? a.compareTo(b) : c;
    });
  final groups = <List<int>>[];
  var start = 0;
  while (start < sorted.length) {
    var end = start + 1;
    while (end < sorted.length &&
        nearScore(scores[sorted[start]], scores[sorted[end]])) {
      end++;
    }
    groups.add(sorted.sublist(start, end)..sort());
    start = end;
  }
  return groups;
}

List<int> descendingOrder(List<double> scores) =>
    rankGroups(scores).expand((g) => g).toList();
List<double> competitionRanks(List<double> scores) {
  final ranks = List<double>.filled(scores.length, 0);
  var rank = 1;
  for (final group in rankGroups(scores)) {
    for (final id in group) {
      ranks[id] = rank.toDouble();
    }
    rank += group.length;
  }
  return ranks;
}

List<ResultMetric> rankingMetrics(List<double> scores) => [
  seriesMetric('scores', 'امتیازها به ترتیب گزینه‌های ورودی', scores),
  seriesMetric(
    'ranks',
    'رتبهٔ رقابتی؛ هم‌رتبگی در تلرانس نسبی اعلام‌شده',
    competitionRanks(scores),
  ),
  seriesMetric(
    'ordered_options',
    'ترتیب نمایش گزینه‌های یک‌مبنا؛ هم‌رتبه‌ها با ترتیب ورودی',
    descendingOrder(scores).map((i) => i + 1.0),
  ),
  seriesMetric(
    'top_options',
    'گزینه‌های بالاترین گروه امتیاز در این مدل و تلرانس',
    rankGroups(scores).first.map((i) => i + 1.0),
  ),
  metric(
    'relative_rank_tolerance',
    'تلرانس نسبی هم‌رتبگی، بدون کف مطلق',
    relativeRankTolerance,
  ),
];
CalculationOutcome decisionResult({
  required String id,
  required String label,
  required double value,
  required String basis,
  String? unit,
  List<ResultMetric> details = const [],
  List<CalculationWarning> warnings = const [],
}) {
  checked(value);
  return CalculationSuccess(
    CalculationResult(
      primary: metric(id, label, value, unit: unit),
      details: details,
      interpretation: '$basis\n$decisionCaution',
      warnings: [
        CalculationWarning(
          code: 'method_assumptions',
          severity: WarningSeverity.information,
          message: basis,
        ),
        CalculationWarning(
          code: 'conditional_decision',
          message: decisionCaution,
        ),
        ...warnings,
      ],
    ),
  );
}
