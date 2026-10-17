import '../calculator_domain.dart';
import '../statistics/tool_numeric.dart';

const hrCaution =
    'این شاخص توصیفی و وابسته به تعریف، کیفیت داده، بازهٔ زمانی و زمینه است؛ معیار قطعی عملکرد افراد یا سازمان، ابزار رتبه‌بندی افراد یا اثبات رابطهٔ علت و معلولی نیست. مقایسه فقط با تعریف و شرایط همسان معنادار است.';

final class HrNumber {
  const HrNumber(
    this.id,
    this.label,
    this.value, {
    this.positive = false,
    this.integer = false,
    this.max,
  });
  final String id, label;
  final double value;
  final bool positive, integer;
  final double? max;
}

List<CalculationIssue> validateHr(List<HrNumber> fields) => [
  for (final f in fields)
    if (!f.value.isFinite)
      CalculationIssue(
        code: 'non_finite',
        fieldId: f.id,
        message: '«${f.label}» باید عدد معتبر و متناهی باشد.',
      )
    else if (f.value < 0)
      CalculationIssue(
        code: 'negative_input',
        fieldId: f.id,
        message: '«${f.label}» نمی‌تواند منفی باشد.',
      )
    else if (f.positive && f.value == 0)
      CalculationIssue(
        code: 'positive_required',
        fieldId: f.id,
        message:
            '«${f.label}» باید بزرگ‌تر از صفر باشد؛ صفر در این ورودی محاسبه را تعریف نمی‌کند.',
      )
    else if (f.integer && f.value % 1 != 0)
      CalculationIssue(
        code: 'whole_count_required',
        fieldId: f.id,
        message: '«${f.label}» شمارش است و باید عدد صحیح باشد.',
      )
    else if (f.max != null && f.value > f.max!)
      CalculationIssue(
        code: 'above_hr_max',
        fieldId: f.id,
        message: '«${f.label}» از بازهٔ مجاز توضیح‌داده‌شده بیشتر است.',
      ),
];
CalculationOutcome hrResult({
  required String id,
  required String label,
  required double value,
  required String basis,
  required double periodDays,
  String? unit,
  bool percentage = false,
  bool nonzero = false,
  List<ResultMetric> details = const [],
}) {
  if (invalidNumeric(value, nonzero: nonzero)) return toolRange();
  return CalculationSuccess(
    CalculationResult(
      primary: metric(id, label, value, unit: unit, percentage: percentage),
      details: [
        metric(
          'period_days',
          'طول بازهٔ گزارش؛ بدون سالانه‌سازی خودکار',
          periodDays,
          unit: 'روز',
        ),
        ...details,
      ],
      interpretation: '$basis\n$hrCaution',
      warnings: [
        CalculationWarning(
          code: 'method_assumptions',
          severity: WarningSeverity.information,
          message: basis,
        ),
        CalculationWarning(code: 'descriptive_hr_only', message: hrCaution),
        if (value == 0)
          CalculationWarning(
            code: 'observed_zero',
            message: 'صفر نتیجهٔ ورودی‌های ثبت‌شده است؛ دادهٔ ناقص جایگزین صفر نشده و این عدد حکم قطعی دربارهٔ عملکرد نیست.',
          ),
      ],
    ),
  );
}
