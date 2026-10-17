import 'dart:math' as math;

import '../calculator_domain.dart';

final class ToolNumber {
  const ToolNumber(
    this.id,
    this.label,
    this.value, {
    this.min,
    this.max,
    this.strictMin = false,
    this.strictMax = false,
    this.integer = false,
  });
  final String id, label;
  final double value;
  final double? min, max;
  final bool strictMin, strictMax, integer;
}

List<CalculationIssue> toolValidate(List<ToolNumber> fields) => [
  for (final f in fields)
    if (!f.value.isFinite ||
        (f.min != null &&
            (f.strictMin ? f.value <= f.min! : f.value < f.min!)) ||
        (f.max != null &&
            (f.strictMax ? f.value >= f.max! : f.value > f.max!)) ||
        (f.integer && (f.value % 1 != 0 || f.value.abs() > 9007199254740991)))
      CalculationIssue(
        code: 'invalid_number',
        fieldId: f.id,
        message:
            '«${f.label}» باید متناهی و مطابق بازه و نوع توضیح‌داده‌شده باشد.',
      ),
];
CalculationFailure toolFailure(
  String code,
  String message, {
  String? fieldId,
}) => CalculationFailure([
  CalculationIssue(code: code, message: message, fieldId: fieldId),
]);
CalculationFailure toolRange() => toolFailure(
  'numeric_range',
  'برای این مقیاس نتیجهٔ قابل اتکا در محدودهٔ عددی تولید نشد؛ صفر یا بی‌نهایت ساختگی نمایش داده نمی‌شود.',
);
bool invalidNumeric(double x, {bool nonzero = false}) =>
    !x.isFinite || (nonzero && x == 0);
ResultMetric metric(
  String id,
  String label,
  double value, {
  String? unit,
  bool percentage = false,
}) => ResultMetric(
  id: id,
  label: label,
  value: NumericResultValue(
    value,
    unit: unit,
    display: percentage ? NumberDisplay.percentage : NumberDisplay.decimal,
  ),
);
ResultMetric textMetric(String id, String label, String value) =>
    ResultMetric(id: id, label: label, value: TextResultValue(value));
ResultMetric seriesMetric(
  String id,
  String label,
  Iterable<double> values, {
  String? unit,
}) => ResultMetric(
  id: id,
  label: label,
  value: NumberListResultValue(values, unit: unit),
);
CalculationOutcome toolResult({
  required String id,
  required String label,
  required double value,
  required String basis,
  String? unit,
  bool nonzero = false,
  List<ResultMetric> details = const [],
  List<CalculationWarning> warnings = const [],
}) {
  if (invalidNumeric(value, nonzero: nonzero)) return toolRange();
  return CalculationSuccess(
    CalculationResult(
      primary: metric(id, label, value, unit: unit),
      details: details,
      warnings: [
        CalculationWarning(
          code: 'method_assumptions',
          severity: WarningSeverity.information,
          message: basis,
        ),
        ...warnings,
      ],
      interpretation: basis,
    ),
  );
}

double scaledMean(List<double> values) {
  final scale = values.map((x) => x.abs()).reduce(math.max);
  if (scale == 0) return 0;
  final normalized = values.map((v) => v / scale).toList();
  for (var i = 0; i < values.length; i++) {
    if (values[i] != 0 && normalized[i] == 0) return double.nan;
  }
  final sum = compensatedSum(normalized), mean = sum / values.length;
  if (sum != 0 && mean == 0) return double.nan;
  final result = mean * scale;
  return result == 0 && mean != 0 ? double.nan : result;
}

double compensatedSum(Iterable<double> values) {
  var sum = 0.0, c = 0.0;
  for (final v in values) {
    final next = sum + v;
    c += sum.abs() >= v.abs() ? (sum - next) + v : (v - next) + sum;
    sum = next;
  }
  return sum + c;
}

/// Difference over k*sigma, without constructing an overflowing denominator.
double differenceRatio(double a, double b, double sigma, double k) {
  final diff = a - b;
  if (!diff.isFinite) return (a / k - b / k) / sigma;
  final ratio = diff / sigma;
  return ratio.isFinite ? ratio / k : (diff / k) / sigma;
}

double positiveFromLog(double logValue) => math.exp(logValue);
double stableHypot(double a, double b) {
  final scale = math.max(a.abs(), b.abs());
  if (scale == 0) return 0;
  return scale *
      math.sqrt((a / scale) * (a / scale) + (b / scale) * (b / scale));
}
