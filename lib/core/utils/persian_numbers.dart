/// Pure Dart numeric localization; no dependency on UI or device locale.
abstract final class PersianNumbers {
  static const _persian = '۰۱۲۳۴۵۶۷۸۹';
  static const _arabic = '٠١٢٣٤٥٦٧٨٩';

  static String toLatin(String text) {
    final output = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final persianIndex = _persian.indexOf(char);
      final arabicIndex = _arabic.indexOf(char);
      output.write(
        persianIndex >= 0
            ? '$persianIndex'
            : arabicIndex >= 0
            ? '$arabicIndex'
            : char,
      );
    }
    return output.toString();
  }

  static String toPersian(String text) => text.replaceAllMapped(
    RegExp('[0-9]'),
    (match) => _persian[int.parse(match[0]!)],
  );

  /// Accepts . or Arabic decimal separator and properly grouped thousands.
  /// Does not guess comma decimals or silently remove malformed grouping.
  static double? tryParse(String text) {
    var normalized = toLatin(text.trim())
        .replaceAll('−', '-')
        .replaceAll('٫', '.')
        .replaceAll('٬', ',');
    if (normalized.contains(',')) {
      if (!RegExp(r'^[+-]?\d{1,3}(,\d{3})+(\.\d+)?$').hasMatch(normalized)) {
        return null;
      }
      normalized = normalized.replaceAll(',', '');
    }
    if (!RegExp(r'^[+-]?(\d+(\.\d*)?|\.\d+)$').hasMatch(normalized)) {
      return null;
    }
    final result = double.tryParse(normalized);
    return result != null && result.isFinite ? result : null;
  }

  /// Use this at presentation boundaries; calculation values stay numeric.
  static String format(num value, {int decimalPlaces = 2}) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'باید متناهی باشد');
    }
    RangeError.checkValueInInterval(decimalPlaces, 0, 12, 'decimalPlaces');
    var text = value.toStringAsFixed(decimalPlaces);
    if (text.contains('.')) text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    if (double.tryParse(text) == 0) text = '0';
    return toPersian(text.replaceAll('.', '٫'));
  }
}
