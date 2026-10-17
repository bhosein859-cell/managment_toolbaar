import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/inventory/abc_engine.dart';
import '../../features/calculators/domain/engines/inventory/days_inventory_engine.dart';
import '../../features/calculators/domain/engines/inventory/eoq_engine.dart';
import '../../features/calculators/domain/engines/inventory/inventory_holding_cost_engine.dart';
import '../../features/calculators/domain/engines/inventory/inventory_turnover_engine.dart';
import '../../features/calculators/domain/engines/inventory/reorder_interval_engine.dart';
import '../../features/calculators/domain/engines/inventory/rop_engine.dart';
import '../../features/calculators/domain/engines/inventory/safety_stock_engine.dart';

abstract final class InventoryCalculators {
  static final eoq = CalculatorDefinition(
    id: 'eoq',
    categoryId: CalculatorCategoryId.inventory,
    nameFa: 'مقدار اقتصادی سفارش — EOQ',
    nameEn: 'Economic Order Quantity',
    aliases: ['سفارش اقتصادی', 'مدل ویلسون'],
    description: 'مقدار بهینهٔ پیوستهٔ سفارش در مدل کلاسیک با تقاضای یکنواخت و هزینه‌های مثبت.',
    formulaLatex: r'Q^*=\sqrt{\frac{2DS}{H}}',
    assumptions: EoqEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'annual_demand',
        label: 'تقاضای سالانه',
        unit: 'واحد/سال',
        defaultValue: 10000,
        help: 'بزرگ‌تر از صفر و با سال مبنای H یکسان.',
      ),
      NumericFieldDefinition(
        id: 'order_cost',
        label: 'هزینهٔ ثابت هر سفارش',
        unit: 'ریال/سفارش',
        defaultValue: 100,
        help: 'بزرگ‌تر از صفر؛ مستقل از مقدار سفارش در این مدل.',
      ),
      NumericFieldDefinition(
        id: 'holding_cost',
        label: 'هزینهٔ سالانهٔ نگهداری هر واحد',
        unit: 'ریال/(واحد·سال)',
        defaultValue: 2,
        help: 'بزرگ‌تر از صفر؛ مبلغ هزینه است، نه درصد.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'annual_demand': const RawTextInput('10000'),
          'order_cost': const RawTextInput('100'),
          'holding_cost': const RawTextInput('2'),
        }),
        explanation: 'تقاضای سالانه ۱۰۰۰۰، هزینهٔ هر سفارش ۱۰۰ و نگهداری هر واحد در سال ۲ ریال: EOQ=۱۰۰۰ واحد؛ هزینهٔ مرتبط ۲۰۰۰ ریال/سال.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'eoq',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(1000, unit: 'واحد/سفارش'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'eoq',
        nameFa: 'مقدار اقتصادی سفارش — EOQ',
        nameEn: 'Economic Order Quantity',
        description: 'مقدار بهینهٔ پیوستهٔ سفارش در مدل کلاسیک با تقاضای یکنواخت و هزینه‌های مثبت.',
      ),
    ],
  );
  static final eoqRunner = CalculatorRunner(
    definition: eoq,
    engine: const EoqEngine(),
  );
  static final rop = CalculatorDefinition(
    id: 'rop',
    categoryId: CalculatorCategoryId.inventory,
    nameFa: 'نقطهٔ سفارش مجدد — ROP',
    nameEn: 'Reorder Point',
    aliases: ['نقطه سفارش', 'نقطه تجدید سفارش'],
    description:
        'تقاضای متوسط طی زمان تأمین به‌علاوهٔ ذخیرهٔ اطمینان ازپیش‌تعیین‌شده.',
    formulaLatex: r'ROP=\bar d L+SS',
    assumptions: RopEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'daily_demand',
        label: 'تقاضای متوسط روزانه',
        unit: 'واحد/روز',
        defaultValue: 40,
        min: 0,
        help: 'نامنفی؛ روز کاری یا تقویمی باید با زمان تأمین یکی باشد.',
      ),
      NumericFieldDefinition(
        id: 'lead_time',
        label: 'زمان تأمین',
        unit: 'روز',
        defaultValue: 5,
        min: 0,
        help: 'نامنفی و با مبنای روز تقاضا یکسان.',
      ),
      NumericFieldDefinition(
        id: 'safety_stock',
        label: 'ذخیرهٔ اطمینان انتخابی',
        unit: 'واحد',
        defaultValue: 50,
        min: 0,
        help: 'نامنفی و متناسب با تعریف خدمت/عدم‌قطعیت؛ خودکار محاسبه نمی‌شود.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'daily_demand': const RawTextInput('40'),
          'lead_time': const RawTextInput('5'),
          'safety_stock': const RawTextInput('50'),
        }),
        explanation:
            '۴۰ واحد/روز، ۵ روز تأمین و ۵۰ واحد ذخیرهٔ اطمینان: ROP=۲۵۰ واحد.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'rop',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(250, unit: 'واحد'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'rop',
        nameFa: 'نقطهٔ سفارش مجدد — ROP',
        nameEn: 'Reorder Point',
        description: 'تقاضای متوسط طی زمان تأمین به‌علاوهٔ ذخیرهٔ اطمینان ازپیش‌تعیین‌شده.',
      ),
    ],
  );
  static final ropRunner = CalculatorRunner(
    definition: rop,
    engine: const RopEngine(),
  );
  static final safetyStock = CalculatorDefinition(
    id: 'safety_stock',
    categoryId: CalculatorCategoryId.inventory,
    nameFa: 'ذخیرهٔ اطمینان آماری',
    nameEn: 'Safety Stock',
    aliases: ['موجودی اطمینان', 'ذخیره احتیاطی'],
    description: 'ذخیرهٔ اطمینان با تقریب نرمال و استقلال تقاضای روزانه و زمان تأمین؛ سطح خدمت چرخه‌ای.',
    formulaLatex: r'SS=z_p\sqrt{\bar L\sigma_d^2+\bar d^2\sigma_L^2}',
    assumptions: SafetyStockEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'mean_demand',
        label: 'میانگین تقاضای روزانه',
        unit: 'واحد/روز',
        defaultValue: 40,
        min: 0,
        help: 'نامنفی؛ با تعریف انحراف معیار روزانه یکسان.',
      ),
      NumericFieldDefinition(
        id: 'demand_sd',
        label: 'انحراف معیار تقاضای روزانه',
        unit: 'واحد/روز',
        defaultValue: 10,
        min: 0,
        help: 'نامنفی، مستقل از برآورد زمان تأمین؛ با میانگین صفر، انحراف معیار مثبت برای تقاضای نامنفی سازگار نیست.',
      ),
      NumericFieldDefinition(
        id: 'mean_lead',
        label: 'میانگین زمان تأمین',
        unit: 'روز',
        defaultValue: 4,
        min: 0,
        help: 'نامنفی؛ با روز کاری/تقویمی تقاضا یکسان.',
      ),
      NumericFieldDefinition(
        id: 'lead_sd',
        label: 'انحراف معیار زمان تأمین',
        unit: 'روز',
        defaultValue: 0,
        min: 0,
        help: 'نامنفی؛ برای تأمین ثابت صفر، نه میانگین زمان تأمین.',
      ),
      NumericFieldDefinition(
        id: 'service_level',
        label: 'سطح خدمت چرخه‌ای یک‌طرفه',
        unit: 'درصد',
        defaultValue: 95,
        min: 50.0,
        kind: NumericInputKind.percentage,
        help: 'از ۵۰٪ تا کمتر از ۱۰۰٪؛ نه نرخ تأمین کامل تقاضا (fill rate).',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'mean_demand': const RawTextInput('40'),
          'demand_sd': const RawTextInput('10'),
          'mean_lead': const RawTextInput('4'),
          'lead_sd': const RawTextInput('0'),
          'service_level': const RawTextInput('95'),
        }),
        explanation: 'تقاضای روزانه ۴۰ با انحراف معیار ۱۰، تأمین ثابت ۴ روز و خدمت چرخه‌ای ۹۵٪: SS≈۳۲٫۸۹۷۰۷۳ واحد؛ گردکردن سیاستی خودکار نیست.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'safety_stock',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(32.89707253902944, unit: 'واحد'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'safety_stock',
        nameFa: 'ذخیرهٔ اطمینان آماری',
        nameEn: 'Safety Stock',
        description: 'ذخیرهٔ اطمینان با تقریب نرمال و استقلال تقاضای روزانه و زمان تأمین؛ سطح خدمت چرخه‌ای.',
      ),
    ],
  );
  static final safetyStockRunner = CalculatorRunner(
    definition: safetyStock,
    engine: const SafetyStockEngine(),
  );
  static final abc = CalculatorDefinition(
    id: 'abc',
    categoryId: CalculatorCategoryId.inventory,
    nameFa: 'طبقه‌بندی ABC موجودی',
    nameEn: 'ABC Inventory Classification',
    aliases: ['تحلیل پارتو انبار', 'ارزش مصرف سالانه'],
    description:
        'رتبه‌بندی اقلام با ارزش مصرف سالانه و آستانه‌های تجمعی قابل تعیین.',
    formulaLatex: r'V_i=D_iC_i,\quad share_i=\frac{V_i}{\sum V_j}',
    assumptions: AbcEngine.basis,
    fields: [
      NumberListFieldDefinition(
        id: 'annual_quantities',
        label: 'مصرف سالانه به ترتیب قلم',
        unit: 'واحد/سال',
        minItems: 1,
        maxItems: 100,
        min: 0,
        defaultValue: [100, 100, 100, 100, 100],
        help: 'هر سطر یک SKU؛ دو فهرست باید هم‌ردیف و هم‌اندازه باشند. SKU-1 یعنی ردیف اول.',
      ),
      NumberListFieldDefinition(
        id: 'unit_costs',
        label: 'بهای واحد همان اقلام به همان ترتیب',
        unit: 'ریال/واحد',
        minItems: 1,
        maxItems: 100,
        min: 0,
        defaultValue: [70, 15, 8, 5, 2],
        help: 'نامنفی؛ ردیف k با مصرف ردیف k متناظر است، نه قیمت فروش یا ارزش موجودی لحظه‌ای.',
      ),
      NumericFieldDefinition(
        id: 'a_threshold',
        label: 'مرز تجمعی طبقهٔ A',
        unit: 'درصد',
        defaultValue: 80,
        kind: NumericInputKind.percentage,
        help: 'بیشتر از صفر و کمتر از ۱۰۰٪؛ قلم عبوردهندهٔ مرز در طبقهٔ بالاتر می‌ماند.',
      ),
      NumericFieldDefinition(
        id: 'b_threshold',
        label: 'مرز تجمعی A و B',
        unit: 'درصد',
        defaultValue: 95,
        max: 100,
        kind: NumericInputKind.percentage,
        help: 'بزرگ‌تر از مرز A و حداکثر ۱۰۰٪؛ این سیاست است، نه قانون ثابت کیفیت.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'annual_quantities': RawNumberListInput([
            '100',
            '100',
            '100',
            '100',
            '100',
          ]),
          'unit_costs': RawNumberListInput(['70', '15', '8', '5', '2']),
          'a_threshold': const RawTextInput('80'),
          'b_threshold': const RawTextInput('95'),
        }),
        explanation: 'ارزش‌های سالانه ۷۰۰۰، ۱۵۰۰، ۸۰۰، ۵۰۰، ۲۰۰ ریال و مرزهای ۸۰/۹۵٪: دو قلم A، دو قلم B و یک قلم C؛ قلم عبوردهندهٔ مرز در گروه بالاتر باقی می‌ماند.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'abc',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(10000, unit: 'ریال/سال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'abc',
        nameFa: 'طبقه‌بندی ABC موجودی',
        nameEn: 'ABC Inventory Classification',
        description: 'رتبه‌بندی اقلام با ارزش مصرف سالانه و آستانه‌های تجمعی قابل تعیین.',
      ),
    ],
  );
  static final abcRunner = CalculatorRunner(
    definition: abc,
    engine: const AbcEngine(),
  );
  static final inventoryTurnover = CalculatorDefinition(
    id: 'inventory_turnover',
    categoryId: CalculatorCategoryId.inventory,
    nameFa: 'نرخ گردش موجودی',
    nameEn: 'Inventory Turnover',
    aliases: ['گردش انبار'],
    description: 'بهای تمام‌شدهٔ کالای فروش‌رفتهٔ دوره نسبت به متوسط موجودی به بهای تمام‌شده.',
    formulaLatex: r'Turnover=\frac{COGS_{period}}{Inventory_{avg}}',
    assumptions: InventoryTurnoverEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'cogs',
        label: 'بهای تمام‌شدهٔ فروش دوره',
        unit: 'ریال/دوره',
        defaultValue: 1200000,
        min: 0,
        help: 'نامنفی؛ درآمد فروش را جایگزین نکنید.',
      ),
      NumericFieldDefinition(
        id: 'average_inventory',
        label: 'ارزش متوسط موجودی به بهای تمام‌شده',
        unit: 'ریال',
        defaultValue: 300000,
        help: 'بزرگ‌تر از صفر؛ با دوره و روش ارزش‌گذاری COGS یکسان.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'cogs': const RawTextInput('1200000'),
          'average_inventory': const RawTextInput('300000'),
        }),
        explanation: 'COGS دوره ۱۲۰۰۰۰۰ ریال و متوسط موجودی ۳۰۰۰۰۰: گردش ۴ بار در همان دوره.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'inventory_turnover',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(4, unit: 'بار/دوره'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'inventory_turnover',
        nameFa: 'نرخ گردش موجودی',
        nameEn: 'Inventory Turnover',
        description: 'بهای تمام‌شدهٔ کالای فروش‌رفتهٔ دوره نسبت به متوسط موجودی به بهای تمام‌شده.',
      ),
    ],
  );
  static final inventoryTurnoverRunner = CalculatorRunner(
    definition: inventoryTurnover,
    engine: const InventoryTurnoverEngine(),
  );
  static final daysInventory = CalculatorDefinition(
    id: 'days_inventory',
    categoryId: CalculatorCategoryId.inventory,
    nameFa: 'روزهای موجودی',
    nameEn: 'Days Inventory Outstanding',
    aliases: ['DIO', 'روزهای گردش موجودی'],
    description:
        'روزهای پوشش موجودی بر مبنای متوسط ارزش موجودی، COGS و طول دورهٔ صریح.',
    formulaLatex:
        r'DIO=\frac{Inventory_{avg}}{COGS_{period}}\times Days_{period}',
    assumptions: DaysInventoryEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'average_inventory',
        label: 'متوسط موجودی به بهای تمام‌شده',
        unit: 'ریال',
        defaultValue: 300000,
        min: 0,
        help: 'نامنفی؛ با روش ارزش‌گذاری و بازهٔ COGS یکسان.',
      ),
      NumericFieldDefinition(
        id: 'cogs',
        label: 'بهای تمام‌شدهٔ فروش همان دوره',
        unit: 'ریال/دوره',
        defaultValue: 1200000,
        help: 'بزرگ‌تر از صفر؛ فروش صفر به روزهای صفر تبدیل نمی‌شود.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'طول دورهٔ گزارش',
        unit: 'روز',
        defaultValue: 365,
        help: 'بزرگ‌تر از صفر؛ روزهای دوره را خودتان مطابق گزارش تعیین کنید.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'average_inventory': const RawTextInput('300000'),
          'cogs': const RawTextInput('1200000'),
          'period_days': const RawTextInput('365'),
        }),
        explanation: 'متوسط موجودی ۳۰۰۰۰۰، COGS برابر ۱۲۰۰۰۰۰ در دورهٔ ۳۶۵ روزه: DIO=۹۱٫۲۵ روز.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'days_inventory',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(91.25, unit: 'روز'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'days_inventory',
        nameFa: 'روزهای موجودی',
        nameEn: 'Days Inventory Outstanding',
        description: 'روزهای پوشش موجودی بر مبنای متوسط ارزش موجودی، COGS و طول دورهٔ صریح.',
      ),
    ],
  );
  static final daysInventoryRunner = CalculatorRunner(
    definition: daysInventory,
    engine: const DaysInventoryEngine(),
  );
  static final inventoryHoldingCost = CalculatorDefinition(
    id: 'inventory_holding_cost',
    categoryId: CalculatorCategoryId.inventory,
    nameFa: 'هزینهٔ نگهداری موجودی',
    nameEn: 'Inventory Holding Cost',
    aliases: ['هزینه حمل موجودی', 'carrying cost'],
    description:
        'هزینهٔ نگهداری برآوردی با نرخ سالانه و تخصیص خطی به روزهای دوره.',
    formulaLatex: r'HC=V_{avg} i_{annual}\frac{Days}{Days_{year}}',
    assumptions: InventoryHoldingCostEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'average_value',
        label: 'متوسط ارزش موجودی',
        unit: 'ریال',
        defaultValue: 1000000,
        min: 0,
        help: 'نامنفی و با مبنای نرخ هزینهٔ نگهداری مشترک.',
      ),
      NumericFieldDefinition(
        id: 'annual_rate',
        label: 'نرخ سالانهٔ هزینهٔ نگهداری',
        unit: 'درصد/سال',
        defaultValue: 20,
        min: 0,
        kind: NumericInputKind.percentage,
        help: 'نامنفی؛ اجزای نرخ و دوباره‌شماری را طبق روش سازمان مشخص کنید.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'روزهای دورهٔ هزینه',
        unit: 'روز',
        defaultValue: 90,
        min: 0,
        help: 'نامنفی؛ تخصیص خطی و هم‌مبنا با سال نرخ.',
      ),
      NumericFieldDefinition(
        id: 'year_days',
        label: 'تعداد روز مبنای سال',
        unit: 'روز/سال',
        defaultValue: 360,
        help: 'بزرگ‌تر از صفر؛ مثلاً ۳۶۰/۳۶۵ یا روزهای کاری با نرخ متناظر.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'average_value': const RawTextInput('1000000'),
          'annual_rate': const RawTextInput('20'),
          'period_days': const RawTextInput('90'),
          'year_days': const RawTextInput('360'),
        }),
        explanation: 'متوسط ارزش ۱۰۰۰۰۰۰ ریال، نرخ سالانه ۲۰٪، دوره ۹۰ روز از سال ۳۶۰روزه: هزینهٔ برآوردی ۵۰۰۰۰ ریال.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'inventory_holding_cost',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(50000, unit: 'ریال/دوره'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'inventory_holding_cost',
        nameFa: 'هزینهٔ نگهداری موجودی',
        nameEn: 'Inventory Holding Cost',
        description:
            'هزینهٔ نگهداری برآوردی با نرخ سالانه و تخصیص خطی به روزهای دوره.',
      ),
    ],
  );
  static final inventoryHoldingCostRunner = CalculatorRunner(
    definition: inventoryHoldingCost,
    engine: const InventoryHoldingCostEngine(),
  );
  static final reorderInterval = CalculatorDefinition(
    id: 'reorder_interval',
    categoryId: CalculatorCategoryId.inventory,
    nameFa: 'فاصلهٔ زمانی بازسفارش',
    nameEn: 'Reorder Interval',
    aliases: ['چرخه سفارش', 'فاصله سفارش مجدد'],
    description: 'فاصلهٔ متوسط چرخهٔ سفارش مقدار ثابت با تقاضای سالانهٔ ثابت و مبنای روز صریح.',
    formulaLatex: r'T=\frac{Q}{D_{annual}}Days_{year}',
    assumptions: ReorderIntervalEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'order_quantity',
        label: 'مقدار ثابت هر سفارش',
        unit: 'واحد/سفارش',
        defaultValue: 1000,
        help: 'بزرگ‌تر از صفر؛ مقدار واقعی سیاست یا خروجی پیوستهٔ بررسی‌شدهٔ EOQ.',
      ),
      NumericFieldDefinition(
        id: 'annual_demand',
        label: 'تقاضای سالانه',
        unit: 'واحد/سال',
        defaultValue: 12000,
        help: 'بزرگ‌تر از صفر؛ با سال و روزهای مبنا یکسان.',
      ),
      NumericFieldDefinition(
        id: 'year_days',
        label: 'روزهای مبنای سال',
        unit: 'روز/سال',
        defaultValue: 360,
        help: 'بزرگ‌تر از صفر؛ تقویمی یا کاری را مشخص و یکسان نگه دارید.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'order_quantity': const RawTextInput('1000'),
          'annual_demand': const RawTextInput('12000'),
          'year_days': const RawTextInput('360'),
        }),
        explanation: 'سفارش ۱۰۰۰ واحد، تقاضای سالانه ۱۲۰۰۰ واحد و مبنای ۳۶۰ روز: فاصلهٔ متوسط سفارش ۳۰ روز.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'reorder_interval',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(30, unit: 'روز/سفارش'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'reorder_interval',
        nameFa: 'فاصلهٔ زمانی بازسفارش',
        nameEn: 'Reorder Interval',
        description: 'فاصلهٔ متوسط چرخهٔ سفارش مقدار ثابت با تقاضای سالانهٔ ثابت و مبنای روز صریح.',
      ),
    ],
  );
  static final reorderIntervalRunner = CalculatorRunner(
    definition: reorderInterval,
    engine: const ReorderIntervalEngine(),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        eoqRunner,
        ropRunner,
        safetyStockRunner,
        abcRunner,
        inventoryTurnoverRunner,
        daysInventoryRunner,
        inventoryHoldingCostRunner,
        reorderIntervalRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((r) => r.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({for (final r in runners) r.definition.id: r});
}
