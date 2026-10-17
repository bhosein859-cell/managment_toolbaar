import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/core/utils/persian_numbers.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/formatting/calculator_text.dart';

void main() {
  test('editable default values roundtrip without rounding to zero', () {
    for (final value in [
      0.0,
      -0.0,
      120.0,
      -2.75,
      1e-20,
      -1.2e-8,
      1e21,
      1.7976931348623157e308,
      5e-324,
    ]) {
      expect(PersianNumbers.tryParse(numberInputText(value)), value);
    }
    expect(numberInputText(120), '۱۲۰');
    expect(() => numberInputText(double.infinity), throwsArgumentError);
  });
  test('numbers percentages text and lists are Persian and units retained', () {
    expect(resultValueText(NumericResultValue(80, unit: 'kg')), '۸۰ kg');
    expect(
      resultValueText(
        NumericResultValue(0.8379, display: NumberDisplay.percentage),
      ),
      '۸۳٫۷۹٪',
    );
    expect(resultValueText(TextResultValue('مسیر بحرانی')), 'مسیر بحرانی');
    expect(
      resultValueText(NumberListResultValue([1, 2.5], unit: 'h')),
      '۱ | ۲٫۵ h',
    );
    expect(displayNumber(-0.0), '۰');
  });
  test('scientific formatting never shows false zero or overflow', () {
    expect(displayNumber(1e-20), contains('۱۰^-۲۰'));
    expect(displayNumber(1e12), contains('۱۰^۱۲'));
    final percent = displayNumber(1e308, percentage: true);
    expect(percent, contains('۱۰^۳۱۰٪'));
    expect(percent, isNot(contains('Infinity')));
    expect(() => displayNumber(double.nan), throwsArgumentError);
  });
  test('guidance includes bounds units percentage conventions and optional integer flags', () {
    final numeric = fieldGuidance(
      NumericFieldDefinition(
        id: 'x',
        label: 'مقدار',
        kind: NumericInputKind.percentage,
        min: 0,
        max: 100,
        isRequired: false,
        integerOnly: true,
        help: 'راهنما',
      ),
    );
    expect(numeric, contains('بازهٔ مجاز: از ۰ تا ۱۰۰'));
    expect(numeric, contains('اختیاری'));
    expect(numeric, contains('فقط عدد صحیح'));
    expect(numeric, contains('۹۵٪'));
    expect(numeric, contains('\n'));
    expect(
      fieldGuidance(NumericFieldDefinition(id: 'x', label: 'مقدار', min: 1)),
      contains('حداقل مجاز: ۱'),
    );
    expect(
      fieldGuidance(NumericFieldDefinition(id: 'x', label: 'مقدار', max: 2)),
      contains('حداکثر مجاز: ۲'),
    );
    expect(
      fieldGuidance(
        NumberListFieldDefinition(id: 'x', label: 'داده‌ها', maxItems: 3),
      ),
      contains('تعداد: ۱ تا ۳'),
    );
  });
}
