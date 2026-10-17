import '../src/guards.dart';

sealed class RawFieldInput {
  const RawFieldInput();
}

final class RawTextInput extends RawFieldInput {
  const RawTextInput(this.text);
  final String text;
}

final class RawNumberListInput extends RawFieldInput {
  RawNumberListInput(Iterable<String> items) : items = List.unmodifiable(items);
  final List<String> items;
}

final class RawCalculatorInput {
  RawCalculatorInput(Map<String, RawFieldInput> values)
    : values = Map.unmodifiable(values);
  final Map<String, RawFieldInput> values;
}

sealed class InputValue {
  const InputValue();
}

/// Percentage values are canonical fractions, not percentage points.
final class NumberInputValue extends InputValue {
  NumberInputValue(this.value) {
    requireFinite(value, 'value');
  }
  final double value;
}

final class ChoiceInputValue extends InputValue {
  ChoiceInputValue(this.optionId) {
    requireId(optionId);
  }
  final String optionId;
}

final class NumberListInputValue extends InputValue {
  NumberListInputValue(Iterable<double> values)
    : values = List.unmodifiable(values) {
    for (final value in this.values) {
      requireFinite(value, 'value');
    }
  }
  final List<double> values;
}

/// Snapshot of normalized input. Engines still bind this into their own typed
/// parameter classes, rather than calculating directly from text or config.
final class CalculatorInput {
  CalculatorInput(Map<String, InputValue> values)
    : values = Map.unmodifiable(values);
  final Map<String, InputValue> values;

  double requireNumber(String id) => switch (values[id]) {
    NumberInputValue(:final value) => value,
    _ => throw StateError('فیلد عددی مورد انتظار موجود نیست: $id'),
  };

  String requireChoice(String id) => switch (values[id]) {
    ChoiceInputValue(:final optionId) => optionId,
    _ => throw StateError('فیلد انتخابی مورد انتظار موجود نیست: $id'),
  };

  List<double> requireNumberList(String id) => switch (values[id]) {
    NumberListInputValue(:final values) => values,
    _ => throw StateError('فهرست عددی مورد انتظار موجود نیست: $id'),
  };
}
