import 'package:flutter/foundation.dart';

import '../../domain/calculator_domain.dart';
import '../formatting/calculator_text.dart';

/// Presentation state only. All validation/formulas stay in the domain runner.
final class CalculatorFormController<I extends CalculatorParameters>
    extends ChangeNotifier {
  CalculatorFormController({
    required this.runner,
    RawCalculatorInput? initialInput,
  }) {
    _replace(initialInput, markTouched: initialInput != null);
  }

  final CalculatorRunner<I> runner;
  final _values = <String, RawFieldInput>{};
  final _touched = <String>{};
  late CalculationOutcome _outcome;

  CalculatorDefinition get definition => runner.definition;
  CalculationOutcome get outcome => _outcome;
  CalculationResult? get result => switch (_outcome) {
    CalculationSuccess(:final result) => result,
    CalculationFailure() => null,
  };
  RawCalculatorInput get inputs => RawCalculatorInput(_values);
  List<CalculationIssue> get issues => switch (_outcome) {
    CalculationFailure(:final issues) => issues,
    CalculationSuccess() => const [],
  };

  List<CalculationIssue> issuesFor(String id) => _touched.isNotEmpty
      ? issues.where((issue) => issue.fieldId == id).toList(growable: false)
      : const [];

  List<CalculationIssue> get globalIssues => issues
      .where(
        (issue) =>
            issue.fieldId == null ||
            !definition.fields.any((field) => field.id == issue.fieldId),
      )
      .toList(growable: false);

  String textFor(String id) => switch (_values[id]) {
    RawTextInput(:final text) => text,
    RawNumberListInput(:final items) => items.join('\n'),
    null => '',
  };

  void updateField(String id, RawFieldInput value) {
    if (!definition.fields.any((field) => field.id == id)) {
      throw ArgumentError('فیلد ناشناخته است');
    }
    _values[id] = value;
    _touched.add(id);
    _outcome = runner.run(inputs); // No stale success is retained on failure.
    notifyListeners();
  }

  void replaceInputs(RawCalculatorInput input) {
    _replace(input, markTouched: true);
    notifyListeners();
  }

  void reset() {
    _replace(null, markTouched: false);
    notifyListeners();
  }

  void _replace(RawCalculatorInput? input, {required bool markTouched}) {
    _values.clear();
    _touched.clear();
    for (final field in definition.fields) {
      final value = switch (field) {
        NumericFieldDefinition(:final defaultValue) => RawTextInput(
          defaultValue == null ? '' : numberInputText(defaultValue),
        ),
        ChoiceFieldDefinition(:final defaultValue) => RawTextInput(
          defaultValue ?? '',
        ),
        NumberListFieldDefinition(:final defaultValue) => RawNumberListInput(
          defaultValue?.map(numberInputText) ?? const [],
        ),
      };
      _values[field.id] = value;
    }
    if (input != null) {
      if (runner.normalizer.requireExplicitFields) {
        for (final field in definition.fields) {
          if (!input.values.containsKey(field.id)) {
            _values[field.id] = field is NumberListFieldDefinition
                ? RawNumberListInput([])
                : const RawTextInput('');
          }
        }
      }
      _values.addAll(input.values);
    }
    if (markTouched) _touched.addAll(_values.keys);
    _outcome = runner.run(inputs);
  }
}
