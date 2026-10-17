import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/finance/break_even_engine.dart';
import '../../features/calculators/domain/engines/finance/compound_interest_engine.dart';
import '../../features/calculators/domain/engines/finance/current_ratio_engine.dart';
import '../../features/calculators/domain/engines/finance/irr_engine.dart';
import '../../features/calculators/domain/engines/finance/loan_payment_engine.dart';
import '../../features/calculators/domain/engines/finance/payback_engine.dart';
import '../../features/calculators/domain/engines/finance/quick_ratio_engine.dart';
import '../../features/calculators/domain/engines/finance/roi_engine.dart';
import '../../features/calculators/domain/engines/finance/wacc_engine.dart';
import 'prototype_calculators.dart';

/// Ten finance tools, preserving the original NPV definition and engine.
abstract final class FinanceCalculators {
  static final irr = CalculatorDefinition(
    id: 'irr',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'نرخ بازده داخلی — IRR',
    nameEn: 'Internal Rate of Return',
    aliases: ['بازده داخلی', 'نرخ داخلی بازگشت'],
    description: 'حل محافظه‌کارانهٔ نرخ مؤثر هر دوره با CF0 زمان صفر؛ فقط سری با یک تغییر علامت.',
    formulaLatex: r'0=\sum_{t=0}^{n}\frac{CF_t}{(1+r)^t},\quad r>-1',
    assumptions: IrrEngine.basis,
    fields: [
      NumberListFieldDefinition(
        id: 'cash_flows',
        label: 'جریان نقدی از CF0 تا CFn',
        unit: 'ریال',
        minItems: 2,
        maxItems: 1000,
        defaultValue: [-1000, 600, 600],
        help: 'سطر اول CF0 در زمان صفر، معمولاً سرمایه‌گذاری منفی؛ سطرهای بعد پایان دوره‌های مساوی. ورود مثبت و خروج منفی؛ CF0 غیرصفر. برخلاف فهرست NPV، CF0 را اینجا حتماً وارد کنید. فقط یک تغییر علامت پشتیبانی می‌شود.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال دو دورهٔ مساوی',
        inputs: RawCalculatorInput({
          'cash_flows': RawNumberListInput(['-1000', '600', '600']),
        }),
        explanation: 'خروج ۱۰۰۰ در زمان صفر و ورود ۶۰۰ در پایان هر یک از دو دوره: IRR حدود ۱۳٫۰۶۶۲۳۹٪ در هر دوره است؛ نرخ سالانه فقط وقتی دوره سالانه باشد.',
        expectedResult: _expected('irr', 0.1306623862918075, percentage: true),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'irr',
        nameFa: 'نرخ بازده داخلی',
        nameEn: 'IRR',
        description: 'ریشهٔ معادلهٔ NPV صفر با زمان‌بندی و دامنهٔ نرخ مشخص؛ نه توصیهٔ سرمایه‌گذاری.',
      ),
    ],
  );
  static final irrRunner = CalculatorRunner(
    definition: irr,
    engine: const IrrEngine(),
  );
  static final payback = CalculatorDefinition(
    id: 'payback',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'دورهٔ بازگشت سرمایه',
    nameEn: 'Simple Payback Period',
    aliases: ['بازگشت ساده', 'دوره بازیافت سرمایه'],
    description: 'بازگشت سادهٔ بدون تنزیل، با جریان خالص نامنفی و فرض یکنواختی دریافت برای بخش کسری دوره.',
    formulaLatex: r'PB=k+\frac{I_0-\sum_{t=1}^{k}CF_t}{CF_{k+1}}',
    assumptions: PaybackEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'initial_investment',
        label: 'سرمایه‌گذاری اولیه در زمان صفر',
        unit: 'ریال',
        min: 0,
        defaultValue: 1000,
        help: 'خروج وجه نامنفی زمان صفر؛ در فهرست جریان‌ها تکرار نکنید. صفر یعنی بازگشت در زمان صفر.',
      ),
      NumberListFieldDefinition(
        id: 'cash_flows',
        label: 'جریان خالص دوره‌های بعد',
        unit: 'ریال/دوره',
        min: 0,
        minItems: 1,
        maxItems: 1000,
        defaultValue: [300, 400, 500],
        help: 'بدون CF0؛ هر سطر یک دورهٔ مساوی. فقط جریان نامنفی، بدون تنزیل. برای کسر دوره، دریافت یکنواخت درون دوره فرض شده است.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال دریافت یکنواخت هر دوره',
        inputs: RawCalculatorInput({
          'initial_investment': const RawTextInput('1000'),
          'cash_flows': RawNumberListInput(['300', '400', '500']),
        }),
        explanation: 'پس از دو دوره ۷۰۰ ریال بازگشته؛ ۳۰۰ ریال باقی‌مانده از جریان ۵۰۰ دورهٔ سوم، ۰٫۶ دوره می‌خواهد: جمعاً ۲٫۶ دوره. اگر پرداخت‌ها فقط انتهای دوره باشند، پایان دورهٔ سوم.',
        expectedResult: _expected('payback', 2.6, unit: 'دوره'),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'payback',
        nameFa: 'بازگشت ساده',
        nameEn: 'Payback',
        description:
            'زمان بازیافت اصل در افق واردشده؛ نه ارزش فعلی یا سودآوری کل.',
      ),
    ],
  );
  static final paybackRunner = CalculatorRunner(
    definition: payback,
    engine: const PaybackEngine(),
  );
  static final roi = CalculatorDefinition(
    id: 'roi',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'بازده سرمایه‌گذاری — ROI',
    nameEn: 'Return on Investment',
    aliases: ['نرخ بازده ساده', 'بازده سرمایه'],
    description: 'بازده سادهٔ سود خالص نسبت به هزینهٔ سرمایه‌گذاری؛ بدون سالانه‌سازی یا لحاظ زمان دریافت‌ها.',
    formulaLatex: r'ROI=\frac{Profit_{net}}{Investment}',
    assumptions: RoiEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'net_profit',
        label: 'سود یا زیان خالص متناظر',
        unit: 'ریال',
        defaultValue: 200,
        help: 'سود پس از کسر کل هزینه‌ها و بهای سرمایه‌گذاری؛ زیان منفی مجاز است.',
      ),
      NumericFieldDefinition(
        id: 'investment',
        label: 'کل هزینهٔ سرمایه‌گذاری',
        unit: 'ریال',
        defaultValue: 1000,
        help: 'هزینهٔ مثبت متناظر؛ بزرگ‌تر از صفر.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی آموزشی',
        inputs: RawCalculatorInput({
          'net_profit': const RawTextInput('200'),
          'investment': const RawTextInput('1000'),
        }),
        explanation: '۲۰۰ ریال سود خالص پس از همهٔ هزینه‌ها برای ۱۰۰۰ ریال سرمایه‌گذاری: ROI برابر ۲۰٪ است.',
        expectedResult: _expected('roi', 0.2, unit: null, percentage: true),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'roi',
        nameFa: 'بازده سرمایه‌گذاری — ROI',
        nameEn: 'Return on Investment',
        description: 'بازده سادهٔ سود خالص نسبت به هزینهٔ سرمایه‌گذاری؛ بدون سالانه‌سازی یا لحاظ زمان دریافت‌ها.',
      ),
    ],
  );
  static final roiRunner = CalculatorRunner(
    definition: roi,
    engine: const RoiEngine(),
  );
  static final currentRatio = CalculatorDefinition(
    id: 'current_ratio',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'نسبت جاری',
    nameEn: 'Current Ratio',
    aliases: ['نقدینگی جاری'],
    description: 'نسبت دارایی جاری به بدهی جاری بر اساس یک تاریخ و طبقه‌بندی حسابداری مشترک.',
    formulaLatex: r'CR=\frac{Assets_{current}}{Liabilities_{current}}',
    assumptions: CurrentRatioEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'current_assets',
        label: 'دارایی جاری',
        unit: 'ریال',
        defaultValue: 400,
        min: 0,
        help: 'نامنفی؛ طبقه‌بندی جاری و تاریخ گزارش با بدهی یکسان باشد.',
      ),
      NumericFieldDefinition(
        id: 'current_liabilities',
        label: 'بدهی جاری',
        unit: 'ریال',
        defaultValue: 200,
        help: 'بزرگ‌تر از صفر؛ بدهی صفر نسبت متناهی تعریف نمی‌کند.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی آموزشی',
        inputs: RawCalculatorInput({
          'current_assets': const RawTextInput('400'),
          'current_liabilities': const RawTextInput('200'),
        }),
        explanation: '۴۰۰ ریال دارایی جاری و ۲۰۰ ریال بدهی جاری در یک تاریخ: نسبت جاری ۲ برابر است.',
        expectedResult: _expected(
          'current_ratio',
          2,
          unit: 'برابر',
          percentage: false,
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'current_ratio',
        nameFa: 'نسبت جاری',
        nameEn: 'Current Ratio',
        description: 'نسبت دارایی جاری به بدهی جاری بر اساس یک تاریخ و طبقه‌بندی حسابداری مشترک.',
      ),
    ],
  );
  static final currentRatioRunner = CalculatorRunner(
    definition: currentRatio,
    engine: const CurrentRatioEngine(),
  );
  static final quickRatio = CalculatorDefinition(
    id: 'quick_ratio',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'نسبت آنی',
    nameEn: 'Quick Ratio',
    aliases: ['نسبت سریع', 'آزمون اسید', 'acid test'],
    description: 'نسبت دارایی جاری پس از حذف موجودی و پیش‌پرداخت به بدهی جاری؛ با تعریف مشخص دارایی سریع.',
    formulaLatex: r'QR=\frac{CA-Inventory-Prepayments}{CL}',
    assumptions: QuickRatioEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'current_assets',
        label: 'دارایی جاری کل',
        unit: 'ریال',
        defaultValue: 500,
        min: 0,
        help: 'نامنفی، شامل موجودی و پیش‌پرداخت همین گزارش.',
      ),
      NumericFieldDefinition(
        id: 'inventory',
        label: 'موجودی داخل دارایی جاری',
        unit: 'ریال',
        defaultValue: 100,
        min: 0,
        help: 'نامنفی؛ با پیش‌پرداخت هم‌پوشانی نداشته باشد.',
      ),
      NumericFieldDefinition(
        id: 'prepayments',
        label: 'پیش‌پرداخت داخل دارایی جاری',
        unit: 'ریال',
        defaultValue: 20,
        min: 0,
        help: 'نامنفی؛ موجودی و پیش‌پرداخت روی هم نباید از دارایی جاری بیشتر شوند.',
      ),
      NumericFieldDefinition(
        id: 'current_liabilities',
        label: 'بدهی جاری همان تاریخ',
        unit: 'ریال',
        defaultValue: 200,
        help: 'بزرگ‌تر از صفر، در همان واحد پول و تاریخ.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی آموزشی',
        inputs: RawCalculatorInput({
          'current_assets': const RawTextInput('500'),
          'inventory': const RawTextInput('100'),
          'prepayments': const RawTextInput('20'),
          'current_liabilities': const RawTextInput('200'),
        }),
        explanation: 'دارایی جاری ۵۰۰، موجودی ۱۰۰، پیش‌پرداخت ۲۰ و بدهی جاری ۲۰۰ ریال: دارایی سریع ۳۸۰ و نسبت آنی ۱٫۹ برابر است.',
        expectedResult: _expected(
          'quick_ratio',
          1.9,
          unit: 'برابر',
          percentage: false,
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'quick_ratio',
        nameFa: 'نسبت آنی',
        nameEn: 'Quick Ratio',
        description: 'نسبت دارایی جاری پس از حذف موجودی و پیش‌پرداخت به بدهی جاری؛ با تعریف مشخص دارایی سریع.',
      ),
    ],
  );
  static final quickRatioRunner = CalculatorRunner(
    definition: quickRatio,
    engine: const QuickRatioEngine(),
  );
  static final wacc = CalculatorDefinition(
    id: 'wacc',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'میانگین موزون هزینهٔ سرمایه — WACC',
    nameEn: 'Weighted Average Cost of Capital',
    aliases: ['هزینه سرمایه موزون'],
    description: 'میانگین موزون هزینهٔ حقوق صاحبان سهام و بدهی، با سپر مالیاتی سادهٔ بهره.',
    formulaLatex: r'WACC=\frac{E}{D+E}R_e+\frac{D}{D+E}R_d(1-T)',
    assumptions: WaccEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'equity',
        label: 'ارزش بازار حقوق صاحبان سهام',
        unit: 'ریال',
        defaultValue: 600,
        min: 0,
        help: 'نامنفی؛ مجموع بدهی و حقوق صاحبان سهام باید مثبت باشد.',
      ),
      NumericFieldDefinition(
        id: 'debt',
        label: 'ارزش بازار بدهی',
        unit: 'ریال',
        defaultValue: 400,
        min: 0,
        help: 'نامنفی و هم‌تاریخ/هم‌ارز با حقوق صاحبان سهام.',
      ),
      NumericFieldDefinition(
        id: 'equity_cost',
        label: 'نرخ هزینهٔ حقوق صاحبان سهام',
        unit: 'درصد هر دوره',
        defaultValue: 12,
        min: 0,
        kind: NumericInputKind.percentage,
        help: 'نامنفی و با دورهٔ نرخ بدهی یکسان؛ ۱۲ یعنی ۱۲٪.',
      ),
      NumericFieldDefinition(
        id: 'debt_cost',
        label: 'نرخ هزینهٔ بدهی پیش از مالیات',
        unit: 'درصد هر دوره',
        defaultValue: 8,
        min: 0,
        kind: NumericInputKind.percentage,
        help: 'نامنفی و پیش از مالیات؛ با همان مبنای دوره/ارز.',
      ),
      NumericFieldDefinition(
        id: 'tax_rate',
        label: 'نرخ مؤثر مالیات شرکت',
        unit: 'درصد',
        defaultValue: 25,
        min: 0,
        max: 100,
        kind: NumericInputKind.percentage,
        help:
            'بین صفر و صد درصد؛ سپر مالیاتی کامل بهره در این مدل فرض شده است.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی آموزشی',
        inputs: RawCalculatorInput({
          'equity': const RawTextInput('600'),
          'debt': const RawTextInput('400'),
          'equity_cost': const RawTextInput('12'),
          'debt_cost': const RawTextInput('8'),
          'tax_rate': const RawTextInput('25'),
        }),
        explanation: 'حقوق صاحبان سهام ۶۰۰، بدهی ۴۰۰، هزینه‌ها ۱۲٪ و ۸٪، مالیات ۲۵٪: WACC برابر ۹٫۶٪ است.',
        expectedResult: _expected('wacc', 0.096, unit: null, percentage: true),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'wacc',
        nameFa: 'میانگین موزون هزینهٔ سرمایه — WACC',
        nameEn: 'Weighted Average Cost of Capital',
        description: 'میانگین موزون هزینهٔ حقوق صاحبان سهام و بدهی، با سپر مالیاتی سادهٔ بهره.',
      ),
    ],
  );
  static final waccRunner = CalculatorRunner(
    definition: wacc,
    engine: const WaccEngine(),
  );
  static final compoundInterest = CalculatorDefinition(
    id: 'compound_interest',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'سود مرکب',
    nameEn: 'Compound Interest',
    aliases: ['ارزش آتی', 'Future Value'],
    description: 'ارزش آتی اصل پول با نرخ مؤثر ثابت هر دوره و سرمایه‌گذاری مجدد؛ بدون واریز یا برداشت میان‌دوره‌ای.',
    formulaLatex: r'FV=P(1+r)^n,\quad I=FV-P',
    assumptions: CompoundInterestEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'principal',
        label: 'اصل پول',
        unit: 'ریال',
        defaultValue: 1000,
        min: 0,
        help: 'نامنفی؛ همهٔ مبالغ ریال‌اند.',
      ),
      NumericFieldDefinition(
        id: 'period_rate',
        label: 'نرخ مؤثر ثابت هر دوره',
        unit: 'درصد هر دوره',
        defaultValue: 10,
        kind: NumericInputKind.percentage,
        help: 'بیشتر از منفی ۱۰۰٪؛ دورهٔ نرخ و تعداد دوره‌ها باید یکسان باشد.',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های کامل',
        unit: 'دوره',
        defaultValue: 2,
        min: 0,
        max: 1000000,
        integerOnly: true,
        help: 'عدد صحیح از صفر تا یک میلیون؛ دورهٔ صفر یعنی همان اصل پول.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی آموزشی',
        inputs: RawCalculatorInput({
          'principal': const RawTextInput('1000'),
          'period_rate': const RawTextInput('10'),
          'periods': const RawTextInput('2'),
        }),
        explanation: '۱۰۰۰ ریال با نرخ مؤثر ۱۰٪ در هر دوره برای ۲ دوره: ارزش آتی ۱۲۱۰ و سود انباشته ۲۱۰ ریال.',
        expectedResult: _expected(
          'compound_interest',
          1210,
          unit: 'ریال',
          percentage: false,
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'compound_interest',
        nameFa: 'سود مرکب',
        nameEn: 'Compound Interest',
        description: 'ارزش آتی اصل پول با نرخ مؤثر ثابت هر دوره و سرمایه‌گذاری مجدد؛ بدون واریز یا برداشت میان‌دوره‌ای.',
      ),
    ],
  );
  static final compoundInterestRunner = CalculatorRunner(
    definition: compoundInterest,
    engine: const CompoundInterestEngine(),
  );
  static final loanPayment = CalculatorDefinition(
    id: 'loan_payment',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'قسط ثابت وام',
    nameEn: 'Loan Payment',
    aliases: ['اقساط وام', 'PMT', 'وام مستهلک شونده'],
    description: 'قسط ثابت وام کاملاً مستهلک‌شونده با پرداخت پایان هر دوره و نرخ مؤثر ثابت همان دوره.',
    formulaLatex: r'A=\frac{Pr}{1-(1+r)^{-n}},\quad r=0:\ A=P/n',
    assumptions: LoanPaymentEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'principal',
        label: 'اصل وام',
        unit: 'ریال',
        defaultValue: 1000,
        min: 0,
        help: 'نامنفی؛ بدون افزودن خودکار کارمزد یا بیمه.',
      ),
      NumericFieldDefinition(
        id: 'period_rate',
        label: 'نرخ مؤثر هر فاصلهٔ پرداخت',
        unit: 'درصد هر قسط',
        defaultValue: 1,
        min: 0,
        kind: NumericInputKind.percentage,
        help: 'نامنفی؛ برای اقساط ماهانه نرخ مؤثر ماهانه لازم است، نه عدد سالانه.',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد اقساط پایان دوره',
        unit: 'قسط',
        defaultValue: 12,
        max: 1000000,
        integerOnly: true,
        help:
            'عدد صحیح مثبت تا یک میلیون؛ مدل قسط پایان دوره و بدون بالون است.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی آموزشی',
        inputs: RawCalculatorInput({
          'principal': const RawTextInput('1000'),
          'period_rate': const RawTextInput('1'),
          'periods': const RawTextInput('12'),
        }),
        explanation: 'اصل وام ۱۰۰۰ ریال، نرخ مؤثر هر قسط ۱٪ و ۱۲ قسط پایان دوره: هر قسط حدود ۸۸٫۸۴۸۷۸۹ ریال؛ بدون گردکردن قراردادی.',
        expectedResult: _expected(
          'loan_payment',
          88.8487886783417,
          unit: 'ریال/قسط',
          percentage: false,
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'loan_payment',
        nameFa: 'قسط ثابت وام',
        nameEn: 'Loan Payment',
        description: 'قسط ثابت وام کاملاً مستهلک‌شونده با پرداخت پایان هر دوره و نرخ مؤثر ثابت همان دوره.',
      ),
    ],
  );
  static final loanPaymentRunner = CalculatorRunner(
    definition: loanPayment,
    engine: const LoanPaymentEngine(),
  );
  static final breakEven = CalculatorDefinition(
    id: 'break_even',
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'نقطهٔ سربه‌سر',
    nameEn: 'Break Even Point',
    aliases: ['حداقل فروش سربه سر', 'BEP'],
    description: 'مقدار فروش سربه‌سر تک‌محصولی با قیمت و هزینهٔ متغیر ثابت و حاشیهٔ مشارکت مثبت.',
    formulaLatex: r'Q_{BE}=\frac{F}{P-v},\quad P>v',
    assumptions: BreakEvenEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'fixed_cost',
        label: 'هزینهٔ ثابت بازه',
        unit: 'ریال',
        defaultValue: 1000,
        min: 0,
        help: 'نامنفی و مربوط به همان افق فروش.',
      ),
      NumericFieldDefinition(
        id: 'unit_price',
        label: 'قیمت فروش هر واحد',
        unit: 'ریال/واحد',
        defaultValue: 10,
        help: 'بزرگ‌تر از صفر و بزرگ‌تر از هزینهٔ متغیر هر واحد.',
      ),
      NumericFieldDefinition(
        id: 'variable_cost',
        label: 'هزینهٔ متغیر هر واحد',
        unit: 'ریال/واحد',
        defaultValue: 6,
        min: 0,
        help: 'نامنفی؛ تعریف واحد و بازه با قیمت و هزینهٔ ثابت یکسان باشد.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی آموزشی',
        inputs: RawCalculatorInput({
          'fixed_cost': const RawTextInput('1000'),
          'unit_price': const RawTextInput('10'),
          'variable_cost': const RawTextInput('6'),
        }),
        explanation: 'هزینهٔ ثابت ۱۰۰۰ ریال، قیمت ۱۰ و هزینهٔ متغیر ۶ ریال/واحد: سربه‌سر ۲۵۰ واحد و درآمد ۲۵۰۰ ریال.',
        expectedResult: _expected(
          'break_even',
          250,
          unit: 'واحد',
          percentage: false,
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'break_even',
        nameFa: 'نقطهٔ سربه‌سر',
        nameEn: 'Break Even Point',
        description: 'مقدار فروش سربه‌سر تک‌محصولی با قیمت و هزینهٔ متغیر ثابت و حاشیهٔ مشارکت مثبت.',
      ),
    ],
  );
  static final breakEvenRunner = CalculatorRunner(
    definition: breakEven,
    engine: const BreakEvenEngine(),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        PrototypeCalculators.npvRunner,
        irrRunner,
        paybackRunner,
        roiRunner,
        currentRatioRunner,
        quickRatioRunner,
        waccRunner,
        compoundInterestRunner,
        loanPaymentRunner,
        breakEvenRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((r) => r.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({for (final r in runners) r.definition.id: r});
  static CalculationResult _expected(
    String id,
    double value, {
    String? unit,
    bool percentage = false,
  }) => CalculationResult(
    primary: ResultMetric(
      id: id,
      label: 'نتیجهٔ مرجع',
      value: NumericResultValue(
        value,
        unit: unit,
        display: percentage ? NumberDisplay.percentage : NumberDisplay.decimal,
      ),
    ),
  );
}
