import '../calculator_domain.dart';

final class OeeParameters implements CalculatorParameters {
  const OeeParameters({
    required this.availability,
    required this.performance,
    required this.quality,
  });
  final double availability;
  final double performance;
  final double quality;
}

final class OeeEngine implements CalculatorEngine<OeeParameters> {
  const OeeEngine();
  @override
  String get calculatorId => 'oee';

  @override
  InputBinding<OeeParameters> bind(CalculatorInput input) {
    final parameters = OeeParameters(
      availability: input.requireNumber('availability'),
      performance: input.requireNumber('performance'),
      quality: input.requireNumber('quality'),
    );
    final issues = _validate(parameters);
    return issues.isEmpty ? BoundInput(parameters) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(OeeParameters parameters) {
    final issues = _validate(parameters);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value =
        parameters.availability * parameters.performance * parameters.quality;
    if (value == 0 &&
        parameters.availability > 0 &&
        parameters.performance > 0 &&
        parameters.quality > 0) {
      return CalculationFailure([
        CalculationIssue(
          code: 'numeric_range',
          message: 'حاصل‌ضرب مؤلفه‌ها از حد دقت عددی کوچک‌تر است؛ نتیجهٔ صفرِ قابل اتکا تولید نشد.',
        ),
      ]);
    }
    return CalculationSuccess(
      CalculationResult(
        primary: ResultMetric(
          id: 'oee',
          label: 'اثربخشی کلی تجهیزات (OEE)',
          value: NumericResultValue(value, display: NumberDisplay.percentage),
        ),
        details: [
          ResultMetric(
            id: 'availability',
            label: 'دسترس‌پذیری (Availability)',
            value: NumericResultValue(
              parameters.availability,
              display: NumberDisplay.percentage,
            ),
          ),
          ResultMetric(
            id: 'performance',
            label: 'عملکرد (Performance)',
            value: NumericResultValue(
              parameters.performance,
              display: NumberDisplay.percentage,
            ),
          ),
          ResultMetric(
            id: 'quality',
            label: 'کیفیت (Quality)',
            value: NumericResultValue(
              parameters.quality,
              display: NumberDisplay.percentage,
            ),
          ),
          ResultMetric(
            id: 'ratio',
            label: 'نسبت OEE بدون تبدیل به درصد',
            value: NumericResultValue(value),
          ),
        ],
        warnings: [
          CalculationWarning(
            code: 'consistent_period',
            severity: WarningSeverity.information,
            message: 'سه مؤلفه باید برای یک تجهیز و یک بازهٔ زمانی یکسان و با تعریف سازگار محاسبه شده باشند.',
          ),
        ],
        interpretation: 'OEE حاصل‌ضرب سه نسبت است. در این ابزار برچسب خوب یا بد و آستانهٔ قطعی برای مقایسهٔ سازمان‌ها اعمال نمی‌شود.',
      ),
    );
  }

  List<CalculationIssue> _validate(OeeParameters parameters) {
    final issues = <CalculationIssue>[];
    final values = {
      'availability': parameters.availability,
      'performance': parameters.performance,
      'quality': parameters.quality,
    };
    final labels = {
      'availability': 'دسترس‌پذیری',
      'performance': 'عملکرد',
      'quality': 'کیفیت',
    };
    for (final entry in values.entries) {
      if (!entry.value.isFinite || entry.value < 0 || entry.value > 1) {
        issues.add(
          CalculationIssue(
            code: 'invalid_ratio',
            fieldId: entry.key,
            message:
                'نسبت «${labels[entry.key]}» باید عدد متناهی بین صفر و یک باشد.',
          ),
        );
      }
    }
    return issues;
  }
}
