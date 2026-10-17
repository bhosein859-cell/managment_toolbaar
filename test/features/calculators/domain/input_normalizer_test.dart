import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  const normalizer = InputNormalizer();
  for (final text in ['۱۲۳٫۴۵', '١٢٣٫٤٥', '123.45', '۱۲٣.45']) {
    test('normalizes $text before binding', () {
      final normalized = normalizer.normalize(
        definition(),
        raw({'x': text}),
      ) as NormalizedInput;
      expect(normalized.input.requireNumber('x'), closeTo(123.45, 1e-9));
    });
  }
  test('normalizes signs, thousands and inclusive bounds', () {
    final def = definition(
      fields: [
        NumericFieldDefinition(
          id: 'x',
          label: 'مقدار',
          min: -1234.5,
          max: 1234.5,
        ),
      ],
    );
    for (final text in ['−۱٬۲۳۴٫۵', '1,234.5']) {
      expect(
        normalizer.normalize(def, raw({'x': text})),
        isA<NormalizedInput>(),
      );
    }
  });
  test('percentages are checked as display points then converted once', () {
    final def = definition(
      fields: [
        NumericFieldDefinition(
          id: 'rate',
          label: 'نرخ',
          kind: NumericInputKind.percentage,
          min: 0,
          max: 100,
          defaultValue: 90,
        ),
      ],
    );
    final entered =
        normalizer.normalize(def, raw({'rate': '۹۵'})) as NormalizedInput;
    expect(entered.input.requireNumber('rate'), 0.95);
    final defaults = normalizer.normalize(def, raw({})) as NormalizedInput;
    expect(defaults.input.requireNumber('rate'), 0.9);
    for (final text in ['۰', '۱۰۰']) {
      expect(
        normalizer.normalize(def, raw({'rate': text})),
        isA<NormalizedInput>(),
      );
    }
    expect(
      (normalizer.normalize(
        def,
        raw({'rate': '۱۰۱'}),
      ) as InvalidInput).issues.single.code,
      'above_max',
    );
  });
  test('missing gets default, explicit blank never reuses it', () {
    final def = definition(
      fields: [
        NumericFieldDefinition(id: 'x', label: 'مقدار', defaultValue: 4),
      ],
    );
    expect(
      (normalizer.normalize(def, raw({})) as NormalizedInput).input
          .requireNumber('x'),
      4,
    );
    expect(
      (normalizer.normalize(
        def,
        raw({'x': ' '}),
      ) as InvalidInput).issues.single.code,
      'required',
    );
  });
  test(
    'required, optional blank and unknown fields have distinct handling',
    () {
      expect(
        (normalizer.normalize(
          definition(),
          raw({}),
        ) as InvalidInput).issues.single.code,
        'required',
      );
      final def = definition(
        fields: [
          NumericFieldDefinition(
            id: 'x',
            label: 'مقدار',
            isRequired: false,
            defaultValue: 4,
          ),
        ],
      );
      expect(
        (normalizer.normalize(
          def,
          raw({'x': ''}),
        ) as NormalizedInput).input.values,
        isEmpty,
      );
      final unknown = normalizer.normalize(
        def,
        raw({'x': '2', 'unsafe key': '3'}),
      ) as InvalidInput;
      expect(unknown.issues.single.code, 'unknown_field');
      expect(unknown.issues.single.fieldId, isNull);
      expect(unknown.issues.single.message, isNot(contains('unsafe key')));
    },
  );
  for (final invalid in [
    'NaN',
    'Infinity',
    '1,5',
    'abc',
    '۱٫۲٫۳',
    '1e3',
    '۹' * 400,
  ]) {
    test(
      'invalid numeric input never produces a value: ${invalid.length > 20 ? 'overflow' : invalid}',
      () {
        final result = normalizer.normalize(
          definition(),
          raw({'x': invalid}),
        ) as InvalidInput;
        expect(result.issues.single.code, 'invalid_number');
        expect(result.issues.single.fieldId, 'x');
        expect(result.issues.single.message, contains('مقدار'));
      },
    );
  }
  test('bounds and integer validation provide Persian issues', () {
    final def = definition(
      fields: [
        NumericFieldDefinition(
          id: 'x',
          label: 'تعداد',
          min: 1,
          max: 10,
          integerOnly: true,
        ),
      ],
    );
    expect(
      (normalizer.normalize(
        def,
        raw({'x': '0'}),
      ) as InvalidInput).issues.single.code,
      'below_min',
    );
    expect(
      (normalizer.normalize(
        def,
        raw({'x': '11'}),
      ) as InvalidInput).issues.single.code,
      'above_max',
    );
    expect(
      (normalizer.normalize(
        def,
        raw({'x': '1.5'}),
      ) as InvalidInput).issues.single.code,
      'integer_required',
    );
    final tiny = definition(
      fields: [NumericFieldDefinition(id: 'x', label: 'مقدار', min: 0.001)],
    );
    expect(
      (normalizer.normalize(
        tiny,
        raw({'x': '0'}),
      ) as InvalidInput).issues.single.message,
      contains('۰٫۰۰۱'),
    );
  });
  test(
    'choice accepts stable IDs rather than display labels, supports defaults',
    () {
      final def = definition(
        fields: [
          ChoiceFieldDefinition(
            id: 'choice',
            label: 'روش',
            options: [ChoiceOption(id: 'simple', label: 'ساده')],
            defaultValue: 'simple',
          ),
        ],
      );
      expect(
        (normalizer.normalize(def, raw({})) as NormalizedInput).input
            .requireChoice('choice'),
        'simple',
      );
      expect(
        (normalizer.normalize(
          def,
          raw({'choice': ' simple '}),
        ) as NormalizedInput).input.requireChoice('choice'),
        'simple',
      );
      expect(
        (normalizer.normalize(
          def,
          raw({'choice': 'ساده'}),
        ) as InvalidInput).issues.single.code,
        'invalid_choice',
      );
    },
  );
  test('optional fields and list defaults are normalized predictably', () {
    final def = definition(
      fields: [
        NumericFieldDefinition(
          id: 'optional',
          label: 'اختیاری',
          isRequired: false,
        ),
        ChoiceFieldDefinition(
          id: 'choice',
          label: 'روش',
          isRequired: false,
          options: [ChoiceOption(id: 'simple', label: 'ساده')],
        ),
        NumberListFieldDefinition(
          id: 'flows',
          label: 'جریان‌ها',
          defaultValue: [-1, 2],
        ),
        NumberListFieldDefinition(
          id: 'optional_list',
          label: 'فهرست اختیاری',
          isRequired: false,
        ),
      ],
    );
    final result =
        (normalizer.normalize(def, raw({})) as NormalizedInput).input;
    expect(result.values.keys, ['flows']);
    expect(result.requireNumberList('flows'), [-1, 2]);
  });
  test('list parses three digit systems and reports index-specific errors', () {
    final def = definition(
      fields: [
        NumberListFieldDefinition(
          id: 'flows',
          label: 'جریان‌ها',
          min: -10,
          max: 10,
          minItems: 2,
          maxItems: 3,
        ),
      ],
    );
    final ok = normalizer.normalize(
      def,
      RawCalculatorInput({
        'flows': RawNumberListInput(['−۱', '٢', '3']),
      }),
    ) as NormalizedInput;
    expect(ok.input.requireNumberList('flows'), [-1, 2, 3]);
    final invalid = normalizer.normalize(
      def,
      RawCalculatorInput({
        'flows': RawNumberListInput(['-11', '', '11']),
      }),
    ) as InvalidInput;
    expect(invalid.issues.map((issue) => issue.code), [
      'below_min',
      'invalid_number',
      'above_max',
    ]);
    expect(invalid.issues.map((issue) => issue.itemIndex), [0, 1, 2]);
    expect(invalid.issues[1].message, contains('۲'));
    final length = normalizer.normalize(
      def,
      RawCalculatorInput({
        'flows': RawNumberListInput(['1']),
      }),
    ) as InvalidInput;
    expect(length.issues.single.code, 'invalid_length');
    final empty = normalizer.normalize(
      def,
      RawCalculatorInput({'flows': RawNumberListInput([])}),
    ) as InvalidInput;
    expect(empty.issues.single.code, 'required');
  });
  test('wrong raw value types are rejected even when optional and empty', () {
    final def = definition(
      fields: [
        NumericFieldDefinition(id: 'x', label: 'مقدار', isRequired: false),
        ChoiceFieldDefinition(
          id: 'choice',
          label: 'روش',
          options: [ChoiceOption(id: 'a', label: 'الف')],
        ),
        NumberListFieldDefinition(id: 'flows', label: 'جریان‌ها'),
      ],
    );
    final result = normalizer.normalize(
      def,
      RawCalculatorInput({
        'x': RawNumberListInput([]),
        'choice': RawNumberListInput(['1']),
        'flows': const RawTextInput('1,2'),
      }),
    ) as InvalidInput;
    expect(result.issues.map((issue) => issue.code), [
      'invalid_type',
      'invalid_type',
      'invalid_type',
    ]);
  });
  test('all field issues accumulate and invalid input is immutable', () {
    final def = definition(
      fields: [
        NumericFieldDefinition(id: 'x', label: 'اول'),
        NumericFieldDefinition(id: 'y', label: 'دوم'),
      ],
    );
    final result =
        normalizer.normalize(def, raw({'x': 'bad', 'y': ''})) as InvalidInput;
    expect(result.issues, hasLength(2));
    expect(() => result.issues.clear(), throwsUnsupportedError);
  });
}
