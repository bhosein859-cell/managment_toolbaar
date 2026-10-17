import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/hr/absence_cost_engine.dart';
import '../../features/calculators/domain/engines/hr/cost_per_hire_engine.dart';
import '../../features/calculators/domain/engines/hr/employee_productivity_engine.dart';
import '../../features/calculators/domain/engines/hr/employee_turnover_engine.dart';
import '../../features/calculators/domain/engines/hr/replacement_time_engine.dart';
import '../../features/calculators/domain/engines/hr/training_roi_engine.dart';

abstract final class HrCalculators {
  static final costPerHire = CalculatorDefinition(
    id: 'cost_per_hire',
    categoryId: CalculatorCategoryId.humanResources,
    nameFa: 'هزینهٔ استخدام به‌ازای هر جذب',
    nameEn: 'Cost per Hire',
    aliases: ['cost per hire'],
    description: 'هزینهٔ استخدام به‌ازای هر جذب؛ شاخص توصیفی با تعریف دامنه و بازه، نه معیار قطعی عملکرد افراد یا سازمان.',
    formulaLatex: r'CPH=\frac{C_{internal}+C_{external}}{N_{hires}}',
    assumptions: CostPerHireEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'internal_cost',
        label: 'هزینهٔ داخلی تخصیص‌یافتهٔ جذب',
        unit: 'ریال',
        min: 0,
        defaultValue: 20000000,
        help: 'نامنفی؛ هزینهٔ سهم واحد جذب، زمان مصاحبه/ارزیابی و امور اداری مرتبط، با تخصیص مستند.',
      ),
      NumericFieldDefinition(
        id: 'external_cost',
        label: 'هزینهٔ خارجی جذب',
        unit: 'ریال',
        min: 0,
        defaultValue: 10000000,
        help: 'نامنفی؛ آگهی، کارمزد و خدمات جذب؛ اقلام مشترک با هزینهٔ داخلی دوباره شمرده نشوند.',
      ),
      NumericFieldDefinition(
        id: 'hires',
        label: 'تعداد جذب تکمیل‌شده',
        unit: 'نفر',
        min: 0,
        defaultValue: 3,
        integerOnly: true,
        max: 1000000000,
        help: 'صحیح و مثبت؛ افرادی که در بازهٔ گزارش کار را آغاز کرده‌اند، نه تعداد درخواست یا پیشنهاد.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'طول بازهٔ گزارش',
        unit: 'روز',
        min: 0,
        defaultValue: 90,
        help: 'مثبت؛ تمام داده‌ها باید از همین بازه و دامنه باشند. فقط زمینهٔ گزارش است و نتیجه را خودکار سالانه نمی‌کند.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی در بازهٔ مشخص',
        inputs: RawCalculatorInput({
          'internal_cost': const RawTextInput('20000000'),
          'external_cost': const RawTextInput('10000000'),
          'hires': const RawTextInput('3'),
          'period_days': const RawTextInput('90'),
        }),
        explanation: 'هزینهٔ داخلی ۲۰ میلیون و خارجی ۱۰ میلیون ریال برای ۳ شروع کار در ۹۰ روز: ۱۰ میلیون ریال/جذب.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'cost_per_hire',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(10000000, unit: 'ریال/جذب'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'cost_per_hire',
        nameFa: 'هزینهٔ استخدام به‌ازای هر جذب',
        nameEn: 'Cost per Hire',
        description: CostPerHireEngine.basis,
      ),
    ],
  );
  static final costPerHireRunner = CalculatorRunner(
    definition: costPerHire,
    engine: const CostPerHireEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final employeeTurnover = CalculatorDefinition(
    id: 'employee_turnover',
    categoryId: CalculatorCategoryId.humanResources,
    nameFa: 'نرخ ترک خدمت کارکنان',
    nameEn: 'Employee Turnover Rate',
    aliases: ['employee turnover'],
    description: 'نرخ ترک خدمت کارکنان؛ شاخص توصیفی با تعریف دامنه و بازه، نه معیار قطعی عملکرد افراد یا سازمان.',
    formulaLatex: r'Turnover=\frac{Exits}{(HC_{start}+HC_{end})/2}\times100\%',
    assumptions: EmployeeTurnoverEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'separations',
        label: 'تعداد خروج قطعی از دامنه',
        unit: 'نفر',
        min: 0,
        defaultValue: 5,
        integerOnly: true,
        max: 1000000000,
        help: 'صحیح و نامنفی؛ خروج‌های داوطلبانه/غیرداوطلبانه طبق سیاست ثابت؛ جابه‌جایی داخلی خروج سازمانی نیست.',
      ),
      NumericFieldDefinition(
        id: 'opening_headcount',
        label: 'تعداد کارکنان ابتدای بازه',
        unit: 'نفر',
        min: 0,
        defaultValue: 90,
        integerOnly: true,
        max: 1000000000,
        help: 'صحیح و نامنفی؛ همان تعریف کارکنان و دامنهٔ انتهای بازه.',
      ),
      NumericFieldDefinition(
        id: 'closing_headcount',
        label: 'تعداد کارکنان انتهای بازه',
        unit: 'نفر',
        min: 0,
        defaultValue: 110,
        integerOnly: true,
        max: 1000000000,
        help: 'صحیح و نامنفی؛ میانگین دو نقطه باید مثبت باشد.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'طول بازهٔ گزارش',
        unit: 'روز',
        min: 0,
        defaultValue: 90,
        help: 'مثبت؛ تمام داده‌ها باید از همین بازه و دامنه باشند. فقط زمینهٔ گزارش است و نتیجه را خودکار سالانه نمی‌کند.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی در بازهٔ مشخص',
        inputs: RawCalculatorInput({
          'separations': const RawTextInput('5'),
          'opening_headcount': const RawTextInput('90'),
          'closing_headcount': const RawTextInput('110'),
          'period_days': const RawTextInput('90'),
        }),
        explanation: '۵ خروج و شمار ابتدا/انتها ۹۰ و ۱۱۰ در ۹۰ روز: میانگین ۱۰۰ و نرخ دوره ۵٪؛ نه نرخ سالانه.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'employee_turnover',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(
              0.05,
              unit: null,
              display: NumberDisplay.percentage,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'employee_turnover',
        nameFa: 'نرخ ترک خدمت کارکنان',
        nameEn: 'Employee Turnover Rate',
        description: EmployeeTurnoverEngine.basis,
      ),
    ],
  );
  static final employeeTurnoverRunner = CalculatorRunner(
    definition: employeeTurnover,
    engine: const EmployeeTurnoverEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final employeeProductivity = CalculatorDefinition(
    id: 'employee_productivity',
    categoryId: CalculatorCategoryId.humanResources,
    nameFa: 'بهره‌وری نیروی کار؛ خروجی بر نفرساعت',
    nameEn: 'Labor Productivity per Worked Hour',
    aliases: ['employee productivity'],
    description: 'بهره‌وری نیروی کار؛ خروجی بر نفرساعت؛ شاخص توصیفی با تعریف دامنه و بازه، نه معیار قطعی عملکرد افراد یا سازمان.',
    formulaLatex: r'LP=\frac{StandardizedOutput}{WorkedPersonHours}',
    assumptions: EmployeeProductivityEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'output',
        label: 'خروجی همگن و استانداردشده',
        unit: 'واحد خروجی',
        min: 0,
        defaultValue: 4000,
        help: 'نامنفی؛ خروجی واقعی هم‌نوع با تعریف کیفیت/معادل‌سازی ثابت، نه شمار کارهای ناهمگن بدون وزن.',
      ),
      NumericFieldDefinition(
        id: 'worked_hours',
        label: 'ساعت کار واقعی نیروی کار',
        unit: 'نفرساعت',
        min: 0,
        defaultValue: 800,
        help: 'مثبت؛ جمع ساعت کار ثبت‌شدهٔ همهٔ کارکنان همان دامنه/بازه، بدون ساعت غیبت یا مرخصی کارنشده.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'طول بازهٔ گزارش',
        unit: 'روز',
        min: 0,
        defaultValue: 90,
        help: 'مثبت؛ تمام داده‌ها باید از همین بازه و دامنه باشند. فقط زمینهٔ گزارش است و نتیجه را خودکار سالانه نمی‌کند.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی در بازهٔ مشخص',
        inputs: RawCalculatorInput({
          'output': const RawTextInput('4000'),
          'worked_hours': const RawTextInput('800'),
          'period_days': const RawTextInput('90'),
        }),
        explanation: '۴۰۰۰ واحد خروجی همگن و ۸۰۰ نفرساعت کار واقعی در ۹۰ روز: ۵ واحد/نفرساعت.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'employee_productivity',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(5, unit: 'واحد خروجی/نفرساعت'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'employee_productivity',
        nameFa: 'بهره‌وری نیروی کار؛ خروجی بر نفرساعت',
        nameEn: 'Labor Productivity per Worked Hour',
        description: EmployeeProductivityEngine.basis,
      ),
    ],
  );
  static final employeeProductivityRunner = CalculatorRunner(
    definition: employeeProductivity,
    engine: const EmployeeProductivityEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final trainingRoi = CalculatorDefinition(
    id: 'training_roi',
    categoryId: CalculatorCategoryId.humanResources,
    nameFa: 'بازده برآوردی آموزش؛ ROI',
    nameEn: 'Estimated Training ROI',
    aliases: ['training roi'],
    description: 'بازده برآوردی آموزش؛ ROI؛ شاخص توصیفی با تعریف دامنه و بازه، نه معیار قطعی عملکرد افراد یا سازمان.',
    formulaLatex:
        r'ROI=\frac{B_{gross}\times a-C_{training}}{C_{training}}\times100\%',
    assumptions: TrainingRoiEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'gross_benefits',
        label: 'منافع پولی برآوردشده پیش از انتساب',
        unit: 'ریال',
        min: 0,
        defaultValue: 40000000,
        help: 'نامنفی؛ منافع پولی برآوردشده در پنجرهٔ پس از آموزش؛ منافع غیرپولی بدون روش ارزش‌گذاری وارد نشوند.',
      ),
      NumericFieldDefinition(
        id: 'attribution_rate',
        label: 'سهم برآوردی قابل انتساب به آموزش',
        unit: 'درصد',
        min: 0,
        defaultValue: 50,
        kind: NumericInputKind.percentage,
        max: 100,
        help: 'از صفر تا صد درصد؛ فرض تحلیلی مستند، نه احتمال اثبات‌شدهٔ علیت.',
      ),
      NumericFieldDefinition(
        id: 'training_cost',
        label: 'کل هزینهٔ آموزش cohort',
        unit: 'ریال',
        min: 0,
        defaultValue: 10000000,
        help: 'مثبت؛ شهریه، مواد، سفر و زمان کاری شرکت‌کنندگان/مدرس با تخصیص بدون هم‌پوشانی.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'طول بازهٔ گزارش',
        unit: 'روز',
        min: 0,
        defaultValue: 90,
        help: 'مثبت؛ تمام داده‌ها باید از همین بازه و دامنه باشند. فقط زمینهٔ گزارش است و نتیجه را خودکار سالانه نمی‌کند.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی در بازهٔ مشخص',
        inputs: RawCalculatorInput({
          'gross_benefits': const RawTextInput('40000000'),
          'attribution_rate': const RawTextInput('50'),
          'training_cost': const RawTextInput('10000000'),
          'period_days': const RawTextInput('90'),
        }),
        explanation: '۴۰ میلیون ریال منفعت ناخالص، انتساب ۵۰٪ و هزینهٔ ۱۰ میلیون برای cohort در پنجرهٔ ۹۰روزه: منفعت قابل انتساب ۲۰ میلیون و ROI برآوردی ۱۰۰٪.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'training_roi',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(
              1,
              unit: null,
              display: NumberDisplay.percentage,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'training_roi',
        nameFa: 'بازده برآوردی آموزش؛ ROI',
        nameEn: 'Estimated Training ROI',
        description: TrainingRoiEngine.basis,
      ),
    ],
  );
  static final trainingRoiRunner = CalculatorRunner(
    definition: trainingRoi,
    engine: const TrainingRoiEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final replacementTime = CalculatorDefinition(
    id: 'replacement_time',
    categoryId: CalculatorCategoryId.humanResources,
    nameFa: 'زمان تکمیل جایگزینی؛ میانگین مدت',
    nameEn: 'Replacement Completion Time',
    aliases: ['replacement time'],
    description: 'زمان تکمیل جایگزینی؛ میانگین مدت؛ شاخص توصیفی با تعریف دامنه و بازه، نه معیار قطعی عملکرد افراد یا سازمان.',
    formulaLatex:
        r'T_{replacement}=\frac{\sum ElapsedCalendarDays_i}{N_{completed}}',
    assumptions: ReplacementTimeEngine.basis,
    fields: [
      NumberListFieldDefinition(
        id: 'elapsed_days',
        label: 'روزهای سپری‌شده برای هر جایگزینی تکمیل‌شده',
        unit: 'روز/جایگزینی',
        min: 0,
        maxItems: 1000,
        defaultValue: [20, 30, 40],
        help: 'هر جایگزینی یک سطر: فاصلهٔ تأیید رسمی درخواست جایگزینی تا شروع واقعی کار فرد جدید، به روز تقویمی و نامنفی؛ حداکثر ۱۰۰۰ مورد. حداقل یک مورد لازم است.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'طول بازهٔ گزارش',
        unit: 'روز',
        min: 0,
        defaultValue: 90,
        help: 'مثبت؛ تمام داده‌ها باید از همین بازه و دامنه باشند. فقط زمینهٔ گزارش است و نتیجه را خودکار سالانه نمی‌کند.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی در بازهٔ مشخص',
        inputs: RawCalculatorInput({
          'elapsed_days': RawNumberListInput(['20', '30', '40']),
          'period_days': const RawTextInput('90'),
        }),
        explanation: 'جایگزینی‌های با شروع کار در ۹۰ روز گزارش، با مدت‌های ۲۰،۳۰،۴۰ روز: جمع ۹۰، تعداد ۳ و میانگین ۳۰ روز.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'replacement_time',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(30, unit: 'روز/جایگزینی'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'replacement_time',
        nameFa: 'زمان تکمیل جایگزینی؛ میانگین مدت',
        nameEn: 'Replacement Completion Time',
        description: ReplacementTimeEngine.basis,
      ),
    ],
  );
  static final replacementTimeRunner = CalculatorRunner(
    definition: replacementTime,
    engine: const ReplacementTimeEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final absenceCost = CalculatorDefinition(
    id: 'absence_cost',
    categoryId: CalculatorCategoryId.humanResources,
    nameFa: 'هزینهٔ مستقیم غیبت با پرداخت',
    nameEn: 'Direct Paid Absence Cost',
    aliases: ['absence cost'],
    description: 'هزینهٔ مستقیم غیبت با پرداخت؛ شاخص توصیفی با تعریف دامنه و بازه، نه معیار قطعی عملکرد افراد یا سازمان.',
    formulaLatex:
        r'C_{absence}=H_{paidAbsent}\times C_{loadedHour}+C_{extraCover}',
    assumptions: AbsenceCostEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'paid_absent_hours',
        label: 'نفرساعت غیبت با پرداخت',
        unit: 'نفرساعت',
        min: 0,
        defaultValue: 40,
        help: 'نامنفی؛ ساعت برنامه‌ریزی‌شدهٔ کارنشده که بابت آن پرداخت صورت گرفته است، در همان بازه.',
      ),
      NumericFieldDefinition(
        id: 'loaded_hourly_cost',
        label: 'هزینهٔ ساعتی با بار کارفرما',
        unit: 'ریال/نفرساعت',
        min: 0,
        defaultValue: 500000,
        help: 'مثبت؛ دستمزد و سهم کارفرما برای ساعت غیبت با پرداخت؛ در ترکیب شغلی متفاوت از میانگین وزنی مستند استفاده کنید.',
      ),
      NumericFieldDefinition(
        id: 'incremental_cover_cost',
        label: 'هزینهٔ اضافی پوشش غیبت',
        unit: 'ریال',
        min: 0,
        defaultValue: 2000000,
        help: 'نامنفی؛ هزینهٔ واقعی افزودهٔ جایگزین/اضافه‌کار، نه حقوق عادی ازقبل‌محاسبه‌شده؛ بدون شمارش دوباره.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'طول بازهٔ گزارش',
        unit: 'روز',
        min: 0,
        defaultValue: 90,
        help: 'مثبت؛ تمام داده‌ها باید از همین بازه و دامنه باشند. فقط زمینهٔ گزارش است و نتیجه را خودکار سالانه نمی‌کند.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی در بازهٔ مشخص',
        inputs: RawCalculatorInput({
          'paid_absent_hours': const RawTextInput('40'),
          'loaded_hourly_cost': const RawTextInput('500000'),
          'incremental_cover_cost': const RawTextInput('2000000'),
          'period_days': const RawTextInput('90'),
        }),
        explanation: '۴۰ نفرساعت غیبت با هزینهٔ ساعتی ۵۰۰ هزار و پوشش افزودهٔ ۲ میلیون ریال در ۹۰ روز: جمع ۲۲ میلیون ریال.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'absence_cost',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(22000000, unit: 'ریال/بازه'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'absence_cost',
        nameFa: 'هزینهٔ مستقیم غیبت با پرداخت',
        nameEn: 'Direct Paid Absence Cost',
        description: AbsenceCostEngine.basis,
      ),
    ],
  );
  static final absenceCostRunner = CalculatorRunner(
    definition: absenceCost,
    engine: const AbsenceCostEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        costPerHireRunner,
        employeeTurnoverRunner,
        employeeProductivityRunner,
        trainingRoiRunner,
        replacementTimeRunner,
        absenceCostRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((r) => r.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({for (final r in runners) r.definition.id: r});
}
