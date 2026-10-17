import '../calculator_domain.dart';

final class FormDemoParameters implements CalculatorParameters {
  const FormDemoParameters({
    required this.quantity,
    required this.reduction,
    required this.unit,
  });
  final double quantity;
  final double reduction;
  final String unit;
}

/// Explicit demonstration engine, not OEE, NPV or any production catalog tool.
final class FormDemoEngine implements CalculatorEngine<FormDemoParameters> {
  const FormDemoEngine();
  @override
  String get calculatorId => 'form_demo';

  @override
  InputBinding<FormDemoParameters> bind(CalculatorInput input) {
    final quantity = input.requireNumber('quantity');
    final reduction = input.requireNumber('reduction');
    final unit = input.requireChoice('unit');
    if (quantity < 0 ||
        reduction < 0 ||
        reduction > 1 ||
        !{'kg', 'hours'}.contains(unit)) {
      return RejectedInput([
        CalculationIssue(
          code: 'invalid_demo_input',
          message: 'ورودی نمونه معتبر نیست.',
        ),
      ]);
    }
    return BoundInput(
      FormDemoParameters(quantity: quantity, reduction: reduction, unit: unit),
    );
  }

  @override
  CalculationOutcome calculate(FormDemoParameters parameters) {
    if (!parameters.quantity.isFinite ||
        !parameters.reduction.isFinite ||
        parameters.quantity < 0 ||
        parameters.reduction < 0 ||
        parameters.reduction > 1 ||
        !{'kg', 'hours'}.contains(parameters.unit)) {
      return CalculationFailure([
        CalculationIssue(
          code: 'invalid_demo_input',
          message: 'ورودی نمونه معتبر نیست.',
        ),
      ]);
    }
    final unit = parameters.unit == 'kg' ? 'kg' : 'h';
    return CalculationSuccess(
      CalculationResult(
        primary: ResultMetric(
          id: 'remaining',
          label: 'مقدار باقی‌مانده',
          value: NumericResultValue(
            parameters.quantity * (1 - parameters.reduction),
            unit: unit,
          ),
        ),
        details: [
          ResultMetric(
            id: 'removed',
            label: 'مقدار کاهش',
            value: NumericResultValue(
              parameters.quantity * parameters.reduction,
              unit: unit,
            ),
          ),
          ResultMetric(
            id: 'reduction',
            label: 'درصد کاهش',
            value: NumericResultValue(
              parameters.reduction,
              display: NumberDisplay.percentage,
            ),
          ),
        ],
        warnings: [
          CalculationWarning(
            code: 'demo_only',
            severity: WarningSeverity.information,
            message: 'این ابزار فقط برای آزمایش فرم عمومی است.',
          ),
        ],
        interpretation: 'مقدار باقی‌مانده برابر مقدار اولیه پس از اعمال کاهش است؛ انتخاب واحد فقط برچسب را تغییر می‌دهد، نه مقدار را.',
      ),
    );
  }
}
