import '../../calculator_domain.dart';

/// Shared numeric guards only; each production tool owns its typed formula.
final class ProductionNumber {
  const ProductionNumber(
    this.id,
    this.label,
    this.value, {
    this.positive = false,
    this.integer = false,
  });
  final String id;
  final String label;
  final double value;
  final bool positive;
  final bool integer;
}

List<CalculationIssue> validateProductionNumbers(
  List<ProductionNumber> fields,
) => [
  for (final field in fields)
    if (!field.value.isFinite ||
        field.value < 0 ||
        (field.positive && field.value == 0))
      CalculationIssue(
        code: 'invalid_number',
        fieldId: field.id,
        message:
            '«${field.label}» باید عدد متناهی ${field.positive ? 'بزرگ‌تر از صفر' : 'نامنفی'} باشد.',
      )
    else if (field.integer &&
        (field.value % 1 != 0 || field.value > 9007199254740991))
      CalculationIssue(
        code: 'invalid_integer',
        fieldId: field.id,
        message:
            '«${field.label}» باید عدد صحیح قابل نمایش دقیق و حداکثر ۹۰۰۷۱۹۹۲۵۴۷۴۰۹۹۱ باشد.',
      ),
];

CalculationOutcome productionResult({
  required String id,
  required String label,
  required double value,
  required bool nonzeroExpected,
  required String interpretation,
  String? unit,
  bool percentage = false,
  List<ResultMetric> details = const [],
  List<CalculationWarning> warnings = const [],
}) {
  if (!value.isFinite ||
      (nonzeroExpected && value == 0) ||
      (percentage && !(value * 100).isFinite)) {
    return CalculationFailure([
      CalculationIssue(
        code: 'numeric_range',
        message: 'نتیجه خارج از محدودهٔ امن عددی است؛ مقیاس ورودی‌ها را بررسی کنید. صفر یا بی‌نهایت ساختگی نمایش داده نشد.',
      ),
    ]);
  }
  return CalculationSuccess(
    CalculationResult(
      primary: ResultMetric(
        id: id,
        label: label,
        value: NumericResultValue(
          value,
          unit: unit,
          display: percentage
              ? NumberDisplay.percentage
              : NumberDisplay.decimal,
        ),
      ),
      details: details,
      warnings: [
        CalculationWarning(
          code: 'calculation_basis',
          severity: WarningSeverity.information,
          message: interpretation,
        ),
        ...warnings,
      ],
      interpretation: interpretation,
    ),
  );
}
