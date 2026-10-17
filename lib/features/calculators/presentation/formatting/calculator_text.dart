import '../../../../core/utils/persian_numbers.dart';
import '../../domain/calculator_domain.dart';

/// Lossless editable defaults, including small/large finite doubles.
String numberInputText(double value) {
  if (!value.isFinite) throw ArgumentError('مقدار باید متناهی باشد');
  if (value == 0) return '۰';
  var text = value.toString();
  if (text.contains('e')) {
    final parts = text.split('e');
    final exponent = int.parse(parts[1]);
    final negative = parts[0].startsWith('-');
    final mantissa = parts[0].replaceFirst('-', '');
    final dot = mantissa.indexOf('.');
    final digits = mantissa.replaceAll('.', '');
    final position = (dot < 0 ? mantissa.length : dot) + exponent;
    text = position <= 0
        ? '0.${'0' * -position}$digits'
        : position >= digits.length
        ? '$digits${'0' * (position - digits.length)}'
        : '${digits.substring(0, position)}.${digits.substring(position)}';
    if (negative) text = '-$text';
  }
  if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
  return PersianNumbers.toPersian(text.replaceAll('.', '٫'));
}

String displayNumber(double value, {bool percentage = false}) {
  if (!value.isFinite) throw ArgumentError('مقدار باید متناهی باشد');
  final scaled = percentage ? value * 100 : value;
  if (!scaled.isFinite ||
      (scaled != 0 && (scaled.abs() < 0.000001 || scaled.abs() >= 1e12))) {
    final parts = value.toStringAsExponential(6).split('e');
    final exponent = int.parse(parts[1]) + (percentage ? 2 : 0);
    final mantissa = parts[0].replaceFirst(RegExp(r'\.?0+$'), '');
    return '${PersianNumbers.toPersian(mantissa.replaceAll('.', '٫'))} × ۱۰^${PersianNumbers.toPersian('$exponent')}${percentage ? '٪' : ''}';
  }
  return '${PersianNumbers.format(scaled, decimalPlaces: 6)}${percentage ? '٪' : ''}';
}

String resultValueText(ResultValue value) => switch (value) {
  NumericResultValue(:final value, :final display, :final unit) =>
    '${displayNumber(value, percentage: display == NumberDisplay.percentage)}${unit == null ? '' : ' $unit'}',
  TextResultValue(:final value) => value,
  NumberListResultValue(:final values, :final unit) =>
    '${values.map(displayNumber).join(' | ')}${unit == null ? '' : ' $unit'}',
};

String fieldGuidance(InputFieldDefinition field) {
  final lines = <String>[];
  if (field.help.isNotEmpty) lines.add(field.help);
  if (!field.isRequired) lines.add('اختیاری');
  switch (field) {
    case NumericFieldDefinition():
      if (field.kind == NumericInputKind.percentage) {
        lines.add('بر حسب درصد؛ ۹۵ یعنی ۹۵٪');
      }
      if (field.integerOnly) lines.add('فقط عدد صحیح');
      lines.addAll(_bounds(field.min, field.max));
    case NumberListFieldDefinition():
      lines.add('هر عدد در یک سطر؛ کاما جداکنندهٔ سطر نیست.');
      lines.add(
        'تعداد: ${field.minItems} تا ${field.maxItems}'.replaceAllMapped(
          RegExp('[0-9]+'),
          (m) => PersianNumbers.toPersian(m[0]!),
        ),
      );
      lines.addAll(_bounds(field.min, field.max));
    case ChoiceFieldDefinition():
      break;
  }
  return lines.join('\n');
}

List<String> _bounds(double? min, double? max) => [
  if (min != null && max != null)
    'بازهٔ مجاز: از ${numberInputText(min)} تا ${numberInputText(max)}',
  if (min != null && max == null) 'حداقل مجاز: ${numberInputText(min)}',
  if (min == null && max != null) 'حداکثر مجاز: ${numberInputText(max)}',
];
