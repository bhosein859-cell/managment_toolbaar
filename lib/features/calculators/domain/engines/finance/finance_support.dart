import 'dart:math' as math;

import '../../calculator_domain.dart';

final class FinanceField {
  const FinanceField(
    this.id,
    this.label,
    this.value, {
    this.min,
    this.max,
    this.exclusiveMin = false,
    this.integer = false,
  });
  final String id, label;
  final double value;
  final double? min, max;
  final bool exclusiveMin, integer;
}

List<CalculationIssue> validateFinance(List<FinanceField> fields) => [
  for (final f in fields)
    if (!f.value.isFinite ||
        (f.min != null &&
            (f.exclusiveMin ? f.value <= f.min! : f.value < f.min!)) ||
        (f.max != null && f.value > f.max!) ||
        (f.integer && (f.value % 1 != 0 || f.value.abs() > 9007199254740991)))
      CalculationIssue(
        code: 'invalid_number',
        fieldId: f.id,
        message:
            '«${f.label}» باید متناهی و در محدودهٔ توضیح‌داده‌شده باشد${f.integer ? ' و مقدار صحیح داشته باشد' : ''}.',
      ),
];
CalculationFailure financeFailure(
  String code,
  String message, {
  String? fieldId,
}) => CalculationFailure([
  CalculationIssue(code: code, message: message, fieldId: fieldId),
]);
CalculationFailure financeRange() => financeFailure(
  'numeric_range',
  'این ترکیب ورودی از محدودهٔ امن دقت عددی خارج است؛ نتیجهٔ صفر یا بی‌نهایت ساختگی تولید نشد. مقیاس و نرخ/دوره‌ها را بازبینی کنید.',
);
bool lostNonzero(double value, bool expected) =>
    !value.isFinite || (expected && value == 0);
ResultMetric financeMetric(
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
CalculationOutcome financeResult({
  required String id,
  required String label,
  required double value,
  required String basis,
  String? unit,
  bool percentage = false,
  bool nonzeroExpected = false,
  List<ResultMetric> details = const [],
  List<CalculationWarning> warnings = const [],
}) {
  if (lostNonzero(value, nonzeroExpected) ||
      (percentage && !(value * 100).isFinite)) {
    return financeRange();
  }
  return CalculationSuccess(
    CalculationResult(
      primary: financeMetric(
        id,
        label,
        value,
        unit: unit,
        percentage: percentage,
      ),
      details: details,
      warnings: [
        CalculationWarning(
          code: 'financial_basis',
          severity: WarningSeverity.information,
          message: basis,
        ),
        ...warnings,
        CalculationWarning(
          code: 'not_investment_advice',
          severity: WarningSeverity.information,
          message: 'نتیجه صرفاً محاسبهٔ آموزشی با فرض‌های واردشده است، نه توصیهٔ سرمایه‌گذاری شخصی یا پیشنهاد خرید، فروش یا اخذ وام.',
        ),
      ],
      interpretation: basis,
    ),
  );
}

/// Stable near zero; avoids cancellation in log(1+x) and exp(x)-1.
double financeLog1p(double x) {
  if (x.abs() >= 0.0001) return math.log(1 + x);
  var term = x, sum = x;
  for (var k = 2; k <= 20; k++) {
    term *= -x;
    sum += term / k;
  }
  return sum;
}

double financeExpm1(double x) {
  if (x.abs() >= 0.0001) return math.exp(x) - 1;
  var term = x, sum = x;
  for (var k = 2; k <= 20; k++) {
    term *= x / k;
    sum += term;
  }
  return sum;
}
