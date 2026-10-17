import '../models/calculation_result.dart';
import '../models/calculator_definition.dart';
import '../models/calculator_input.dart';
import '../services/input_normalizer.dart';
import 'calculator_engine.dart';

typedef UnexpectedCalculationError = void Function(
  Object error,
  StackTrace stack,
);

/// The only route from raw form text to a compiled, typed calculation engine.
/// Formula strings are never interpreted or executed.
final class CalculatorRunner<I extends CalculatorParameters> {
  CalculatorRunner({
    required this.definition,
    required this.engine,
    this.normalizer = const InputNormalizer(),
    this.onUnexpectedError,
  }) {
    if (definition.id != engine.calculatorId) {
      throw ArgumentError('شناسهٔ موتور با تعریف ماشین‌حساب یکسان نیست');
    }
  }
  final CalculatorDefinition definition;
  final CalculatorEngine<I> engine;
  final InputNormalizer normalizer;
  final UnexpectedCalculationError? onUnexpectedError;

  CalculationOutcome run(RawCalculatorInput raw) {
    try {
      final normalized = normalizer.normalize(definition, raw);
      if (normalized is InvalidInput) {
        return CalculationFailure(normalized.issues);
      }
      final binding = engine.bind((normalized as NormalizedInput).input);
      return switch (binding) {
        BoundInput<I>(:final parameters) => engine.calculate(parameters),
        RejectedInput<I>(:final issues) => CalculationFailure(issues),
      };
    } on Object catch (error, stack) {
      try {
        onUnexpectedError?.call(error, stack);
      } on Object {
        // A failing diagnostics sink must not expose internal exceptions to UI.
      }
      return CalculationFailure([
        CalculationIssue(
          code: 'calculation_failed',
          message:
              'محاسبه انجام نشد. ورودی‌ها را بررسی کنید و دوباره تلاش کنید.',
        ),
      ]);
    }
  }
}
