import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/production/capacity_utilization_engine.dart';
import '../../features/calculators/domain/engines/production/cycle_time_engine.dart';
import '../../features/calculators/domain/engines/production/labor_productivity_engine.dart';
import '../../features/calculators/domain/engines/production/production_capacity_engine.dart';
import '../../features/calculators/domain/engines/production/smed_engine.dart';
import '../../features/calculators/domain/engines/production/takt_time_engine.dart';
import '../../features/calculators/domain/engines/production/throughput_engine.dart';
import '../../features/calculators/domain/engines/production/unit_production_cost_engine.dart';
import '../../features/calculators/domain/engines/production/wip_engine.dart';
import 'prototype_calculators.dart';

/// Production tools: shared OEE plus nine independent, compiled engines.
abstract final class ProductionCalculators {
  static final taktTime = CalculatorDefinition(
    id: 'takt_time',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'زمان تکت — Takt Time',
    nameEn: 'Takt Time',
    aliases: ['تاکت تایم', 'آهنگ تقاضا'],
    description: 'زمان خالص در دسترس به ازای هر واحد تقاضا؛ آهنگ موردنیاز مشتری، نه زمان واقعی ساخت.',
    formulaLatex: r'T_{takt}=\frac{T_{net}}{D}',
    assumptions: 'زمان خالص یک بازه پس از کسر استراحت و توقف برنامه‌ریزی‌شده است؛ تقاضای همان بازه و همان محصول/واحد را وارد کنید. تکت با زمان سیکل واقعی یا ظرفیت تضمین‌شده یکی نیست. برای سبد محصولات باید ابتدا واحد معادل و ترکیب ثابت تعریف شود.',
    fields: [
      NumericFieldDefinition(
        id: 'available_time',
        label: 'زمان خالص در دسترس',
        unit: 'دقیقه',
        defaultValue: 420,
        help: 'زمان بازه پس از کسر وقفه‌های برنامه‌ریزی‌شده؛ باید بزرگ‌تر از صفر باشد.',
      ),
      NumericFieldDefinition(
        id: 'demand',
        label: 'تقاضای همان بازه',
        unit: 'واحد محصول',
        defaultValue: 210,
        help:
            'تقاضای مثبت برای یک محصول یا واحد معادل همگن؛ نه تعداد تولیدشده.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'available_time': const RawTextInput('420'),
          'demand': const RawTextInput('210'),
        }),
        explanation: '۴۲۰ دقیقه زمان خالص و تقاضای ۲۱۰ واحد: تکت ۲ دقیقه برای هر واحد است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'takt_time',
            label: 'زمان تکت — Takt Time',
            value: NumericResultValue(
              2,
              unit: 'دقیقه/واحد',
              display: NumberDisplay.decimal,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'takt_time',
        nameFa: 'زمان تکت — Takt Time',
        nameEn: 'Takt Time',
        description: 'زمان خالص در دسترس به ازای هر واحد تقاضا؛ آهنگ موردنیاز مشتری، نه زمان واقعی ساخت.',
      ),
    ],
  );
  static final taktTimeRunner = CalculatorRunner(
    definition: taktTime,
    engine: const TaktTimeEngine(),
  );
  static final productionCapacity = CalculatorDefinition(
    id: 'production_capacity',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'ظرفیت تولید',
    nameEn: 'Production Capacity',
    aliases: ['ظرفیت نظری', 'توان تولید'],
    description: 'ظرفیت نظری منابع یکسان و موازی بر اساس زمان برنامه‌ای خالص و سیکل ایده‌آل.',
    formulaLatex: r'C=\frac{T_{net}}{CT_{ideal}}\times m',
    assumptions: 'منابع باید یکسان، مستقل و موازی باشند؛ ظرفیت ماشین‌های متوالی را با این فرمول جمع نکنید و گلوگاه خط را جدا بررسی کنید. زمان خالص برای هر منبع برابر است. توقف ناخواسته، ضایعات، OEE و محدودیت تقاضا لحاظ نشده‌اند. خروجی کسری، ظرفیت معادل است و خودکار رو به پایین گرد نمی‌شود.',
    fields: [
      NumericFieldDefinition(
        id: 'available_time',
        label: 'زمان خالص هر منبع در بازه',
        unit: 'دقیقه',
        defaultValue: 480,
        min: 0,
        help: 'زمان یکسان برای هر منبع؛ پس از وقفهٔ برنامه‌ای، نامنفی؛ صفر یعنی ظرفیت صفر.',
      ),
      NumericFieldDefinition(
        id: 'ideal_cycle',
        label: 'زمان سیکل ایده‌آل هر منبع',
        unit: 'دقیقه/واحد',
        defaultValue: 2,
        help: 'مبنای ایده‌آل معتبر برای همان محصول؛ بزرگ‌تر از صفر و بدون ضریب OEE.',
      ),
      NumericFieldDefinition(
        id: 'parallel_resources',
        label: 'تعداد منابع یکسان و موازی',
        unit: 'منبع',
        defaultValue: 2,
        min: 1,
        max: 9007199254740991,
        integerOnly: true,
        help: 'عدد صحیح از ۱ تا ۹۰۰۷۱۹۹۲۵۴۷۴۰۹۹۱؛ برای ایستگاه‌های متوالی کاربرد ندارد.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'available_time': const RawTextInput('480'),
          'ideal_cycle': const RawTextInput('2'),
          'parallel_resources': const RawTextInput('2'),
        }),
        explanation: 'دو منبع موازی، هرکدام ۴۸۰ دقیقه و سیکل ۲ دقیقه: ظرفیت نظری ۴۸۰ واحد در بازه است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'production_capacity',
            label: 'ظرفیت تولید',
            value: NumericResultValue(
              480,
              unit: 'واحد/بازه',
              display: NumberDisplay.decimal,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'production_capacity',
        nameFa: 'ظرفیت تولید',
        nameEn: 'Production Capacity',
        description: 'ظرفیت نظری منابع یکسان و موازی بر اساس زمان برنامه‌ای خالص و سیکل ایده‌آل.',
      ),
    ],
  );
  static final productionCapacityRunner = CalculatorRunner(
    definition: productionCapacity,
    engine: const ProductionCapacityEngine(),
  );
  static final laborProductivity = CalculatorDefinition(
    id: 'labor_productivity',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'بهره‌وری نیروی کار',
    nameEn: 'Labor Productivity',
    aliases: ['بهره وری کار', 'نفرساعت', 'units per labor hour'],
    description: 'خروجی سالم همگن به ازای مجموع نفرساعت تخصیص‌یافته به تولید در یک بازه.',
    formulaLatex: r'LP=\frac{Q_{good}}{H_{labor}}',
    assumptions: 'در این ابزار مبنا، کل نفرساعت تخصیص‌یافته به تولید، شامل توقف‌های همان تخصیص است؛ نه فقط ساعت کار مفید و نه ساعت ماشین. ساعت همهٔ افراد را جمع کنید. برای محصولات متفاوت ابتدا واحد معادل مشترک تعریف کنید. این شاخص ارزیابی فردی یا درصد کارایی نسبت به استاندارد نیست.',
    fields: [
      NumericFieldDefinition(
        id: 'good_output',
        label: 'خروجی سالم همان بازه',
        unit: 'واحد سالم',
        defaultValue: 800,
        min: 0,
        help:
            'نامنفی و بدون دوباره‌شماری دوباره‌کاری؛ محصول یا واحد معادل همگن.',
      ),
      NumericFieldDefinition(
        id: 'labor_hours',
        label: 'جمع نفرساعت تخصیص‌یافته',
        unit: 'نفرساعت',
        defaultValue: 100,
        help: 'ساعت همهٔ افراد را جمع کنید؛ شامل توقف‌های همان تخصیص، بزرگ‌تر از صفر.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'good_output': const RawTextInput('800'),
          'labor_hours': const RawTextInput('100'),
        }),
        explanation: '۸۰۰ واحد سالم با مجموع ۱۰۰ نفرساعت تخصیص‌یافته: بهره‌وری ۸ واحد سالم/نفرساعت.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'labor_productivity',
            label: 'بهره‌وری نیروی کار',
            value: NumericResultValue(
              8,
              unit: 'واحد سالم/نفرساعت',
              display: NumberDisplay.decimal,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'labor_productivity',
        nameFa: 'بهره‌وری نیروی کار',
        nameEn: 'Labor Productivity',
        description: 'خروجی سالم همگن به ازای مجموع نفرساعت تخصیص‌یافته به تولید در یک بازه.',
      ),
    ],
  );
  static final laborProductivityRunner = CalculatorRunner(
    definition: laborProductivity,
    engine: const LaborProductivityEngine(),
  );
  static final cycleTime = CalculatorDefinition(
    id: 'cycle_time',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'زمان سیکل',
    nameEn: 'Cycle Time',
    aliases: ['سیکل تایم', 'چرخه تولید'],
    description: 'متوسط زمان کارکرد واقعی به ازای هر واحد کل تولیدشده، شامل سالم و ضایعات.',
    formulaLatex: r'CT_{avg}=\frac{T_{run}}{Q_{total}}',
    assumptions: 'زمان این محاسبه، زمان کارکرد واقعی تجهیز است و توقف را شامل نمی‌شود؛ تعداد کل شامل سالم و ضایعات است. این میانگین معادل زمان ایده‌آل، تکت یا زمان عبور یک سفارش نیست. برای کار موازی و دسته‌ای، عدد حاصل فاصلهٔ معادل خروجی است و لزوماً مدت عملیات هر قطعه نیست.',
    fields: [
      NumericFieldDefinition(
        id: 'run_time',
        label: 'زمان کارکرد واقعی',
        unit: 'دقیقه',
        defaultValue: 420,
        help: 'فقط زمان کارکرد، بدون توقف؛ بزرگ‌تر از صفر.',
      ),
      NumericFieldDefinition(
        id: 'total_output',
        label: 'کل خروجی تولیدشده',
        unit: 'واحد کل',
        defaultValue: 210,
        help: 'سالم به‌علاوه ضایعات در همان کارکرد، بدون دوباره‌شماری؛ بزرگ‌تر از صفر.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'run_time': const RawTextInput('420'),
          'total_output': const RawTextInput('210'),
        }),
        explanation: '۴۲۰ دقیقه کارکرد برای ۲۱۰ واحد کل: زمان سیکل متوسط ۲ دقیقه/واحد است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'cycle_time',
            label: 'زمان سیکل',
            value: NumericResultValue(
              2,
              unit: 'دقیقه/واحد',
              display: NumberDisplay.decimal,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'cycle_time',
        nameFa: 'زمان سیکل',
        nameEn: 'Cycle Time',
        description: 'متوسط زمان کارکرد واقعی به ازای هر واحد کل تولیدشده، شامل سالم و ضایعات.',
      ),
    ],
  );
  static final cycleTimeRunner = CalculatorRunner(
    definition: cycleTime,
    engine: const CycleTimeEngine(),
  );
  static final smed = CalculatorDefinition(
    id: 'smed',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'کاهش زمان تعویض — SMED',
    nameEn: 'SMED Setup Reduction',
    aliases: [
      'زمان تعویض',
      'کاهش زمان آماده سازی',
      'Single Minute Exchange of Die',
    ],
    description: 'اندازه‌گیری درصد کاهش و دقیقهٔ صرفه‌جویی زمان تعویض؛ افزایش زمان هم بدون پنهان‌سازی گزارش می‌شود.',
    formulaLatex: r'R=\frac{S_{before}-S_{after}}{S_{before}},\quad \Delta S=S_{before}-S_{after}',
    assumptions: 'در این ابزار زمان تعویض از آخرین قطعهٔ سالم محصول قبلی تا اولین قطعهٔ سالم محصول بعدی با کیفیت/سرعت مورد توافق اندازه‌گیری می‌شود؛ قبل و بعد باید مبنای یکسان داشته باشند. ابزار فقط کاهش زمان را می‌سنجد، نه مراحل اجرای روش SMED. هدف single-minute معمولاً کمتر از ده دقیقه است؛ درصد کاهش به‌تنهایی تحقق این هدف را ثابت نمی‌کند. مقدار بعد بزرگ‌تر از قبل مجاز است و کاهش منفی گزارش می‌شود.',
    fields: [
      NumericFieldDefinition(
        id: 'before_time',
        label: 'زمان تعویض پیش از تغییر',
        unit: 'دقیقه',
        defaultValue: 60,
        help: 'از آخرین سالم قبلی تا اولین سالم بعدی با معیار مشترک؛ بزرگ‌تر از صفر.',
      ),
      NumericFieldDefinition(
        id: 'after_time',
        label: 'زمان تعویض پس از تغییر',
        unit: 'دقیقه',
        defaultValue: 20,
        min: 0,
        help: 'با همان تعریف قبلی؛ نامنفی و مجاز به بزرگ‌تر بودن از مقدار قبل.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'before_time': const RawTextInput('60'),
          'after_time': const RawTextInput('20'),
        }),
        explanation: 'از ۶۰ به ۲۰ دقیقه: ۴۰ دقیقه صرفه‌جویی و ۶۶٫۶۶۶۶۶۷٪ کاهش؛ هنوز زمان بعد کمتر از ده دقیقه نیست.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'smed',
            label: 'کاهش زمان تعویض — SMED',
            value: NumericResultValue(
              0.6666666666666666,
              unit: null,
              display: NumberDisplay.percentage,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'smed',
        nameFa: 'کاهش زمان تعویض — SMED',
        nameEn: 'SMED Setup Reduction',
        description: 'اندازه‌گیری درصد کاهش و دقیقهٔ صرفه‌جویی زمان تعویض؛ افزایش زمان هم بدون پنهان‌سازی گزارش می‌شود.',
      ),
    ],
  );
  static final smedRunner = CalculatorRunner(
    definition: smed,
    engine: const SmedEngine(),
  );
  static final unitProductionCost = CalculatorDefinition(
    id: 'unit_production_cost',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'هزینهٔ تولید واحد',
    nameEn: 'Unit Production Cost',
    aliases: ['بهای تمام شده واحد', 'هزینه هر قطعه'],
    description:
        'هزینهٔ ساخت تخصیص‌یافته در بازه تقسیم بر خروجی سالم همان بازه.',
    formulaLatex: r'UC=\frac{C_{allocated}}{Q_{good}}',
    assumptions: 'صورت باید هزینهٔ ساخت تخصیص‌یافته شامل مواد، دستمزد و سربار با روش حسابداری انتخابی سازمان باشد؛ هزینهٔ ضایعات در صورت باقی می‌ماند و مخرج فقط خروجی سالم است. روش جذب سربار، تغییر موجودی، ظرفیت عادی و دوباره‌کاری را حسابداری تعیین می‌کند؛ ابزار تخصیص خودکار ندارد. مبالغ همه ریال‌اند، نه مخلوط ریال/تومان. این شاخص قیمت فروش، هزینهٔ نهایی یا ارزش‌گذاری استاندارد موجودی نیست.',
    fields: [
      NumericFieldDefinition(
        id: 'allocated_cost',
        label: 'کل هزینهٔ ساخت تخصیص‌یافته',
        unit: 'ریال',
        defaultValue: 1500000,
        min: 0,
        help: 'نامنفی؛ مواد، دستمزد و سربار همان دوره با روش سازمان، شامل هزینهٔ ضایعات.',
      ),
      NumericFieldDefinition(
        id: 'good_output',
        label: 'خروجی سالم متناظر',
        unit: 'واحد سالم',
        defaultValue: 500,
        help: 'بزرگ‌تر از صفر؛ هم‌دوره و هم‌مرز با هزینه، بدون ضایعات و دوباره‌شماری.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'allocated_cost': const RawTextInput('1500000'),
          'good_output': const RawTextInput('500'),
        }),
        explanation: '۱٬۵۰۰٬۰۰۰ ریال هزینهٔ تخصیص‌یافته و ۵۰۰ واحد سالم: ۳۰۰۰ ریال/واحد سالم.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'unit_production_cost',
            label: 'هزینهٔ تولید واحد',
            value: NumericResultValue(
              3000,
              unit: 'ریال/واحد سالم',
              display: NumberDisplay.decimal,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'unit_production_cost',
        nameFa: 'هزینهٔ تولید واحد',
        nameEn: 'Unit Production Cost',
        description:
            'هزینهٔ ساخت تخصیص‌یافته در بازه تقسیم بر خروجی سالم همان بازه.',
      ),
    ],
  );
  static final unitProductionCostRunner = CalculatorRunner(
    definition: unitProductionCost,
    engine: const UnitProductionCostEngine(),
  );
  static final wip = CalculatorDefinition(
    id: 'wip',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'موجودی در جریان ساخت — WIP',
    nameEn: 'Work In Process',
    aliases: ['قانون لیتل', 'Little Law', 'موجودی نیمه ساخته'],
    description: 'برآورد متوسط موجودی در جریان ساخت با قانون لیتل، از نرخ خروج و زمان جریان متوسط.',
    formulaLatex: r'L=\lambda W',
    assumptions: 'قانون لیتل برای میانگین‌های بلندمدت یک سیستم پایدار با مرز ثابت و داده‌های سازگار به‌کار می‌رود، نه موجودی لحظه‌ای. نرخ خروج و زمان حضور باید همهٔ واحدهای عبوری در همان مرز را پوشش دهند؛ ضایعات و مسیرهای خروج را سازگار حساب کنید. برای دورهٔ گذرا، رشد موجودی یا داده‌های ناهم‌مرز نتیجه تضمین‌شده نیست. نرخ بر ساعت و زمان بر ساعت است؛ دقیقه را پیش از ورود بر ۶۰ تقسیم کنید.',
    fields: [
      NumericFieldDefinition(
        id: 'throughput_rate',
        label: 'نرخ خروج متوسط هم‌مرز',
        unit: 'واحد/ساعت',
        defaultValue: 20,
        help: 'بزرگ‌تر از صفر؛ همهٔ واحدهای خروجی در مرز قانون لیتل، نه لزوماً فقط سالم‌ها.',
      ),
      NumericFieldDefinition(
        id: 'flow_time',
        label: 'متوسط زمان حضور در سیستم',
        unit: 'ساعت',
        defaultValue: 3,
        min: 0,
        help: 'نامنفی؛ شامل انتظار و پردازش در همان مرز. برای دقیقه، ابتدا بر ۶۰ تقسیم کنید.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'throughput_rate': const RawTextInput('20'),
          'flow_time': const RawTextInput('3'),
        }),
        explanation: 'نرخ متوسط ۲۰ واحد/ساعت و زمان حضور ۳ ساعت: WIP متوسط ۶۰ واحد، با فرض شرایط قانون لیتل.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'wip',
            label: 'موجودی در جریان ساخت — WIP',
            value: NumericResultValue(
              60,
              unit: 'واحد متوسط',
              display: NumberDisplay.decimal,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'wip',
        nameFa: 'موجودی در جریان ساخت — WIP',
        nameEn: 'Work In Process',
        description: 'برآورد متوسط موجودی در جریان ساخت با قانون لیتل، از نرخ خروج و زمان جریان متوسط.',
      ),
    ],
  );
  static final wipRunner = CalculatorRunner(
    definition: wip,
    engine: const WipEngine(),
  );
  static final throughput = CalculatorDefinition(
    id: 'throughput',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'نرخ خروجی — Throughput',
    nameEn: 'Throughput Rate',
    aliases: ['توان عملیاتی', 'نرخ تولید واقعی', 'خروجی در ساعت'],
    description: 'نرخ واقعی خروج واحد سالم در زمان تقویمی مشاهده، شامل توقف‌های همان بازه.',
    formulaLatex: r'TH_{good}=\frac{Q_{good}}{T_{elapsed}}',
    assumptions: 'در این ابزار Throughput نرخ تعدادی خروجی سالم است، نه throughput مالیِ حسابداری محدودیت‌ها. زمان مشاهده، زمان تقویمی همان بازه و شامل توقف است؛ ساعت کارکرد خالص جای آن ننویسید. مرز خروج محصول نهایی و واحد همگن را ثابت نگه دارید. برای استفاده در قانون لیتل ممکن است نرخ همهٔ خروجی‌ها، شامل مسیر ضایعات، لازم باشد؛ این نرخ سالم را کورکورانه جایگزین آن نکنید.',
    fields: [
      NumericFieldDefinition(
        id: 'good_output',
        label: 'خروجی سالم تکمیل‌شده',
        unit: 'واحد سالم',
        defaultValue: 240,
        min: 0,
        help: 'نامنفی، در مرز خروج ثابت و بدون دوباره‌شماری دوباره‌کاری.',
      ),
      NumericFieldDefinition(
        id: 'elapsed_time',
        label: 'مدت تقویمی مشاهده',
        unit: 'ساعت',
        defaultValue: 8,
        help: 'بزرگ‌تر از صفر؛ شامل توقف‌های همان بازه، نه فقط زمان کارکرد.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'good_output': const RawTextInput('240'),
          'elapsed_time': const RawTextInput('8'),
        }),
        explanation: '۲۴۰ واحد سالم در ۸ ساعت تقویمی شامل توقف: نرخ خروج سالم ۳۰ واحد/ساعت.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'throughput',
            label: 'نرخ خروجی — Throughput',
            value: NumericResultValue(
              30,
              unit: 'واحد سالم/ساعت',
              display: NumberDisplay.decimal,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'throughput',
        nameFa: 'نرخ خروجی — Throughput',
        nameEn: 'Throughput Rate',
        description: 'نرخ واقعی خروج واحد سالم در زمان تقویمی مشاهده، شامل توقف‌های همان بازه.',
      ),
    ],
  );
  static final throughputRunner = CalculatorRunner(
    definition: throughput,
    engine: const ThroughputEngine(),
  );
  static final capacityUtilization = CalculatorDefinition(
    id: 'capacity_utilization',
    categoryId: CalculatorCategoryId.production,
    nameFa: 'نرخ بهره‌برداری از ظرفیت',
    nameEn: 'Capacity Utilization',
    aliases: ['استفاده از ظرفیت', 'درصد بهره برداری', 'utilization rate'],
    description: 'نسبت خروجی واقعی به ظرفیت اسمی/طراحی در همان بازه و با مبنای تعدادی مشترک.',
    formulaLatex: r'U=\frac{Q_{actual}}{C_{design}}',
    assumptions: 'مخرج در این نسخه ظرفیت اسمی/طراحی است، نه ظرفیت مؤثر؛ اگر سازمان ظرفیت مؤثر به‌کار می‌برد نام شاخص و مبنا باید تغییر کند. صورت و مخرج باید بازه، واحد معادل و مبنای سالم/کل یکسان داشته باشند. این نسبت با درصد مشغول‌بودن زمانی ماشین یا OEE یکی نیست. بالاتر از ۱۰۰٪ قطع نمی‌شود؛ می‌تواند نشانهٔ اضافه‌کاری، تعریف ظرفیت یا دادهٔ ناسازگار باشد.',
    fields: [
      NumericFieldDefinition(
        id: 'actual_output',
        label: 'خروجی واقعی بازه',
        unit: 'واحد هم‌مبنا',
        defaultValue: 360,
        min: 0,
        help: 'نامنفی؛ مبنای سالم/کل و واحد باید دقیقاً با ظرفیت اسمی یکسان باشد.',
      ),
      NumericFieldDefinition(
        id: 'design_capacity',
        label: 'ظرفیت اسمی/طراحی همان بازه',
        unit: 'واحد هم‌مبنا',
        defaultValue: 480,
        help: 'بزرگ‌تر از صفر؛ نه ظرفیت مؤثر یا ساعت آماده‌به‌کار. با خروجی هم‌دوره باشد.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با مبنای مشخص',
        inputs: RawCalculatorInput({
          'actual_output': const RawTextInput('360'),
          'design_capacity': const RawTextInput('480'),
        }),
        explanation: '۳۶۰ واحد واقعی در برابر ظرفیت اسمی ۴۸۰ واحد همان بازه: بهره‌برداری ۷۵٪.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'capacity_utilization',
            label: 'نرخ بهره‌برداری از ظرفیت',
            value: NumericResultValue(
              0.75,
              unit: null,
              display: NumberDisplay.percentage,
            ),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'capacity_utilization',
        nameFa: 'نرخ بهره‌برداری از ظرفیت',
        nameEn: 'Capacity Utilization',
        description: 'نسبت خروجی واقعی به ظرفیت اسمی/طراحی در همان بازه و با مبنای تعدادی مشترک.',
      ),
    ],
  );
  static final capacityUtilizationRunner = CalculatorRunner(
    definition: capacityUtilization,
    engine: const CapacityUtilizationEngine(),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        PrototypeCalculators.oeeRunner,
        taktTimeRunner,
        productionCapacityRunner,
        laborProductivityRunner,
        cycleTimeRunner,
        smedRunner,
        unitProductionCostRunner,
        wipRunner,
        throughputRunner,
        capacityUtilizationRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((runner) => runner.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({
        for (final runner in runners) runner.definition.id: runner,
      });
}
