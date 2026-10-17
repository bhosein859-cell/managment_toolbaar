import '../../calculators/domain/calculator_domain.dart';
import '../../calculators/domain/statistics/tool_numeric.dart';

final class PercentageOfParameters implements CalculatorParameters {
  const PercentageOfParameters({required this.amount, required this.rate});
  final double amount, rate;
}

final class PercentageOfEngine
    implements CalculatorEngine<PercentageOfParameters> {
  const PercentageOfEngine();
  static const basis =
      'مقدار و درصد نامنفی‌اند. درصد ورودی به صورت ۲۰ یعنی ۲۰٪ است؛ درصدهای بالای ۱۰۰ نیز مجازند. واحد خروجی با مقدار اولیه یکسان است.';
  @override
  String get calculatorId => 'percentage_of';
  @override
  InputBinding<PercentageOfParameters> bind(CalculatorInput input) {
    final p = PercentageOfParameters(
      amount: input.requireNumber('amount'),
      rate: input.requireNumber('rate'),
    );
    final errors = _validate(p);
    return errors.isEmpty ? BoundInput(p) : RejectedInput(errors);
  }

  List<CalculationIssue> _validate(PercentageOfParameters p) => toolValidate([
    ToolNumber('amount', 'مقدار اولیه', p.amount, min: 0),
    ToolNumber('rate', 'درصد', p.rate, min: 0),
  ]);
  @override
  CalculationOutcome calculate(PercentageOfParameters p) {
    final errors = _validate(p);
    if (errors.isNotEmpty) return CalculationFailure(errors);
    final value = p.amount * p.rate;
    final details = <ResultMetric>[
      metric('amount', 'مقدار اولیه', p.amount),
      metric('rate', 'درصد', p.rate, percentage: true),
    ];
    if (invalidNumeric(value, nonzero: p.amount > 0 && p.rate > 0) ||
        details.any(
          (m) =>
              m.value is NumericResultValue &&
              !((m.value as NumericResultValue).value.isFinite),
        )) {
      return toolRange();
    }
    return CalculationSuccess(
      CalculationResult(
        primary: metric('result', 'درصدی از مقدار', value, percentage: false),
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
