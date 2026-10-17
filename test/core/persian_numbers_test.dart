import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/core/utils/persian_numbers.dart';

void main() {
  test('all digit sets normalize and roundtrip', () {
    expect(
      PersianNumbers.toLatin('۰۱۲۳۴۵۶۷۸۹ / ٠١٢٣٤٥٦٧٨٩'),
      '0123456789 / 0123456789',
    );
    expect(PersianNumbers.toPersian('API 26'), 'API ۲۶');
    expect(
      PersianNumbers.toLatin(PersianNumbers.toPersian('123.45')),
      '123.45',
    );
  });
  for (final input in ['۱۲۳٫۴۵', '١٢٣٫٤٥', '123.45', ' ۱۲٣.45 ']) {
    test('accepts $input', () {
      expect(PersianNumbers.tryParse(input), closeTo(123.45, 0.000001));
    });
  }
  test('signs, fractions, thousands and zero', () {
    expect(PersianNumbers.tryParse('−۱٬۲۳۴٫۵'), -1234.5);
    expect(PersianNumbers.tryParse('+1,234,567.5'), 1234567.5);
    expect(PersianNumbers.tryParse('.۵'), 0.5);
    expect(PersianNumbers.tryParse('۰'), 0);
  });
  for (final input in [
    '',
    ' ',
    'NaN',
    'Infinity',
    '1e3',
    '1,5',
    '۱۲٬۳۴',
    '1..2',
    '12 34',
    '--1',
    '۱۰۰٪',
    '۱۲٫۳٫۴',
  ]) {
    test('rejects malformed input "$input"', () {
      expect(PersianNumbers.tryParse(input), isNull);
    });
  }
  test('rejects overflow and formats finite values in Persian', () {
    expect(PersianNumbers.tryParse('9' * 400), isNull);
    expect(PersianNumbers.format(83.79), '۸۳٫۷۹');
    expect(PersianNumbers.format(120), '۱۲۰');
    expect(PersianNumbers.format(-0.00001), '۰');
    expect(PersianNumbers.format(-12.5), '-۱۲٫۵');
    expect(PersianNumbers.format(1.234, decimalPlaces: 2), '۱٫۲۳');
    expect(() => PersianNumbers.format(double.nan), throwsArgumentError);
    expect(() => PersianNumbers.format(double.infinity), throwsArgumentError);
    expect(() => PersianNumbers.format(1, decimalPlaces: 13), throwsRangeError);
  });
}
