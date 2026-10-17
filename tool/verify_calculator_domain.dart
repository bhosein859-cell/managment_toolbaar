// Pure Dart smoke check: no Flutter runtime or device required.
import 'dart:io';

import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

void main() {
  final definition = CalculatorDefinition(
    id: 'domain_smoke',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'بررسی دامنه',
    nameEn: 'Domain smoke check',
    description: 'بررسی استقلال دامنه از Flutter',
    formulaLatex: 'display only',
    fields: [
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ',
        kind: NumericInputKind.percentage,
        min: 0,
        max: 100,
      ),
    ],
  );
  const normalizer = InputNormalizer();
  final result = normalizer.normalize(
    definition,
    RawCalculatorInput({'rate': const RawTextInput('۹۵')}),
  );
  if (result is! NormalizedInput ||
      result.input.requireNumber('rate') != 0.95) {
    throw StateError('نرمال‌سازی درصد ناموفق بود');
  }
  final invalid = normalizer.normalize(
    definition,
    RawCalculatorInput({'rate': const RawTextInput('NaN')}),
  );
  if (invalid is! InvalidInput ||
      invalid.issues.single.code != 'invalid_number') {
    throw StateError('اعتبارسنجی ورودی نامعتبر ناموفق بود');
  }
  stdout.writeln('Pure Dart domain smoke check passed.');
}
