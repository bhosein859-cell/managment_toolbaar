import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/cp_engine.dart';
import '../../features/calculators/domain/engines/npv_engine.dart';
import '../../features/calculators/domain/engines/oee_engine.dart';

/// Definitions and stable runner identities; no formula execution in config.
abstract final class PrototypeCalculators {
  static final oee = CalculatorDefinition(
    id: 'oee',
    aliases: ['OEE', 'بهره‌وری تجهیزات', 'راندمان کلی تجهیزات'],
    categoryId: CalculatorCategoryId.production,
    nameFa: 'اثربخشی کلی تجهیزات — OEE',
    nameEn: 'Overall Equipment Effectiveness',
    description: 'حاصل‌ضرب دسترس‌پذیری، عملکرد و کیفیت برای یک تجهیز و یک بازهٔ زمانی مشترک.',
    formulaLatex: r'OEE = A \times P \times Q,\quad A,P,Q\in[0,1]',
    assumptions: 'فرمول با نسبت‌های صفر تا یک محاسبه می‌شود، اما فرم درصد می‌گیرد: برای نسبت ۰٫۹۰، عدد ۹۰ را وارد کنید. تعریف متعارف A زمان کارکرد/زمان تولید برنامه‌ریزی‌شده، P زمان سیکل ایده‌آل × تعداد کل/زمان کارکرد و Q تعداد سالم/تعداد کل است؛ این صفحه مؤلفه‌های محاسبه‌شده را می‌گیرد. همه باید یک بازه و مبنای یکسان داشته باشند. در این نمونه هر مؤلفه حداکثر ۱۰۰٪ است؛ مقدار بالاتر قطع یا اصلاح خودکار نمی‌شود و باید مبنای سرعت ایده‌آل و داده‌ها بررسی شود. مقایسه نیازمند تعریف و معیار مشترک است.',
    fields: [
      NumericFieldDefinition(
        id: 'availability',
        label: 'دسترس‌پذیری (Availability)',
        kind: NumericInputKind.percentage,
        min: 0,
        max: 100,
        defaultValue: 90,
        help: 'درصد زمان کارکرد از زمان تولید برنامه‌ریزی‌شده؛ ۹۰ یعنی نسبت ۰٫۹۰.',
      ),
      NumericFieldDefinition(
        id: 'performance',
        label: 'عملکرد (Performance)',
        kind: NumericInputKind.percentage,
        min: 0,
        max: 100,
        defaultValue: 95,
        help: 'درصد عملکرد نسبت به سرعت ایده‌آل تعریف‌شده؛ ۹۵ یعنی نسبت ۰٫۹۵.',
      ),
      NumericFieldDefinition(
        id: 'quality',
        label: 'کیفیت (Quality)',
        kind: NumericInputKind.percentage,
        min: 0,
        max: 100,
        defaultValue: 98,
        help: 'درصد تعداد سالم از تعداد کل تولید؛ ۹۸ یعنی نسبت ۰٫۹۸.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ سه مؤلفه',
        inputs: RawCalculatorInput({
          'availability': const RawTextInput('۹۰'),
          'performance': const RawTextInput('۹۵'),
          'quality': const RawTextInput('۹۸'),
        }),
        explanation: '\u2066۰٫۹۰ × ۰٫۹۵ × ۰٫۹۸ = ۰٫۸۳۷۹\u2069، یعنی ۸۳٫۷۹٪.',
        expectedResult: _expected('oee', 'OEE', 0.8379, percentage: true),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'oee',
        nameFa: 'اثربخشی کلی تجهیزات',
        nameEn: 'OEE',
        description: 'شاخص ترکیبی دسترس‌پذیری، عملکرد و کیفیت.',
      ),
    ],
  );

  static final npv = CalculatorDefinition(
    id: 'npv',
    aliases: ['NPV', 'ارزش خالص فعلی', 'خالص ارزش فعلی', 'تنزیل جریان نقدی'],
    categoryId: CalculatorCategoryId.finance,
    nameFa: 'ارزش فعلی خالص — NPV',
    nameEn: 'Net Present Value',
    description: 'تنزیل جریان‌های نقدی پایان دوره‌های برابر، با کسر سرمایه‌گذاری اولیه در زمان صفر.',
    formulaLatex: r'NPV = -I_0 + \sum_{t=1}^{n}\frac{CF_t}{(1+r)^t}',
    assumptions: 'I₀ یک مقدار نامنفی برای خروج وجه در زمان صفر است و دقیقاً یک بار کم می‌شود. فهرست فقط جریان‌های دورهٔ اول تا آخر را می‌گیرد: سطر اول پایان دورهٔ اول، نه زمان صفر. دوره‌ها باید هم‌طول باشند و نرخ مؤثر تنزیل مربوط به همان دوره، ثابت و بیشتر از منفی ۱۰۰٪ باشد؛ نرخ سالانه برای جریان ماهانه باید پیشاپیش به نرخ مؤثر ماهانه تبدیل شود. ورود جریان نقدی مثبت و خروج آن منفی است. واحد پول همهٔ مبالغ یکسان است و انتخاب ریال/تومان تبدیل خودکار انجام نمی‌دهد. جریان‌های نامنظم تاریخ‌دار (XNPV)، تبدیل نرخ اسمی، مالیات و تورم خودکار پشتیبانی نمی‌شوند؛ مبالغ اسمی/واقعی باید با نرخ سازگار باشند و ارزش اسقاط در جریان دورهٔ مربوط وارد شود. محاسبه با اعشار ممیز شناور است؛ علامت نتیجه‌های بسیار نزدیک صفر ممکن است از خطای گردکردن تأثیر بگیرد و نباید قطعی تفسیر شود. اعداد خارج از محدودهٔ امن محاسبات به‌جای نتیجهٔ ساختگی خطا می‌دهند. خروجی توصیهٔ سرمایه‌گذاری نیست.',
    fields: [
      NumericFieldDefinition(
        id: 'initial_investment',
        label: 'سرمایه‌گذاری اولیه در زمان صفر',
        min: 0,
        defaultValue: 1000,
        unit: 'واحد پول انتخابی',
        help: 'عدد نامنفی وارد کنید؛ موتور آن را به‌عنوان خروج وجه کم می‌کند.',
      ),
      NumericFieldDefinition(
        id: 'discount_rate',
        label: 'نرخ مؤثر تنزیل هر دوره',
        kind: NumericInputKind.percentage,
        defaultValue: 10,
        help: 'باید بیشتر از منفی ۱۰۰٪ باشد؛ مثلاً ۱۰ یعنی نرخ ۱۰٪ هر دوره. خودِ منفی ۱۰۰٪ مجاز نیست.',
      ),
      NumberListFieldDefinition(
        id: 'cash_flows',
        label: 'جریان‌های نقدی پایان دوره‌ها',
        unit: 'واحد پول انتخابی',
        defaultValue: [600, 600],
        maxItems: 1000,
        help: 'هر دوره یک سطر؛ اولین سطر پایان دورهٔ اول. جریان منفی مجاز است؛ سرمایهٔ زمان صفر را اینجا تکرار نکنید.',
      ),
      ChoiceFieldDefinition(
        id: 'money_unit',
        label: 'واحد پول مشترک',
        defaultValue: 'rial',
        options: [
          ChoiceOption(id: 'rial', label: 'ریال'),
          ChoiceOption(id: 'toman', label: 'تومان'),
        ],
        help: 'انتخاب فقط برچسب خروجی است؛ هیچ تبدیل پول یا نرخ زنده‌ای انجام نمی‌شود.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'دو جریان در پایان دو دوره',
        inputs: RawCalculatorInput({
          'initial_investment': const RawTextInput('۱۰۰۰'),
          'discount_rate': const RawTextInput('۱۰'),
          'cash_flows': RawNumberListInput(['۶۰۰', '۶۰۰']),
          'money_unit': const RawTextInput('rial'),
        }),
        explanation: '\u2066−۱۰۰۰ + ۶۰۰/۱٫۱ + ۶۰۰/۱٫۲۱ ≈ ۴۱٫۳۲۲۳۱۴\u2069 ریال. دوره‌ها برابر و نرخ ۱۰٪ برای هر دوره است.',
        expectedResult: _expected(
          'npv',
          'NPV',
          41.322314049586566,
          unit: 'ریال',
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'discount_rate',
        nameFa: 'نرخ تنزیل',
        nameEn: 'Discount rate',
        description:
            'نرخ مؤثر هر دوره برای تبدیل جریان آینده به ارزش زمان صفر.',
      ),
    ],
  );

  static final cp = CalculatorDefinition(
    id: 'cp',
    aliases: ['Cp', 'قابلیت فرایند', 'توانمندی فرایند', 'Process capability'],
    categoryId: CalculatorCategoryId.quality,
    nameFa: 'قابلیت بالقوهٔ فرایند — Cp',
    nameEn: 'Process Capability Index',
    description: 'نسبت عرض حدود مشخصات به شش برابر انحراف معیار درون‌فرایندی؛ نتیجه بدون واحد است.',
    formulaLatex: r'C_p = \frac{USL-LSL}{6\sigma_w}',
    assumptions: 'USL و LSL حدود مشخصات مهندسی/مشتری‌اند، نه حدود کنترل آماری یا بیشینه و کمینهٔ نمونه. USL باید بزرگ‌تر از LSL و σw مثبت باشد؛ هر سه مقدار باید در یک واحد باشند. برآورد سیگما باید معتبر و درون‌زیرگروهی/درون‌فرایندی باشد؛ این ابزار از حدود مشخصات سیگما تخمین نمی‌زند و روش برآورد را انتخاب نمی‌کند. تفسیر متعارف به فرایند پایدار و توزیع تقریباً نرمال وابسته است؛ برای داده‌های غیرنرمال تحلیل مناسب لازم است. Cp مرکزیت فرایند را لحاظ نمی‌کند، نرخ عیب یا احتمال قبولی قطعی نمی‌دهد و جایگزین Cpk یا شاخص Pp با سیگمای کلی نیست. انتخاب واحد تبدیل انجام نمی‌دهد. بدون معیار سازمانی/قراردادی، خوب یا بد اعلام نمی‌شود.',
    fields: [
      NumericFieldDefinition(
        id: 'usl',
        label: 'حد بالای مشخصات (USL)',
        unit: 'واحد مشترک',
        defaultValue: 110,
        help: 'حد بالای مجاز مشخصه؛ باید از حد پایین بزرگ‌تر باشد.',
      ),
      NumericFieldDefinition(
        id: 'lsl',
        label: 'حد پایین مشخصات (LSL)',
        unit: 'واحد مشترک',
        defaultValue: 90,
        help: 'حد پایین مجاز مشخصه؛ مقدار منفی در صورت سازگاری واحد مجاز است.',
      ),
      NumericFieldDefinition(
        id: 'sigma',
        label: 'سیگمای درون‌فرایندی (σw)',
        unit: 'واحد مشترک',
        defaultValue: 2,
        help: 'انحراف معیار معتبر و بزرگ‌تر از صفر؛ از سیگمای کلی به‌جای آن استفاده نکنید مگر روش را آگاهانه تغییر دهید.',
      ),
      ChoiceFieldDefinition(
        id: 'measurement_unit',
        label: 'واحد مشترک اندازه‌گیری',
        defaultValue: 'mm',
        options: [
          ChoiceOption(id: 'mm', label: 'میلی‌متر (mm)'),
          ChoiceOption(id: 'cm', label: 'سانتی‌متر (cm)'),
          ChoiceOption(id: 'seconds', label: 'ثانیه (s)'),
          ChoiceOption(id: 'generic', label: 'واحد مشترک دلخواه'),
        ],
        help:
            'واحد فقط برچسب است؛ حدود و سیگما را همگی با همان واحد وارد کنید.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'عرض مشخصات برابر شش سیگما',
        inputs: RawCalculatorInput({
          'usl': const RawTextInput('۱۰'),
          'lsl': const RawTextInput('۴'),
          'sigma': const RawTextInput('۱'),
          'measurement_unit': const RawTextInput('mm'),
        }),
        explanation: '\u2066(۱۰ − ۴) / (۶ × ۱) = ۱\u2069. این برابری به‌تنهایی نشان‌دهندهٔ قبول یا رد فرایند نیست.',
        expectedResult: _expected('cp', 'Cp', 1),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'within_sigma',
        nameFa: 'سیگمای درون‌فرایندی',
        nameEn: 'Within-process sigma',
        description: 'برآورد پراکندگی کوتاه‌مدت با روش زیرگروه‌بندی معتبر؛ روش برآورد باید مستند باشد.',
      ),
    ],
  );

  static final oeeRunner = CalculatorRunner(
    definition: oee,
    engine: const OeeEngine(),
  );
  static final npvRunner = CalculatorRunner(
    definition: npv,
    engine: const NpvEngine(),
  );
  static final cpRunner = CalculatorRunner(
    definition: cp,
    engine: const CpEngine(),
  );

  static CalculationResult _expected(
    String id,
    String label,
    double value, {
    bool percentage = false,
    String? unit,
  }) => CalculationResult(
    primary: ResultMetric(
      id: id,
      label: label,
      value: NumericResultValue(
        value,
        unit: unit,
        display: percentage ? NumberDisplay.percentage : NumberDisplay.decimal,
      ),
    ),
  );
}
