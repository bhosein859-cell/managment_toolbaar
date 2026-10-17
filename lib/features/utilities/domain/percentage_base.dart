import '../../calculators/domain/calculator_domain.dart';
import '../../calculators/domain/statistics/tool_numeric.dart';

final class PercentageBaseParameters implements CalculatorParameters {
  const PercentageBaseParameters({required this.part, required this.rate});
  final double part, rate;
}

final class PercentageBaseEngine
    implements CalculatorEngine<PercentageBaseParameters> {
  const PercentageBaseEngine();
  static const basis =
      'مقدار بخش نامنفی و درصد اکیداً مثبت است؛ درصد صفر نمی‌تواند پایه را تعیین کند. درصدهای بالای ۱۰۰ پذیرفته‌اند. واحد بخش و پایه یکسان است.';
  @override
  String get calculatorId => 'percentage_base';
  @override
  InputBinding<PercentageBaseParameters> bind(CalculatorInput input) {
    final p = PercentageBaseParameters(
      part: input.requireNumber('part'),
      rate: input.requireNumber('rate'),
    );
    final errors = _validate(p);
    return errors.isEmpty ? BoundInput(p) : RejectedInput(errors);
  }

  List<CalculationIssue> _validate(PercentageBaseParameters p) => toolValidate([
    ToolNumber('part', 'مقدار بخش', p.part, min: 0),
    ToolNumber('rate', 'درصد بخش از پایه', p.rate, min: 0, strictMin: true),
  ]);
  @override
  CalculationOutcome calculate(PercentageBaseParameters p) {
    final errors = _validate(p);
    if (errors.isNotEmpty) return CalculationFailure(errors);
    final value = p.part / p.rate;
    final details = <ResultMetric>[
      metric('part', 'مقدار بخش', p.part),
      metric('rate', 'درصد بخش از پایه', p.rate, percentage: true),
    ];
    if (invalidNumeric(value, nonzero: p.part > 0) ||
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
          'مقدار پایه از درصد',
          value,
          percentage: false,
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
