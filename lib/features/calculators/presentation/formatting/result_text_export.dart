import '../../domain/calculator_domain.dart';
import 'calculator_text.dart';

/// Human-readable, offline export. Original input text is retained (not a
/// normalized fraction); display units and selected unit names are explicit.
abstract final class ResultTextExport {
  static String format(
    CalculatorDefinition definition,
    RawCalculatorInput inputs,
    CalculationResult result,
  ) {
    final lines = <String>[
      'جعبه‌ابزار مدیریت',
      definition.nameFa,
      definition.nameEn,
      '',
      'ورودی‌ها:',
    ];
    for (final field in definition.fields) {
      final raw = inputs.values[field.id];
      if (raw == null) throw ArgumentError('ورودی کامل نیست: ${field.id}');
      final unit =
          field is NumericFieldDefinition &&
              field.kind == NumericInputKind.percentage
          ? '٪'
          : field.unit;
      final label = '${field.label}${unit == null ? '' : ' ($unit)'}';
      switch (raw) {
        case RawTextInput(:final text):
          if (field is ChoiceFieldDefinition) {
            final choices = field.options.where((o) => o.id == text.trim());
            if (choices.isEmpty) throw ArgumentError('گزینهٔ ناشناخته');
            lines.add('$label: ${choices.first.label}');
          } else {
            lines.add('$label: $text');
          }
        case RawNumberListInput(:final items):
          lines.add('$label:');
          for (var i = 0; i < items.length; i++) {
            lines.add('  ${i + 1}) ${items[i]}');
          }
      }
    }
    lines.addAll([
      '',
      'نتیجه:',
      '${result.primary.label}: ${resultValueText(result.primary.value)}',
      'نمایش با گرد کردن تا ۶ رقم اعشار؛ ورودی‌ها عین متن واردشده‌اند.',
    ]);
    for (final metric in result.details) {
      lines.add('${metric.label}: ${resultValueText(metric.value)}');
    }
    if (result.warnings.isNotEmpty) {
      lines.addAll([
        '',
        'فرض‌ها و هشدارها:',
        ...result.warnings.map((w) => '• ${w.message}'),
      ]);
    }
    if (result.interpretation.isNotEmpty &&
        !result.warnings.any((w) => w.message == result.interpretation)) {
      lines.addAll(['', 'توضیح:', result.interpretation]);
    }
    lines.addAll(['', 'سازنده حسین بختیاری']);
    return lines.join('\n');
  }
}
