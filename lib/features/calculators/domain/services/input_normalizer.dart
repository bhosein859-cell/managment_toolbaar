import '../../../../core/utils/persian_numbers.dart';
import '../models/calculation_result.dart';
import '../models/calculator_definition.dart';
import '../models/calculator_input.dart';
import '../models/input_field_definition.dart';

sealed class NormalizationOutcome {
  const NormalizationOutcome();
}

final class NormalizedInput extends NormalizationOutcome {
  const NormalizedInput(this.input);
  final CalculatorInput input;
}

final class InvalidInput extends NormalizationOutcome {
  InvalidInput(Iterable<CalculationIssue> issues)
    : issues = List.unmodifiable(issues) {
    if (this.issues.isEmpty) throw ArgumentError('خطا نباید خالی باشد');
  }
  final List<CalculationIssue> issues;
}

final class InputNormalizer {
  const InputNormalizer({this.requireExplicitFields = false});

  /// Opt-in for forms that must never replace omitted external observations with examples.
  final bool requireExplicitFields;

  NormalizationOutcome normalize(
    CalculatorDefinition definition,
    RawCalculatorInput raw,
  ) {
    final issues = <CalculationIssue>[];
    final values = <String, InputValue>{};
    final fieldIds = definition.fields.map((field) => field.id).toSet();
    for (final id in raw.values.keys) {
      if (!fieldIds.contains(id)) {
        // Unknown external keys are not trusted as stable domain identifiers.
        issues.add(
          CalculationIssue(
            code: 'unknown_field',
            message: 'یک فیلد ناشناخته در ورودی وجود دارد.',
          ),
        );
      }
    }
    for (final field in definition.fields) {
      final supplied = raw.values[field.id];
      if (supplied == null) {
        if (requireExplicitFields && field.isRequired) {
          issues.add(
            _issue(
              field,
              'required',
              'وارد کردن «${field.label}» الزامی است؛ دادهٔ ناقص با مقدار نمونه جایگزین نمی‌شود.',
            ),
          );
          continue;
        }
        // Under strict observation policy, omitted optional data stays absent.
        if (requireExplicitFields && !field.isRequired) continue;
        final defaultValue = _default(field);
        if (defaultValue != null) {
          values[field.id] = defaultValue;
        } else if (field.isRequired) {
          issues.add(
            _issue(field, 'required', 'وارد کردن «${field.label}» الزامی است.'),
          );
        }
        continue;
      }
      final correctType = switch (field) {
        NumericFieldDefinition() ||
        ChoiceFieldDefinition() => supplied is RawTextInput,
        NumberListFieldDefinition() => supplied is RawNumberListInput,
      };
      if (!correctType) {
        issues.add(
          _issue(
            field,
            'invalid_type',
            'نوع ورودی «${field.label}» معتبر نیست.',
          ),
        );
        continue;
      }
      final empty = switch (supplied) {
        RawTextInput(:final text) => text.trim().isEmpty,
        RawNumberListInput(:final items) => items.isEmpty,
      };
      if (empty) {
        if (field.isRequired) {
          issues.add(
            _issue(field, 'required', 'وارد کردن «${field.label}» الزامی است.'),
          );
        }
        continue; // Explicit blank never silently reuses a default.
      }
      switch (field) {
        case NumericFieldDefinition():
          final value = PersianNumbers.tryParse(
            (supplied as RawTextInput).text,
          );
          if (value == null) {
            issues.add(
              _issue(
                field,
                'invalid_number',
                'مقدار «${field.label}» باید عدد معتبر و متناهی باشد.',
              ),
            );
          } else if (_checkValue(field, value, field.min, field.max, issues)) {
            if (field.integerOnly && value % 1 != 0) {
              issues.add(
                _issue(
                  field,
                  'integer_required',
                  'مقدار «${field.label}» باید عدد صحیح باشد.',
                ),
              );
            } else {
              values[field.id] = NumberInputValue(_canonical(field, value));
            }
          }
        case ChoiceFieldDefinition():
          final id = (supplied as RawTextInput).text.trim();
          if (!field.options.any((option) => option.id == id)) {
            issues.add(
              _issue(
                field,
                'invalid_choice',
                'گزینهٔ انتخاب‌شده برای «${field.label}» معتبر نیست.',
              ),
            );
          } else {
            values[field.id] = ChoiceInputValue(id);
          }
        case NumberListFieldDefinition():
          final items = (supplied as RawNumberListInput).items;
          if (items.length < field.minItems || items.length > field.maxItems) {
            issues.add(
              _issue(
                field,
                'invalid_length',
                'تعداد موارد «${field.label}» باید بین ${PersianNumbers.format(field.minItems)} و ${PersianNumbers.format(field.maxItems)} باشد.',
              ),
            );
            continue;
          }
          final numbers = <double>[];
          final issueCount = issues.length;
          for (var index = 0; index < items.length; index++) {
            final value = PersianNumbers.tryParse(items[index]);
            if (value == null) {
              issues.add(
                _issue(
                  field,
                  'invalid_number',
                  'مورد ${PersianNumbers.format(index + 1)} در «${field.label}» عدد معتبر نیست.',
                  index,
                ),
              );
            } else if (_checkValue(
              field,
              value,
              field.min,
              field.max,
              issues,
              index,
            )) {
              numbers.add(value);
            }
          }
          if (issues.length == issueCount) {
            values[field.id] = NumberListInputValue(numbers);
          }
      }
    }
    return issues.isEmpty
        ? NormalizedInput(CalculatorInput(values))
        : InvalidInput(issues);
  }

  InputValue? _default(InputFieldDefinition field) => switch (field) {
    NumericFieldDefinition(:final defaultValue) =>
      defaultValue == null
          ? null
          : NumberInputValue(_canonical(field, defaultValue)),
    ChoiceFieldDefinition(:final defaultValue) =>
      defaultValue == null ? null : ChoiceInputValue(defaultValue),
    NumberListFieldDefinition(:final defaultValue) =>
      defaultValue == null ? null : NumberListInputValue(defaultValue),
  };

  double _canonical(NumericFieldDefinition field, double value) =>
      field.kind == NumericInputKind.percentage ? value / 100 : value;

  bool _checkValue(
    InputFieldDefinition field,
    double value,
    double? min,
    double? max,
    List<CalculationIssue> issues, [
    int? index,
  ]) {
    if (min != null && value < min) {
      issues.add(
        _issue(
          field,
          'below_min',
          'مقدار «${field.label}» نباید کمتر از ${PersianNumbers.toPersian(min.toString().replaceAll('.', '٫'))} باشد.',
          index,
        ),
      );
      return false;
    }
    if (max != null && value > max) {
      issues.add(
        _issue(
          field,
          'above_max',
          'مقدار «${field.label}» نباید بیشتر از ${PersianNumbers.toPersian(max.toString().replaceAll('.', '٫'))} باشد.',
          index,
        ),
      );
      return false;
    }
    return true;
  }

  CalculationIssue _issue(
    InputFieldDefinition field,
    String code,
    String message, [
    int? index,
  ]) => CalculationIssue(
    code: code,
    message: message,
    fieldId: field.id,
    itemIndex: index,
  );
}
