import 'package:flutter/material.dart';

import '../../domain/calculator_domain.dart';
import '../formatting/calculator_text.dart';

class CalculatorField extends StatelessWidget {
  const CalculatorField({
    super.key,
    required this.field,
    required this.rawText,
    required this.errors,
    required this.onChanged,
    this.textController,
    this.focusNode,
  });

  final InputFieldDefinition field;
  final String rawText;
  final List<CalculationIssue> errors;
  final ValueChanged<RawFieldInput> onChanged;
  final TextEditingController? textController;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final guidance = fieldGuidance(field);
    final suffix = [
      if (field case NumericFieldDefinition(kind: NumericInputKind.percentage))
        '٪',
      if (field.unit != null) field.unit!,
    ].join(' ');
    final decoration = InputDecoration(
      label: Semantics(
        label:
            '${field.label}${field.unit == null ? '' : ', واحد ${field.unit}'}${field is NumericFieldDefinition && (field as NumericFieldDefinition).kind == NumericInputKind.percentage ? ', بر حسب درصد' : ''}',
        excludeSemantics: true,
        child: Text(field.label),
      ),
      suffix: suffix.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Text(suffix, textDirection: TextDirection.ltr),
            ),
      helperText: guidance.isEmpty ? null : guidance,
      helperMaxLines: 8,
      errorText: errors.isEmpty
          ? null
          : errors.map((issue) => issue.message).join('\n'),
      errorMaxLines: 8,
      alignLabelWithHint: field is NumberListFieldDefinition,
    );
    if (field case ChoiceFieldDefinition(:final options)) {
      final selected = options.any((option) => option.id == rawText.trim())
          ? rawText.trim()
          : '';
      return InputDecorator(
        decoration: decoration,
        isEmpty: selected.isEmpty,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: Key('input-${field.id}'),
            value: selected,
            focusNode: focusNode,
            itemHeight: null,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: '', child: Text('انتخاب کنید')),
              ...options.map(
                (option) => DropdownMenuItem(
                  value: option.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(option.label),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(RawTextInput(value));
            },
          ),
        ),
      );
    }
    final isList = field is NumberListFieldDefinition;
    return TextField(
      key: Key('input-${field.id}'),
      controller: textController,
      focusNode: focusNode,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
      decoration: decoration,
      keyboardType: isList
          ? TextInputType.multiline
          : const TextInputType.numberWithOptions(decimal: true, signed: true),
      textInputAction: isList ? TextInputAction.newline : TextInputAction.next,
      minLines: isList ? 2 : 1,
      maxLines: isList ? 5 : 1,
      onChanged: (value) => onChanged(
        isList
            ? RawNumberListInput(
                value.trim().isEmpty ? const [] : value.split(RegExp(r'\r?\n')),
              )
            : RawTextInput(value),
      ),
    );
  }
}
