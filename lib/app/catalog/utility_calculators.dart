import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/utilities/domain/discount.dart';
import '../../features/utilities/domain/percentage_base.dart';
import '../../features/utilities/domain/percentage_change.dart';
import '../../features/utilities/domain/percentage_of.dart';
import '../../features/utilities/domain/unit_conversion.dart';

abstract final class UtilityCalculators {
  static final percentageOf = CalculatorDefinition(
    id: 'percentage_of',
    categoryId: CalculatorCategoryId.utilities,
    nameFa: 'درصدی از مقدار',
    nameEn: 'Percentage of Amount',
    description: 'بخش موردنظر از یک مقدار با درصد معلوم.',
    formulaLatex: r'A\times p/100',
    assumptions: PercentageOfEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'مقدار اولیه',
        defaultValue: 250,
        min: 0,
        help: 'نامنفی؛ واحد این مقدار با سایر مقادیر همین محاسبه یکسان است.',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'درصد',
        defaultValue: 20,
        min: 0,
        kind: NumericInputKind.percentage,
        help: '۲۰ یعنی ۲۰٪؛ نه ۰٫۲۰.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('250'),
          'rate': const RawTextInput('20'),
        }),
        explanation: 'مقدار اولیه: 250؛ درصد: 20؛ نتیجهٔ مرجع: 50.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'result',
            label: 'نتیجهٔ مرجع',
            value: NumericResultValue(50),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'percentage_of',
        nameFa: 'درصدی از مقدار',
        nameEn: 'Percentage of Amount',
        description: 'بخش موردنظر از یک مقدار با درصد معلوم.',
      ),
    ],
  );
  static final percentageOfRunner = CalculatorRunner(
    definition: percentageOf,
    engine: const PercentageOfEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final percentageChange = CalculatorDefinition(
    id: 'percentage_change',
    categoryId: CalculatorCategoryId.utilities,
    nameFa: 'درصد تغییر',
    nameEn: 'Percentage Change',
    description: 'تغییر نسبی مقدار جدید نسبت به مبنای قبلی مثبت.',
    formulaLatex: r'(B-A)/A\times100\%',
    assumptions: PercentageChangeEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'previous',
        label: 'مقدار قبلی',
        defaultValue: 100,
        min: 0,
        help: 'صفر برای این فیلد پذیرفته نیست؛ مبنای مثبت لازم است.',
      ),
      NumericFieldDefinition(
        id: 'current',
        label: 'مقدار جدید',
        defaultValue: 125,
        min: 0,
        help: 'نامنفی؛ واحد این مقدار با سایر مقادیر همین محاسبه یکسان است.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی',
        inputs: RawCalculatorInput({
          'previous': const RawTextInput('100'),
          'current': const RawTextInput('125'),
        }),
        explanation: 'مقدار قبلی: 100؛ مقدار جدید: 125؛ نتیجهٔ مرجع: 0.25 (کسر؛ معادل ۲۵٪).',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'result',
            label: 'نتیجهٔ مرجع',
            value: NumericResultValue(0.25, display: NumberDisplay.percentage),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'percentage_change',
        nameFa: 'درصد تغییر',
        nameEn: 'Percentage Change',
        description: 'تغییر نسبی مقدار جدید نسبت به مبنای قبلی مثبت.',
      ),
    ],
  );
  static final percentageChangeRunner = CalculatorRunner(
    definition: percentageChange,
    engine: const PercentageChangeEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final percentageBase = CalculatorDefinition(
    id: 'percentage_base',
    categoryId: CalculatorCategoryId.utilities,
    nameFa: 'مقدار پایه از درصد',
    nameEn: 'Base from Percentage',
    description: 'بازسازی مقدار پایه از اندازهٔ بخش و درصد آن.',
    formulaLatex: r'B=A/(p/100)',
    assumptions: PercentageBaseEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'part',
        label: 'مقدار بخش',
        defaultValue: 50,
        min: 0,
        help: 'نامنفی؛ واحد این مقدار با سایر مقادیر همین محاسبه یکسان است.',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'درصد بخش از پایه',
        defaultValue: 20,
        min: 0,
        kind: NumericInputKind.percentage,
        help: 'صفر برای این فیلد پذیرفته نیست؛ مبنای مثبت لازم است.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی',
        inputs: RawCalculatorInput({
          'part': const RawTextInput('50'),
          'rate': const RawTextInput('20'),
        }),
        explanation: 'مقدار بخش: 50؛ درصد بخش از پایه: 20؛ نتیجهٔ مرجع: 250.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'result',
            label: 'نتیجهٔ مرجع',
            value: NumericResultValue(250),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'percentage_base',
        nameFa: 'مقدار پایه از درصد',
        nameEn: 'Base from Percentage',
        description: 'بازسازی مقدار پایه از اندازهٔ بخش و درصد آن.',
      ),
    ],
  );
  static final percentageBaseRunner = CalculatorRunner(
    definition: percentageBase,
    engine: const PercentageBaseEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final discount = CalculatorDefinition(
    id: 'discount',
    categoryId: CalculatorCategoryId.utilities,
    nameFa: 'محاسبهٔ تخفیف',
    nameEn: 'Discount',
    description: 'قیمت نهایی و مبلغ صرفه‌جویی با یک تخفیف مشخص.',
    formulaLatex: r'P_{final}=P(1-p/100)',
    assumptions: DiscountEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'price',
        label: 'قیمت اصلی',
        defaultValue: 100000,
        min: 0,
        unit: 'ریال',
        help: 'نامنفی؛ واحد این مقدار با سایر مقادیر همین محاسبه یکسان است.',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'درصد تخفیف',
        defaultValue: 20,
        min: 0,
        kind: NumericInputKind.percentage,
        max: 100,
        help: '۲۰ یعنی ۲۰٪؛ نه ۰٫۲۰.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی',
        inputs: RawCalculatorInput({
          'price': const RawTextInput('100000'),
          'rate': const RawTextInput('20'),
        }),
        explanation: 'قیمت اصلی: 100000؛ درصد تخفیف: 20؛ نتیجهٔ مرجع: 80000.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'result',
            label: 'نتیجهٔ مرجع',
            value: NumericResultValue(80000),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'discount',
        nameFa: 'محاسبهٔ تخفیف',
        nameEn: 'Discount',
        description: 'قیمت نهایی و مبلغ صرفه‌جویی با یک تخفیف مشخص.',
      ),
    ],
  );
  static final discountRunner = CalculatorRunner(
    definition: discount,
    engine: const DiscountEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final unitConversion = CalculatorDefinition(
    id: 'unit_conversion',
    categoryId: CalculatorCategoryId.utilities,
    nameFa: 'تبدیل واحد',
    nameEn: 'Unit Conversion',
    aliases: ['واحد', 'تبدیل دما', 'unit converter'],
    description:
        'تبدیل ۴۲ واحد مشخص در ۱۰ گروه کمیت؛ بدون اینترنت.\nواحدهای پشتیبانی‌شده:\n${UnitRegistry.summary.replaceAll('؛ ', '\n')}',
    formulaLatex: r'y=(x-z_1)\frac{s_1}{s_2}+z_2',
    assumptions: UnitConversionEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'مقدار مبدا',
        defaultValue: 1,
        help: 'فقط عدد متناهی؛ دامنهٔ مجاز به واحد مبدا وابسته است. دمای مطلق را با اختلاف دما اشتباه نگیرید.',
      ),
      ChoiceFieldDefinition(
        id: 'from_unit',
        label: 'واحد مبدا',
        defaultValue: 'm',
        options: [
          for (final u in UnitRegistry.units)
            ChoiceOption(id: u.id, label: u.label),
        ],
        help: 'واحدهای پشتیبانی‌شده: ${UnitRegistry.summary}',
      ),
      ChoiceFieldDefinition(
        id: 'to_unit',
        label: 'واحد مقصد',
        defaultValue: 'cm',
        options: [
          for (final u in UnitRegistry.units)
            ChoiceOption(id: u.id, label: u.label),
        ],
        help: 'واحدی از همان گروه مبدا انتخاب کنید؛ تبدیل بین دو گروه خطاست.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'متر به سانتی‌متر',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1'),
          'from_unit': const RawTextInput('m'),
          'to_unit': const RawTextInput('cm'),
        }),
        explanation: 'یک متر برابر ۱۰۰ سانتی‌متر است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'result',
            label: 'سانتی‌متر',
            value: NumericResultValue(100, unit: 'cm'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'unit_conversion',
        nameFa: 'تبدیل واحد',
        nameEn: 'Unit Conversion',
        description: 'بیان یک کمیت در واحدی دیگر از همان بعد؛ دمای مطلق علاوه بر ضریب، جابه‌جایی مبدا دارد.',
      ),
    ],
  );
  static final unitConversionRunner = CalculatorRunner(
    definition: unitConversion,
    engine: const UnitConversionEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        percentageOfRunner,
        percentageChangeRunner,
        percentageBaseRunner,
        discountRunner,
        unitConversionRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((r) => r.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({for (final r in runners) r.definition.id: r});
}
