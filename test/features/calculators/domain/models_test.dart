import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  test('nine categories and typed Persian category metadata', () {
    expect(CalculatorCategoryId.values, hasLength(9));
    final category = CalculatorCategory(
      id: CalculatorCategoryId.finance,
      nameFa: 'مالی',
      nameEn: 'Finance',
      description: 'ابزارهای مالی',
    );
    expect(category.id, CalculatorCategoryId.finance);
    expect(category.nameFa, 'مالی');
    expect(
      () => CalculatorCategory(
        id: CalculatorCategoryId.finance,
        nameFa: ' ',
        nameEn: 'Finance',
        description: 'ابزارها',
      ),
      throwsArgumentError,
    );
  });

  test('definitions store display-only educational content and terms', () {
    final term = RelatedTerm(
      id: 'capacity',
      nameFa: 'ظرفیت',
      nameEn: 'Capacity',
      description: 'توان تولید',
    );
    final example = CalculatorExample(
      title: 'مثال',
      inputs: raw({'x': '۱۲'}),
      explanation: 'ورودی نمونه',
      expectedResult: numericResult(12),
    );
    final def = CalculatorDefinition(
      id: 'capacity_test',
      categoryId: CalculatorCategoryId.production,
      nameFa: 'ظرفیت',
      nameEn: 'Capacity',
      description: 'توضیح',
      formulaLatex: r'y = x',
      fields: [NumericFieldDefinition(id: 'x', label: 'مقدار')],
      aliases: ['توان'],
      examples: [example],
      relatedTerms: [term],
      assumptions: 'مثال آموزشی',
    );
    expect(def.formulaLatex, r'y = x');
    expect(
      def.examples.single.expectedResult!.primary.value,
      isA<NumericResultValue>(),
    );
    expect(def.relatedTerms.single.nameFa, 'ظرفیت');
    expect(() => def.aliases.add('دیگر'), throwsUnsupportedError);
    expect(() => def.examples.clear(), throwsUnsupportedError);
    expect(() => def.relatedTerms.clear(), throwsUnsupportedError);
  });

  test(
    'definition snapshots fields and rejects duplicate and unknown references',
    () {
      final fields = <InputFieldDefinition>[
        NumericFieldDefinition(id: 'x', label: 'مقدار'),
      ];
      final def = definition(fields: fields);
      fields.clear();
      expect(def.fields, hasLength(1));
      expect(() => def.fields.clear(), throwsUnsupportedError);
      expect(
        () => definition(
          fields: [
            NumericFieldDefinition(id: 'x', label: 'اول'),
            NumericFieldDefinition(id: 'x', label: 'دوم'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => definition(
          examples: [
            CalculatorExample(
              title: 'مثال',
              inputs: raw({'unknown': '1'}),
              explanation: 'اشتباه',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(() => definition(id: 'bad id'), throwsArgumentError);
    },
  );

  test(
    'invalid numeric ranges, bounds and defaults fail at configuration time',
    () {
      expect(
        () => NumericFieldDefinition(id: 'x', label: ''),
        throwsArgumentError,
      );
      expect(
        () => NumericFieldDefinition(id: 'x', label: 'مقدار', min: 2, max: 1),
        throwsArgumentError,
      );
      expect(
        () => NumericFieldDefinition(id: 'x', label: 'مقدار', min: double.nan),
        throwsArgumentError,
      );
      expect(
        () => NumericFieldDefinition(
          id: 'x',
          label: 'مقدار',
          max: double.infinity,
        ),
        throwsArgumentError,
      );
      expect(
        () => NumericFieldDefinition(
          id: 'x',
          label: 'مقدار',
          min: 0,
          defaultValue: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => NumericFieldDefinition(
          id: 'x',
          label: 'مقدار',
          max: 1,
          defaultValue: 2,
        ),
        throwsArgumentError,
      );
      expect(
        () => NumericFieldDefinition(
          id: 'x',
          label: 'مقدار',
          defaultValue: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        () => NumericFieldDefinition(
          id: 'x',
          label: 'تعداد',
          integerOnly: true,
          defaultValue: 1.5,
        ),
        throwsArgumentError,
      );
    },
  );

  test('choice configuration is immutable, unique and validates default', () {
    final options = [ChoiceOption(id: 'yes', label: 'بله')];
    final field = ChoiceFieldDefinition(
      id: 'choice',
      label: 'انتخاب',
      options: options,
      defaultValue: 'yes',
    );
    options.clear();
    expect(field.options.single.id, 'yes');
    expect(() => field.options.clear(), throwsUnsupportedError);
    expect(
      () => ChoiceFieldDefinition(id: 'choice', label: 'انتخاب', options: []),
      throwsArgumentError,
    );
    expect(
      () => ChoiceFieldDefinition(
        id: 'choice',
        label: 'انتخاب',
        options: [
          ChoiceOption(id: 'yes', label: 'بله'),
          ChoiceOption(id: 'yes', label: 'تکراری'),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => ChoiceFieldDefinition(
        id: 'choice',
        label: 'انتخاب',
        options: field.options,
        defaultValue: 'no',
      ),
      throwsArgumentError,
    );
  });

  test('numeric series validates limits and snapshots its defaults', () {
    final defaults = [1.0, 2.0];
    final field = NumberListFieldDefinition(
      id: 'flows',
      label: 'جریان‌ها',
      defaultValue: defaults,
    );
    defaults.clear();
    expect(field.defaultValue, [1, 2]);
    expect(() => field.defaultValue!.clear(), throwsUnsupportedError);
    expect(
      () => NumberListFieldDefinition(
        id: 'flows',
        label: 'جریان‌ها',
        minItems: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => NumberListFieldDefinition(
        id: 'flows',
        label: 'جریان‌ها',
        minItems: 3,
        maxItems: 2,
      ),
      throwsArgumentError,
    );
    expect(
      () => NumberListFieldDefinition(
        id: 'flows',
        label: 'جریان‌ها',
        defaultValue: [],
      ),
      throwsArgumentError,
    );
    expect(
      () => NumberListFieldDefinition(
        id: 'flows',
        label: 'جریان‌ها',
        min: 0,
        defaultValue: [-1],
      ),
      throwsArgumentError,
    );
  });

  test('raw and normalized input snapshots cannot be mutated from outside', () {
    final strings = ['۱', '۲'];
    final list = RawNumberListInput(strings);
    strings.clear();
    expect(list.items, ['۱', '۲']);
    expect(() => list.items.clear(), throwsUnsupportedError);
    final map = <String, RawFieldInput>{'x': const RawTextInput('1')};
    final input = RawCalculatorInput(map);
    map.clear();
    expect(input.values, hasLength(1));
    expect(() => input.values.clear(), throwsUnsupportedError);
    final normalizedMap = <String, InputValue>{
      'x': NumberInputValue(3),
      'choice': ChoiceInputValue('yes'),
      'flows': NumberListInputValue([1, 2]),
    };
    final normalized = CalculatorInput(normalizedMap);
    normalizedMap.clear();
    expect(normalized.requireNumber('x'), 3);
    expect(normalized.requireChoice('choice'), 'yes');
    expect(normalized.requireNumberList('flows'), [1, 2]);
    expect(() => normalized.values.clear(), throwsUnsupportedError);
    expect(
      () => normalized.requireNumberList('flows').clear(),
      throwsUnsupportedError,
    );
    expect(() => normalized.requireNumber('missing'), throwsStateError);
    expect(() => normalized.requireChoice('x'), throwsStateError);
    expect(() => normalized.requireNumberList('x'), throwsStateError);
  });

  for (final invalid in [
    double.nan,
    double.infinity,
    double.negativeInfinity,
  ]) {
    test('non-finite values cannot enter typed models: $invalid', () {
      expect(() => NumberInputValue(invalid), throwsArgumentError);
      expect(() => NumberListInputValue([invalid]), throwsArgumentError);
      expect(() => NumericResultValue(invalid), throwsArgumentError);
      expect(() => NumberListResultValue([invalid]), throwsArgumentError);
    });
  }

  test(
    'results carry immutable metrics, warnings, units and interpretation',
    () {
      final warnings = [
        CalculationWarning(
          code: 'assumption',
          message: 'فرض را بررسی کنید',
          severity: WarningSeverity.information,
        ),
      ];
      final numbers = [1.0, 2.0];
      final list = NumberListResultValue(numbers, unit: 'kg');
      numbers.clear();
      final details = [
        ResultMetric(id: 'series', label: 'داده‌ها', value: list),
        ResultMetric(
          id: 'explanation',
          label: 'توضیح',
          value: TextResultValue('نمونه'),
        ),
      ];
      final result = CalculationResult(
        primary: ResultMetric(
          id: 'ratio',
          label: 'نسبت',
          value: NumericResultValue(0.9, display: NumberDisplay.percentage),
        ),
        details: details,
        warnings: warnings,
        interpretation: 'فقط نمونه است',
      );
      details.clear();
      warnings.clear();
      expect((result.primary.value as NumericResultValue).value, 0.9);
      expect(result.details, hasLength(2));
      expect(result.warnings.single.message, contains('فرض'));
      expect(list.values, [1, 2]);
      expect(() => list.values.clear(), throwsUnsupportedError);
      expect(() => result.details.clear(), throwsUnsupportedError);
      expect(() => result.warnings.clear(), throwsUnsupportedError);
      expect(
        () => CalculationResult(
          primary: result.primary,
          details: [result.primary],
        ),
        throwsArgumentError,
      );
      expect(() => TextResultValue(' '), throwsArgumentError);
    },
  );

  test('failure, binding and warning messages are structured and nonempty', () {
    final issue = CalculationIssue(
      code: 'invalid_input',
      message: 'ورودی نامعتبر است',
      fieldId: 'x',
      itemIndex: 0,
    );
    final issues = [issue];
    final outcome = CalculationFailure(issues);
    issues.clear();
    expect(outcome.issues.single.fieldId, 'x');
    expect(() => outcome.issues.clear(), throwsUnsupportedError);
    expect(() => CalculationFailure([]), throwsArgumentError);
    expect(() => InvalidInput([]), throwsArgumentError);
    expect(
      () => CalculationIssue(code: 'invalid', message: 'خطا', itemIndex: -1),
      throwsArgumentError,
    );
    expect(
      () => CalculationWarning(code: 'invalid', message: ''),
      throwsArgumentError,
    );
  });
}
