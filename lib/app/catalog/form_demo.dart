import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/form_demo_engine.dart';

abstract final class FormDemo {
  static final definition = CalculatorDefinition(
    id: 'form_demo',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'آزمایش فرم عمومی',
    nameEn: 'Generic form demo',
    description: 'نمونهٔ زیرساختی: مقدار باقی‌مانده پس از اعمال درصد کاهش، با واحد انتخابی.',
    formulaLatex: r'R = Q \times (1 - p/100)',
    assumptions: 'ورودی درصد از صفر تا صد است. تغییر واحد فقط برچسب است و تبدیل واحد انجام نمی‌شود. این نمونه جایگزین ماشین‌حساب‌های مراحل بعد نیست.',
    fields: [
      NumericFieldDefinition(
        id: 'quantity',
        label: 'مقدار اولیه',
        unit: 'واحد انتخابی',
        min: 0,
        max: 1e12,
        defaultValue: 100,
        help: 'مقدار اولیه را در واحد انتخابی وارد کنید.',
      ),
      NumericFieldDefinition(
        id: 'reduction',
        label: 'درصد کاهش',
        kind: NumericInputKind.percentage,
        min: 0,
        max: 100,
        defaultValue: 20,
        help: 'صفر یعنی بدون کاهش و صد یعنی کاهش کامل.',
      ),
      ChoiceFieldDefinition(
        id: 'unit',
        label: 'واحد',
        defaultValue: 'kg',
        options: [
          ChoiceOption(id: 'kg', label: 'کیلوگرم (kg)'),
          ChoiceOption(id: 'hours', label: 'ساعت (h)'),
        ],
        help: 'برچسب واحد ورودی و خروجی یکسان است.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'کاهش یک‌چهارم',
        inputs: RawCalculatorInput({
          'quantity': const RawTextInput('۲۰۰'),
          'reduction': const RawTextInput('۲۵'),
          'unit': const RawTextInput('hours'),
        }),
        explanation: 'از ۲۰۰ ساعت با کاهش ۲۵٪، مقدار ۱۵۰ ساعت باقی می‌ماند.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'remaining',
            label: 'مقدار باقی‌مانده',
            value: NumericResultValue(150, unit: 'h'),
          ),
        ),
      ),
    ],
  );
  static final runner = CalculatorRunner(
    definition: definition,
    engine: const FormDemoEngine(),
  );
}
