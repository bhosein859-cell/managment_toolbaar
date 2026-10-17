import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

CalculatorDefinition definition({
  String id = 'test_calculator',
  List<InputFieldDefinition>? fields,
  String formula = 'y = x',
  List<CalculatorExample> examples = const [],
}) => CalculatorDefinition(
  id: id,
  categoryId: CalculatorCategoryId.production,
  nameFa: 'ابزار آزمایشی',
  nameEn: 'Test calculator',
  description: 'فقط برای تست قرارداد',
  formulaLatex: formula,
  fields: fields ?? [NumericFieldDefinition(id: 'x', label: 'مقدار')],
  examples: examples,
);

RawCalculatorInput raw(Map<String, String> entries) => RawCalculatorInput(
  entries.map((key, value) => MapEntry(key, RawTextInput(value))),
);

CalculationResult numericResult(double number) => CalculationResult(
  primary: ResultMetric(
    id: 'value',
    label: 'نتیجه',
    value: NumericResultValue(number),
  ),
);
