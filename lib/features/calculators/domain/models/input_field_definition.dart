import '../src/guards.dart';

sealed class InputFieldDefinition {
  InputFieldDefinition({
    required this.id,
    required this.label,
    this.isRequired = true,
    this.help = '',
    this.unit,
  }) {
    requireId(id);
    requireText(label, 'label');
    if (unit != null) requireText(unit!, 'unit');
  }
  final String id;
  final String label;
  final bool isRequired;
  final String help;
  final String? unit;
}

enum NumericInputKind { number, percentage }

/// Bounds and defaultValue are in DISPLAY units. A percentage default of 90
/// becomes 0.9 only after normalization; min/max use percentage points too.
final class NumericFieldDefinition extends InputFieldDefinition {
  NumericFieldDefinition({
    required super.id,
    required super.label,
    super.isRequired,
    super.help,
    super.unit,
    this.kind = NumericInputKind.number,
    this.min,
    this.max,
    this.defaultValue,
    this.integerOnly = false,
  }) {
    _checkBounds(min, max);
    if (defaultValue != null) {
      _checkNumber(defaultValue!, min, max);
      if (integerOnly && defaultValue! % 1 != 0) {
        throw ArgumentError('مقدار اولیه باید صحیح باشد');
      }
    }
  }
  final NumericInputKind kind;
  final double? min;
  final double? max;
  final double? defaultValue;
  final bool integerOnly;
}

final class ChoiceOption {
  ChoiceOption({required this.id, required this.label}) {
    requireId(id);
    requireText(label, 'label');
  }
  final String id;
  final String label;
}

final class ChoiceFieldDefinition extends InputFieldDefinition {
  ChoiceFieldDefinition({
    required super.id,
    required super.label,
    required Iterable<ChoiceOption> options,
    super.isRequired,
    super.help,
    super.unit,
    this.defaultValue,
  }) : options = List.unmodifiable(options) {
    if (this.options.isEmpty) throw ArgumentError('حداقل یک گزینه لازم است');
    requireUnique(this.options.map((option) => option.id));
    if (defaultValue != null &&
        !this.options.any((o) => o.id == defaultValue)) {
      throw ArgumentError('گزینهٔ اولیه در فهرست نیست');
    }
  }
  final List<ChoiceOption> options;
  final String? defaultValue;
}

/// Structured numeric series (e.g. periodic cash flows), not comma-split text.
final class NumberListFieldDefinition extends InputFieldDefinition {
  NumberListFieldDefinition({
    required super.id,
    required super.label,
    super.isRequired,
    super.help,
    super.unit,
    this.min,
    this.max,
    this.minItems = 1,
    this.maxItems = 1000,
    Iterable<double>? defaultValue,
  }) : defaultValue = defaultValue == null
           ? null
           : List.unmodifiable(defaultValue) {
    _checkBounds(min, max);
    if (minItems < 0 || (minItems == 0 && isRequired) || maxItems < minItems) {
      throw ArgumentError('تعداد موارد نامعتبر است');
    }
    final items = this.defaultValue;
    if (items != null) {
      if (items.length < minItems || items.length > maxItems) {
        throw ArgumentError('تعداد مقادیر اولیه نامعتبر است');
      }
      for (final value in items) {
        _checkNumber(value, min, max);
      }
    }
  }
  final double? min;
  final double? max;
  final int minItems;
  final int maxItems;
  final List<double>? defaultValue;
}

void _checkBounds(double? min, double? max) {
  if (min != null) requireFinite(min, 'min');
  if (max != null) requireFinite(max, 'max');
  if (min != null && max != null && min > max) {
    throw ArgumentError('بازه نامعتبر است');
  }
}

void _checkNumber(double value, double? min, double? max) {
  requireFinite(value, 'value');
  if ((min != null && value < min) || (max != null && value > max)) {
    throw ArgumentError('مقدار اولیه خارج از بازه است');
  }
}
