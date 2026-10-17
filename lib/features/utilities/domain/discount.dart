import '../../calculators/domain/calculator_domain.dart';
import '../../calculators/domain/statistics/tool_numeric.dart';

final class DiscountParameters implements CalculatorParameters {
  const DiscountParameters({required this.price, required this.rate});
  final double price, rate;
}

final class DiscountEngine implements CalculatorEngine<DiscountParameters> {
  const DiscountEngine();
  static const basis =
      'قیمت نامنفی بر حسب ریال و تخفیف از صفر تا ۱۰۰٪ است. فقط یک تخفیف محاسبه می‌شود؛ مالیات، کارمزد و تخفیف‌های متوالی لحاظ نمی‌شوند.';
  @override
  String get calculatorId => 'discount';
  @override
  InputBinding<DiscountParameters> bind(CalculatorInput input) {
    final p = DiscountParameters(
      price: input.requireNumber('price'),
      rate: input.requireNumber('rate'),
    );
    final errors = _validate(p);
    return errors.isEmpty ? BoundInput(p) : RejectedInput(errors);
  }

  List<CalculationIssue> _validate(DiscountParameters p) => toolValidate([
    ToolNumber('price', 'قیمت اصلی', p.price, min: 0),
    ToolNumber('rate', 'درصد تخفیف', p.rate, min: 0, max: 1),
  ]);
  @override
  CalculationOutcome calculate(DiscountParameters p) {
    final errors = _validate(p);
    if (errors.isNotEmpty) return CalculationFailure(errors);
    final value = p.price * (1 - p.rate);
    final details = <ResultMetric>[
      metric('original', 'قیمت پیش از تخفیف', p.price, unit: 'ریال'),
      metric('saving', 'مبلغ تخفیف', p.price * p.rate, unit: 'ریال'),
      metric('rate', 'درصد تخفیف', p.rate, percentage: true),
    ];
    if (invalidNumeric(p.price * p.rate, nonzero: p.price > 0 && p.rate > 0) ||
        invalidNumeric(value, nonzero: p.price > 0 && p.rate < 1) ||
        details.any(
          (m) =>
              m.value is NumericResultValue &&
              !((m.value as NumericResultValue).value.isFinite),
        )) {
      return toolRange();
    }
    return CalculationSuccess(
      CalculationResult(
        primary: metric(
          'result',
          'قیمت پس از تخفیف',
          value,
          percentage: false,
          unit: 'ریال',
        ),
        details: details,
        warnings: [
          CalculationWarning(
            code: 'assumptions',
            severity: WarningSeverity.information,
            message: basis,
          ),
        ],
        interpretation: basis,
      ),
    );
  }
}
