import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

double valueOf(CalculationOutcome outcome) =>
    ((outcome as CalculationSuccess).result.primary.value as NumericResultValue)
        .value;
List<String> codes(CalculationOutcome outcome) =>
    (outcome as CalculationFailure).issues.map((issue) => issue.code).toList();
RawCalculatorInput textInput(Map<String, String> entries) => RawCalculatorInput(
  entries.map((key, text) => MapEntry(key, RawTextInput(text))),
);
