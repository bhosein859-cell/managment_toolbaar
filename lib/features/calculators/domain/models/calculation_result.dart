import '../src/guards.dart';

final class CalculationIssue {
  CalculationIssue({
    required this.code,
    required this.message,
    this.fieldId,
    this.itemIndex,
  }) {
    requireId(code);
    requireText(message, 'message');
    if (fieldId != null) requireId(fieldId!);
    if (itemIndex != null && itemIndex! < 0) {
      throw ArgumentError('اندیس نامعتبر است');
    }
  }
  final String code;
  final String message;
  final String? fieldId;

  /// Zero-based index within a numeric series, if any.
  final int? itemIndex;
}

enum WarningSeverity { information, caution }

final class CalculationWarning {
  CalculationWarning({
    required this.code,
    required this.message,
    this.severity = WarningSeverity.caution,
  }) {
    requireId(code);
    requireText(message, 'message');
  }
  final String code;
  final String message;
  final WarningSeverity severity;
}

enum NumberDisplay { decimal, percentage }

sealed class ResultValue {
  const ResultValue();
}

final class NumericResultValue extends ResultValue {
  NumericResultValue(
    this.value, {
    this.unit,
    this.display = NumberDisplay.decimal,
  }) {
    requireFinite(value, 'value');
    if (unit != null) requireText(unit!, 'unit');
  }
  final double value;
  final String? unit;

  /// Percentage outputs are fractions; multiply by 100 only in presentation.
  final NumberDisplay display;
}

final class TextResultValue extends ResultValue {
  TextResultValue(this.value) {
    requireText(value, 'value');
  }
  final String value;
}

final class NumberListResultValue extends ResultValue {
  NumberListResultValue(Iterable<double> values, {this.unit})
    : values = List.unmodifiable(values) {
    for (final value in this.values) {
      requireFinite(value, 'value');
    }
    if (unit != null) requireText(unit!, 'unit');
  }
  final List<double> values;
  final String? unit;
}

final class ResultMetric {
  ResultMetric({required this.id, required this.label, required this.value}) {
    requireId(id);
    requireText(label, 'label');
  }
  final String id;
  final String label;
  final ResultValue value;
}

final class CalculationResult {
  CalculationResult({
    required this.primary,
    Iterable<ResultMetric> details = const [],
    Iterable<CalculationWarning> warnings = const [],
    this.interpretation = '',
  }) : details = List.unmodifiable(details),
       warnings = List.unmodifiable(warnings) {
    requireUnique([primary.id, ...this.details.map((metric) => metric.id)]);
  }
  final ResultMetric primary;
  final List<ResultMetric> details;
  final List<CalculationWarning> warnings;
  final String interpretation;
}

sealed class CalculationOutcome {
  const CalculationOutcome();
}

final class CalculationSuccess extends CalculationOutcome {
  const CalculationSuccess(this.result);
  final CalculationResult result;
}

final class CalculationFailure extends CalculationOutcome {
  CalculationFailure(Iterable<CalculationIssue> issues)
    : issues = List.unmodifiable(issues) {
    if (this.issues.isEmpty) throw ArgumentError('خطا نباید خالی باشد');
  }
  final List<CalculationIssue> issues;
}
