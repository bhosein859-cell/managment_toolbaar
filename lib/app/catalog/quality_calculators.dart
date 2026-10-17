import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/quality/coq_engine.dart';
import '../../features/calculators/domain/engines/quality/cpk_engine.dart';
import '../../features/calculators/domain/engines/quality/dpmo_engine.dart';
import '../../features/calculators/domain/engines/quality/pp_engine.dart';
import '../../features/calculators/domain/engines/quality/ppk_engine.dart';
import '../../features/calculators/domain/engines/quality/sigma_level_engine.dart';
import '../../features/calculators/domain/engines/quality/xbar_control_engine.dart';
import 'prototype_calculators.dart';

abstract final class QualityCalculators {
  static final cpk = CalculatorDefinition(
    id: 'cpk',
    categoryId: CalculatorCategoryId.quality,
    nameFa: 'قابلیت مرکزدار — Cpk',
    nameEn: 'Process Capability Index Cpk',
    aliases: ['قابلیت فرایند مرکزدار'],
    description: 'شاخص مرکزدار با انحراف معیار درون‌زیرگروهی',
    formulaLatex: r'\min\left(\frac{USL-\mu}{3s},\frac{\mu-LSL}{3s}\right)',
    assumptions: CpkEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'usl',
        label: 'حد بالای مشخصات',
        unit: 'واحد مشترک',
        defaultValue: 10,
        help: 'حد مهندسی محصول، نه حد کنترل؛ متناهی و بزرگ‌تر از حد پایین.',
      ),
      NumericFieldDefinition(
        id: 'lsl',
        label: 'حد پایین مشخصات',
        unit: 'واحد مشترک',
        defaultValue: 4,
        help: 'حد مهندسی متناهی با همان واحد میانگین و سیگما.',
      ),
      NumericFieldDefinition(
        id: 'mean',
        label: 'میانگین فرایند',
        unit: 'واحد مشترک',
        defaultValue: 7,
        help: 'میانگین همان جامعه/بازه؛ خروج از حدود مجاز و شاخص منفی گزارش می‌شود.',
      ),
      NumericFieldDefinition(
        id: 'sigma',
        label: 'انحراف معیار درون‌زیرگروهی',
        unit: 'واحد مشترک',
        defaultValue: 1,
        help: 'بزرگ‌تر از صفر؛ برآورد مستقل و معتبر درون زیرگروه‌های عقلانی، نه حاصل عرض مشخصات.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'usl': const RawTextInput('10'),
          'lsl': const RawTextInput('4'),
          'mean': const RawTextInput('7'),
          'sigma': const RawTextInput('1'),
        }),
        explanation: 'حدود ۴ و ۱۰، میانگین ۷ و سیگمای درون‌گروهی ۱: Cpk=۱.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'cpk',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(1, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'cpk',
        nameFa: 'قابلیت مرکزدار — Cpk',
        nameEn: 'Process Capability Index Cpk',
        description: 'شاخص مرکزدار با انحراف معیار درون‌زیرگروهی',
      ),
    ],
  );
  static final cpkRunner = CalculatorRunner(
    definition: cpk,
    engine: const CpkEngine(),
  );
  static final pp = CalculatorDefinition(
    id: 'pp',
    categoryId: CalculatorCategoryId.quality,
    nameFa: 'عملکرد بالقوه — Pp',
    nameEn: 'Process Performance Index Pp',
    aliases: ['عملکرد کلی فرایند pp'],
    description: 'نسبت عرض مشخصات به شش برابر انحراف معیار کلی نمونه',
    formulaLatex: r'P_p=\frac{USL-LSL}{6s_{overall}}',
    assumptions: PpEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'usl',
        label: 'حد بالای مشخصات',
        unit: 'واحد مشترک',
        defaultValue: 10,
        help: 'حد مهندسی محصول، نه حد کنترل؛ متناهی و بزرگ‌تر از حد پایین.',
      ),
      NumericFieldDefinition(
        id: 'lsl',
        label: 'حد پایین مشخصات',
        unit: 'واحد مشترک',
        defaultValue: 4,
        help: 'حد مهندسی متناهی با همان واحد میانگین و سیگما.',
      ),
      NumericFieldDefinition(
        id: 'sigma',
        label: 'انحراف معیار کلی نمونه',
        unit: 'واحد مشترک',
        defaultValue: 2,
        help: 'بزرگ‌تر از صفر؛ انحراف معیار کلی کل داده‌ها با مبنای نمونه‌ای n−1، نه سیگمای درون گروه.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'usl': const RawTextInput('10'),
          'lsl': const RawTextInput('4'),
          'sigma': const RawTextInput('2'),
        }),
        explanation: 'حدود ۴ و ۱۰، سیگمای کلی ۲: Pp=۰٫۵؛ مرکزیت سنجیده نشده.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'pp',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(0.5, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'pp',
        nameFa: 'عملکرد بالقوه — Pp',
        nameEn: 'Process Performance Index Pp',
        description: 'نسبت عرض مشخصات به شش برابر انحراف معیار کلی نمونه',
      ),
    ],
  );
  static final ppRunner = CalculatorRunner(
    definition: pp,
    engine: const PpEngine(),
  );
  static final ppk = CalculatorDefinition(
    id: 'ppk',
    categoryId: CalculatorCategoryId.quality,
    nameFa: 'عملکرد مرکزدار — Ppk',
    nameEn: 'Process Performance Index Ppk',
    aliases: ['عملکرد کلی فرایند ppk'],
    description: 'شاخص مرکزدار با انحراف معیار کلی نمونه',
    formulaLatex: r'\min\left(\frac{USL-\mu}{3s},\frac{\mu-LSL}{3s}\right)',
    assumptions: PpkEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'usl',
        label: 'حد بالای مشخصات',
        unit: 'واحد مشترک',
        defaultValue: 10,
        help: 'حد مهندسی محصول، نه حد کنترل؛ متناهی و بزرگ‌تر از حد پایین.',
      ),
      NumericFieldDefinition(
        id: 'lsl',
        label: 'حد پایین مشخصات',
        unit: 'واحد مشترک',
        defaultValue: 4,
        help: 'حد مهندسی متناهی با همان واحد میانگین و سیگما.',
      ),
      NumericFieldDefinition(
        id: 'mean',
        label: 'میانگین فرایند',
        unit: 'واحد مشترک',
        defaultValue: 8,
        help: 'میانگین همان جامعه/بازه؛ خروج از حدود مجاز و شاخص منفی گزارش می‌شود.',
      ),
      NumericFieldDefinition(
        id: 'sigma',
        label: 'انحراف معیار کلی نمونه',
        unit: 'واحد مشترک',
        defaultValue: 2,
        help: 'بزرگ‌تر از صفر؛ انحراف معیار کلی کل داده‌ها با مبنای نمونه‌ای n−1، نه سیگمای درون گروه.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'usl': const RawTextInput('10'),
          'lsl': const RawTextInput('4'),
          'mean': const RawTextInput('8'),
          'sigma': const RawTextInput('2'),
        }),
        explanation: 'حدود ۴ و ۱۰، میانگین ۸ و سیگمای کلی ۲: Ppk=۱/۳.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'ppk',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(0.3333333333333333, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'ppk',
        nameFa: 'عملکرد مرکزدار — Ppk',
        nameEn: 'Process Performance Index Ppk',
        description: 'شاخص مرکزدار با انحراف معیار کلی نمونه',
      ),
    ],
  );
  static final ppkRunner = CalculatorRunner(
    definition: ppk,
    engine: const PpkEngine(),
  );
  static final dpmo = CalculatorDefinition(
    id: 'dpmo',
    categoryId: CalculatorCategoryId.quality,
    nameFa: 'نقص در میلیون فرصت — DPMO',
    nameEn: 'Defects Per Million Opportunities',
    aliases: ['نقص در هر میلیون فرصت'],
    description: 'نرخ نقص مشاهده‌شده در میلیون فرصت با تعداد فرصت ثابت و تعریف غیرهم‌پوشان.',
    formulaLatex: r'DPMO=\frac{d}{N\times o}\times 10^6',
    assumptions: DpmoEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'defects',
        label: 'تعداد نقص‌های ثبت‌شده',
        unit: 'نقص',
        defaultValue: 10,
        min: 0,
        integerOnly: true,
        help: 'صحیح نامنفی؛ تعداد واحد معیوب را بدون تعریف فرصت جایگزین نکنید.',
      ),
      NumericFieldDefinition(
        id: 'units',
        label: 'تعداد واحد بررسی‌شده',
        unit: 'واحد',
        defaultValue: 1000,
        integerOnly: true,
        help: 'صحیح مثبت؛ تعداد فرصت هر واحد باید ثابت باشد.',
      ),
      NumericFieldDefinition(
        id: 'opportunities',
        label: 'فرصت نقص در هر واحد',
        unit: 'فرصت/واحد',
        defaultValue: 10,
        integerOnly: true,
        help: 'صحیح مثبت؛ هر فرصت حداکثر یک نقص و تعریف بدون هم‌پوشانی.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'defects': const RawTextInput('10'),
          'units': const RawTextInput('1000'),
          'opportunities': const RawTextInput('10'),
        }),
        explanation: '۱۰ نقص در ۱۰۰۰ واحد با ۱۰ فرصت برای هر واحد: ۱۰۰۰ DPMO، نه ۱۰ واحد معیوب لزوماً.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'dpmo',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(1000, unit: 'نقص/میلیون فرصت'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'dpmo',
        nameFa: 'نقص در میلیون فرصت — DPMO',
        nameEn: 'Defects Per Million Opportunities',
        description: 'نرخ نقص مشاهده‌شده در میلیون فرصت با تعداد فرصت ثابت و تعریف غیرهم‌پوشان.',
      ),
    ],
  );
  static final dpmoRunner = CalculatorRunner(
    definition: dpmo,
    engine: const DpmoEngine(),
  );
  static final sigmaLevel = CalculatorDefinition(
    id: 'sigma_level',
    categoryId: CalculatorCategoryId.quality,
    nameFa: 'برآورد سطح سیگما',
    nameEn: 'Equivalent Sigma Level',
    aliases: ['سیگمای معادل', 'Z bench'],
    description: 'Z نرمال معادل یک‌طرفه از DPMO؛ قرارداد شیفت صفر یا ۱٫۵ به انتخاب صریح.',
    formulaLatex: r'Z=-\Phi^{-1}(DPMO/10^6)+shift',
    assumptions: SigmaLevelEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'dpmo',
        label: 'نقص در میلیون فرصت',
        unit: 'DPMO',
        defaultValue: 1000,
        min: 0,
        max: 1000000,
        help: 'از صفر تا یک میلیون؛ در دو انتها Z متناهی نیست و عدد ساختگی تولید نمی‌شود.',
      ),
      ChoiceFieldDefinition(
        id: 'shift',
        label: 'قرارداد شیفت اختیاری',
        defaultValue: 'none',
        help: 'پیش‌فرض بدون شیفت؛ افزودن ۱٫۵ یک قرارداد تجربی است، نه فرض خودکار یا قانون عمومی.',
        options: [
          ChoiceOption(id: 'none', label: 'بدون شیفت (Z معادل)'),
          ChoiceOption(id: 'convention_1_5', label: 'افزودن قرارداد ۱٫۵'),
        ],
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'dpmo': const RawTextInput('1000'),
          'shift': const RawTextInput('none'),
        }),
        explanation: 'DPMO=۱۰۰۰ و بدون شیفت: Z یک‌طرفه تقریباً ۳٫۰۹۰۲۳۲ است. با انتخاب قرارداد ۱٫۵، عدد ۴٫۵۹۰۲۳۲ می‌شود؛ این انحراف معیار فیزیکی نیست.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'sigma_level',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(3.090232306167813, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'sigma_level',
        nameFa: 'برآورد سطح سیگما',
        nameEn: 'Equivalent Sigma Level',
        description: 'Z نرمال معادل یک‌طرفه از DPMO؛ قرارداد شیفت صفر یا ۱٫۵ به انتخاب صریح.',
      ),
    ],
  );
  static final sigmaLevelRunner = CalculatorRunner(
    definition: sigmaLevel,
    engine: const SigmaLevelEngine(),
  );
  static final xbarControl = CalculatorDefinition(
    id: 'xbar_control',
    categoryId: CalculatorCategoryId.quality,
    nameFa: 'داده‌های نمودار کنترل X-bar',
    nameEn: 'X-bar Control Chart Data',
    aliases: ['نمودار میانگین', 'ایکس بار', 'Xbar R'],
    description: 'دادهٔ میانگین/دامنه و حدود سه‌سیگمای تخمینی X-bar/R برای زیرگروه‌های هم‌اندازه.',
    formulaLatex:
        r'CL=\bar{\bar X},\quad UCL,LCL=CL\pm\frac{3\bar R}{d_2\sqrt{n}}',
    assumptions: XbarControlEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'subgroup_size',
        label: 'تعداد مشاهده در هر زیرگروه',
        unit: 'مشاهده/زیرگروه',
        defaultValue: 5,
        min: 2,
        max: 10,
        integerOnly: true,
        help: 'عدد صحیح ۲ تا ۱۰؛ هر n سطر پشت‌سرهم فهرست یک گروه زمانی است.',
      ),
      NumberListFieldDefinition(
        id: 'observations',
        label: 'مشاهده‌ها به ترتیب گروه و زمان',
        unit: 'واحد مشترک',
        minItems: 4,
        maxItems: 1000,
        defaultValue: [8, 9, 10, 11, 12, 9, 10, 11, 12, 13, 10, 11, 12, 13, 14],
        help: 'هر عدد یک سطر؛ گروه‌ها هم‌اندازه، حداقل دو گروه کامل، بدون جابه‌جایی ترتیب. دامنهٔ صفر همهٔ گروه‌ها برای برآورد R معتبر نیست.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'subgroup_size': const RawTextInput('5'),
          'observations': RawNumberListInput([
            '8',
            '9',
            '10',
            '11',
            '12',
            '9',
            '10',
            '11',
            '12',
            '13',
            '10',
            '11',
            '12',
            '13',
            '14',
          ]),
        }),
        explanation: 'سه زیرگروه پنج‌تایی با میانگین‌های ۱۰، ۱۱، ۱۲ و دامنهٔ ۴: CL=۱۱؛ حدود از d2=۲٫۳۲۶ محاسبه می‌شوند. این مثال کوتاه تأیید پایداری نیست.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'xbar_control',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(11, unit: 'واحد مشترک'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'xbar_control',
        nameFa: 'داده‌های نمودار کنترل X-bar',
        nameEn: 'X-bar Control Chart Data',
        description: 'دادهٔ میانگین/دامنه و حدود سه‌سیگمای تخمینی X-bar/R برای زیرگروه‌های هم‌اندازه.',
      ),
    ],
  );
  static final xbarControlRunner = CalculatorRunner(
    definition: xbarControl,
    engine: const XbarControlEngine(),
  );
  static final coq = CalculatorDefinition(
    id: 'coq',
    categoryId: CalculatorCategoryId.quality,
    nameFa: 'هزینهٔ کیفیت — COQ',
    nameEn: 'Cost of Quality',
    aliases: ['هزینه کیفیت', 'PAF', 'COPQ'],
    description: 'جمع هزینهٔ پیشگیری، ارزیابی و شکست داخلی/خارجی با مدل PAF.',
    formulaLatex: r'COQ=P+A+F_i+F_e,\quad COPQ=F_i+F_e',
    assumptions: CoqEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'prevention',
        label: 'هزینهٔ پیشگیری',
        unit: 'ریال/بازه',
        defaultValue: 100,
        min: 0,
        help: 'نامنفی؛ از ارزیابی و شکست‌ها جدا و بدون دوباره‌شماری.',
      ),
      NumericFieldDefinition(
        id: 'appraisal',
        label: 'هزینهٔ ارزیابی',
        unit: 'ریال/بازه',
        defaultValue: 200,
        min: 0,
        help: 'نامنفی و متعلق به همان دوره و روش تخصیص.',
      ),
      NumericFieldDefinition(
        id: 'internal_failure',
        label: 'هزینهٔ شکست داخلی',
        unit: 'ریال/بازه',
        defaultValue: 300,
        min: 0,
        help: 'نامنفی؛ پیش از تحویل به مشتری طبق تعریف سازمان.',
      ),
      NumericFieldDefinition(
        id: 'external_failure',
        label: 'هزینهٔ شکست خارجی',
        unit: 'ریال/بازه',
        defaultValue: 400,
        min: 0,
        help: 'نامنفی؛ پس از تحویل طبق همان مبنای دوره.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی با روش مشخص',
        inputs: RawCalculatorInput({
          'prevention': const RawTextInput('100'),
          'appraisal': const RawTextInput('200'),
          'internal_failure': const RawTextInput('300'),
          'external_failure': const RawTextInput('400'),
        }),
        explanation: 'پیشگیری ۱۰۰، ارزیابی ۲۰۰، شکست داخلی ۳۰۰ و خارجی ۴۰۰ ریال: COQ=۱۰۰۰ و COPQ=۷۰۰ ریال.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'coq',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(1000, unit: 'ریال/بازه'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'coq',
        nameFa: 'هزینهٔ کیفیت — COQ',
        nameEn: 'Cost of Quality',
        description:
            'جمع هزینهٔ پیشگیری، ارزیابی و شکست داخلی/خارجی با مدل PAF.',
      ),
    ],
  );
  static final coqRunner = CalculatorRunner(
    definition: coq,
    engine: const CoqEngine(),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        PrototypeCalculators.cpRunner,
        cpkRunner,
        ppRunner,
        ppkRunner,
        dpmoRunner,
        sigmaLevelRunner,
        xbarControlRunner,
        coqRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((r) => r.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({for (final r in runners) r.definition.id: r});
}
