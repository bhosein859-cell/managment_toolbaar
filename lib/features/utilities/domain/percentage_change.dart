import '../../calculators/domain/calculator_domain.dart';
import '../../calculators/domain/statistics/tool_numeric.dart';

final class PercentageChangeParameters implements CalculatorParameters {
  const PercentageChangeParameters({
    required this.previous,
    required this.current,
  });
  final double previous, current;
}

final class PercentageChangeEngine
    implements CalculatorEngine<PercentageChangeParameters> {
  const PercentageChangeEngine();
  static const basis =
      'مبنای قبلی باید اکیداً مثبت و مقدار جدید نامنفی باشد. مبنای صفر درصد تغییر تعریف‌شده ندارد؛ مبنای منفی به دلیل ابهام تفسیر در این ابزار پذیرفته نیست. کاهش با علامت منفی گزارش می‌شود.';
  @override
  String get calculatorId => 'percentage_change';
  @override
  InputBinding<PercentageChangeParameters> bind(CalculatorInput input) {
    final p = PercentageChangeParameters(
      previous: input.requireNumber('previous'),
      current: input.requireNumber('current'),
    );
    final errors = _validate(p);
    return errors.isEmpty ? BoundInput(p) : RejectedInput(errors);
  }

  List<CalculationIssue> _validate(PercentageChangeParameters p) =>
      toolValidate([
        ToolNumber(
          'previous',
          'مقدار قبلی',
          p.previous,
          min: 0,
          strictMin: true,
        ),
        ToolNumber('current', 'مقدار جدید', p.current, min: 0),
      ]);
  @override
  CalculationOutcome calculate(PercentageChangeParameters p) {
    final errors = _validate(p);
    if (errors.isNotEmpty) return CalculationFailure(errors);
    final value = (p.current - p.previous) / p.previous;
    final details = <ResultMetric>[
      metric('previous', 'مقدار قبلی', p.previous),
      metric('current', 'مقدار جدید', p.current),
      metric('difference', 'تغییر مطلق', p.current - p.previous),
    ];
    if (invalidNumeric(value, nonzero: p.current != p.previous) ||
        details.any(
          (m) =>
              m.value is NumericResultValue &&
              !((m.value as NumericResultValue).value.isFinite),
        )) {
      return toolRange();
    }
    return CalculationSuccess(
      CalculationResult(
        primary: metric('result', 'درصد تغییر', value, percentage: true),
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
