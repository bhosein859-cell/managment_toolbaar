import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/project/cpm_engine.dart';
import '../../features/calculators/domain/engines/project/duration_comparison_engine.dart';
import '../../features/calculators/domain/engines/project/eac_etc_engine.dart';
import '../../features/calculators/domain/engines/project/evm_performance_engine.dart';
import '../../features/calculators/domain/engines/project/pert_duration_engine.dart';
import '../../features/calculators/domain/engines/project/project_float_engine.dart';
import '../../features/calculators/domain/engines/project/sv_cv_engine.dart';
import '../../features/calculators/domain/engines/project/three_point_engine.dart';

abstract final class ProjectCalculators {
  static final pertDuration = CalculatorDefinition(
    id: 'pert_duration',
    categoryId: CalculatorCategoryId.project,
    nameFa: 'برآورد مدت PERT',
    nameEn: 'PERT Expected Duration',
    aliases: ['pert duration'],
    description: 'برآورد مدت PERT با ورودی معتبر و فرض‌های محاسباتی صریح؛ برای توضیح روش بخش تفسیر را بخوانید.',
    formulaLatex:
        r't_e=\frac{O+4M+P}{6},\quad Var=\left(\frac{P-O}{6}\right)^2',
    assumptions: PertDurationEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'optimistic',
        label: 'برآورد خوش‌بینانه O',
        unit: 'روز',
        min: 0,
        defaultValue: 2,
        help: 'نامنفی؛ O ≤ M ≤ P؛ همهٔ مدت‌ها در واحد روز مشترک.',
      ),
      NumericFieldDefinition(
        id: 'most_likely',
        label: 'برآورد محتمل M',
        unit: 'روز',
        min: 0,
        defaultValue: 4,
        help: 'مقدار محتمل، نه میانگین؛ بین دو کران باشد.',
      ),
      NumericFieldDefinition(
        id: 'pessimistic',
        label: 'برآورد بدبینانه P',
        unit: 'روز',
        min: 0,
        defaultValue: 8,
        help: 'کران بالای سناریو؛ تضمین یا صدک توزیع نیست.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی روش مشخص',
        inputs: RawCalculatorInput({
          'optimistic': const RawTextInput('2'),
          'most_likely': const RawTextInput('4'),
          'pessimistic': const RawTextInput('8'),
        }),
        explanation: 'O=۲، M=۴، P=۸: مدت مورد انتظار ۴٫۳۳۳۳۳۳ روز، انحراف معیار یک روز و واریانس یک روز مربع.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'pert_duration',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(4.333333333333333, unit: 'روز'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'pert_duration',
        nameFa: 'برآورد مدت PERT',
        nameEn: 'PERT Expected Duration',
        description: PertDurationEngine.basis,
      ),
    ],
  );
  static final pertDurationRunner = CalculatorRunner(
    definition: pertDuration,
    engine: const PertDurationEngine(),
  );
  static final cpm = CalculatorDefinition(
    id: 'cpm',
    categoryId: CalculatorCategoryId.project,
    nameFa: 'CPM و مسیر بحرانی',
    nameEn: 'Critical Path Method CPM',
    aliases: ['cpm'],
    description: 'CPM و مسیر بحرانی با ورودی معتبر و فرض‌های محاسباتی صریح؛ برای توضیح روش بخش تفسیر را بخوانید.',
    formulaLatex: r'ES_i=\max EF_{pred},\quad LS_i=\min LS_{succ}-d_i',
    assumptions: CpmEngine.basis,
    fields: [
      NumberListFieldDefinition(
        id: 'activity_ids',
        label: 'شناسهٔ فعالیت‌ها به ترتیب ردیف',
        unit: 'شناسه',
        min: 1,
        maxItems: 200,
        defaultValue: [1, 2, 3, 4],
        max: 999999,
        help: 'هر شناسه در یک سطر؛ عدد صحیح یکتا از ۱ تا ۹۹۹۹۹۹. شناسه شمارهٔ ردیف نیست؛ ردیف k با مدت ردیف k هم‌تراز است.',
      ),
      NumberListFieldDefinition(
        id: 'durations',
        label: 'مدت فعالیت‌ها به همان ترتیب',
        unit: 'روز',
        min: 0,
        maxItems: 200,
        defaultValue: [3, 2, 4, 1],
        help: 'متناهی و نامنفی؛ تعداد دقیقاً برابر شناسه‌ها. صفر برای milestone مجاز است.',
      ),
      NumberListFieldDefinition(
        id: 'predecessor_ids',
        label: 'سر یال‌ها: شناسهٔ پیش‌نیاز',
        unit: 'شناسه',
        min: 1,
        maxItems: 2000,
        defaultValue: [1, 1, 2, 3],
        max: 999999,
        isRequired: false,
        minItems: 0,
        help: 'هر سطر با سطر متناظر فهرست پس‌نیاز یک یال FS است: پیش‌نیاز باید تمام شود تا پس‌نیاز شروع شود. هر دو فهرست را برای شبکهٔ بدون یال خالی کنید.',
      ),
      NumberListFieldDefinition(
        id: 'successor_ids',
        label: 'ته یال‌ها: شناسهٔ پس‌نیاز',
        unit: 'شناسه',
        min: 1,
        maxItems: 2000,
        defaultValue: [2, 3, 4, 4],
        max: 999999,
        isRequired: false,
        minItems: 0,
        help: 'تعداد دقیقاً برابر فهرست پیش‌نیاز؛ هر دو شناسه باید موجود باشند. خودارجاعی، یال تکراری و چرخه رد می‌شوند؛ lag در این مدل صفر است.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی روش مشخص',
        inputs: RawCalculatorInput({
          'activity_ids': RawNumberListInput(['1', '2', '3', '4']),
          'durations': RawNumberListInput(['3', '2', '4', '1']),
          'predecessor_ids': RawNumberListInput(['1', '1', '2', '3']),
          'successor_ids': RawNumberListInput(['2', '3', '4', '4']),
        }),
        explanation: '۱ با مدت ۳؛ ۲ و ۳ پس از ۱ با مدت ۲ و ۴؛ ۴ با مدت ۱ پس از هر دو: افق ۸ روز، مسیر بحرانی متصل با شروع ۱، سپس ۳ و پایان ۴ و شناوری فعالیت ۲ برابر ۲ روز است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'cpm',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(8, unit: 'روز'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'cpm',
        nameFa: 'CPM و مسیر بحرانی',
        nameEn: 'Critical Path Method CPM',
        description: CpmEngine.basis,
      ),
    ],
  );
  static final cpmRunner = CalculatorRunner(
    definition: cpm,
    engine: const CpmEngine(),
  );
  static final projectFloat = CalculatorDefinition(
    id: 'project_float',
    categoryId: CalculatorCategoryId.project,
    nameFa: 'شناوری کل و آزاد پروژه',
    nameEn: 'Total and Free Float',
    aliases: ['project float'],
    description: 'شناوری کل و آزاد پروژه با ورودی معتبر و فرض‌های محاسباتی صریح؛ برای توضیح روش بخش تفسیر را بخوانید.',
    formulaLatex: r'TF_i=LS_i-ES_i,\quad FF_i=\min ES_{succ}-EF_i',
    assumptions: ProjectFloatEngine.basis,
    fields: [
      NumberListFieldDefinition(
        id: 'activity_ids',
        label: 'شناسهٔ فعالیت‌ها به ترتیب ردیف',
        unit: 'شناسه',
        min: 1,
        maxItems: 200,
        defaultValue: [1, 2, 3, 4],
        max: 999999,
        help: 'هر شناسه در یک سطر؛ عدد صحیح یکتا از ۱ تا ۹۹۹۹۹۹. شناسه شمارهٔ ردیف نیست؛ ردیف k با مدت ردیف k هم‌تراز است.',
      ),
      NumberListFieldDefinition(
        id: 'durations',
        label: 'مدت فعالیت‌ها به همان ترتیب',
        unit: 'روز',
        min: 0,
        maxItems: 200,
        defaultValue: [3, 2, 4, 1],
        help: 'متناهی و نامنفی؛ تعداد دقیقاً برابر شناسه‌ها. صفر برای milestone مجاز است.',
      ),
      NumberListFieldDefinition(
        id: 'predecessor_ids',
        label: 'سر یال‌ها: شناسهٔ پیش‌نیاز',
        unit: 'شناسه',
        min: 1,
        maxItems: 2000,
        defaultValue: [1, 1, 2, 3],
        max: 999999,
        isRequired: false,
        minItems: 0,
        help: 'هر سطر با سطر متناظر فهرست پس‌نیاز یک یال FS است: پیش‌نیاز باید تمام شود تا پس‌نیاز شروع شود. هر دو فهرست را برای شبکهٔ بدون یال خالی کنید.',
      ),
      NumberListFieldDefinition(
        id: 'successor_ids',
        label: 'ته یال‌ها: شناسهٔ پس‌نیاز',
        unit: 'شناسه',
        min: 1,
        maxItems: 2000,
        defaultValue: [2, 3, 4, 4],
        max: 999999,
        isRequired: false,
        minItems: 0,
        help: 'تعداد دقیقاً برابر فهرست پیش‌نیاز؛ هر دو شناسه باید موجود باشند. خودارجاعی، یال تکراری و چرخه رد می‌شوند؛ lag در این مدل صفر است.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی روش مشخص',
        inputs: RawCalculatorInput({
          'activity_ids': RawNumberListInput(['1', '2', '3', '4']),
          'durations': RawNumberListInput(['3', '2', '4', '1']),
          'predecessor_ids': RawNumberListInput(['1', '1', '2', '3']),
          'successor_ids': RawNumberListInput(['2', '3', '4', '4']),
        }),
        explanation: 'در شبکهٔ مثال CPM، شناوری کل/آزاد فعالیت ۲ هر دو ۲ روز و بقیه صفر است؛ بیشترین TF یک فعالیت ۲ روز است، نه جمع شناوری پروژه.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'project_float',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(2, unit: 'روز'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'project_float',
        nameFa: 'شناوری کل و آزاد پروژه',
        nameEn: 'Total and Free Float',
        description: ProjectFloatEngine.basis,
      ),
    ],
  );
  static final projectFloatRunner = CalculatorRunner(
    definition: projectFloat,
    engine: const ProjectFloatEngine(),
  );
  static final evmPerformance = CalculatorDefinition(
    id: 'evm_performance',
    categoryId: CalculatorCategoryId.project,
    nameFa: 'شاخص‌های EVM؛ SPI و CPI',
    nameEn: 'Earned Value Performance SPI CPI',
    aliases: ['evm performance'],
    description: 'شاخص‌های EVM؛ SPI و CPI با ورودی معتبر و فرض‌های محاسباتی صریح؛ برای توضیح روش بخش تفسیر را بخوانید.',
    formulaLatex: r'SPI=\frac{EV}{PV},\quad CPI=\frac{EV}{AC}',
    assumptions: EvmPerformanceEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'pv',
        label: 'ارزش برنامه‌ریزی‌شده PV',
        unit: 'ریال',
        min: 0,
        defaultValue: 100,
        help:
            'ارزش بودجه‌ای کار برنامه‌ریزی‌شدهٔ تجمعی تا تاریخ وضعیت، نامنفی.',
      ),
      NumericFieldDefinition(
        id: 'ev',
        label: 'ارزش کسب‌شده EV',
        unit: 'ریال',
        min: 0,
        defaultValue: 80,
        help: 'ارزش بودجه‌ای کار انجام‌شده تا همان تاریخ؛ هزینهٔ واقعی نیست و می‌تواند از PV بیشتر باشد.',
      ),
      NumericFieldDefinition(
        id: 'ac',
        label: 'هزینهٔ واقعی AC',
        unit: 'ریال',
        min: 0,
        defaultValue: 100,
        help: 'هزینهٔ واقعی تجمعی همان دامنه و تاریخ؛ نامنفی و الزاماً کمتر از EV نیست.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی روش مشخص',
        inputs: RawCalculatorInput({
          'pv': const RawTextInput('100'),
          'ev': const RawTextInput('80'),
          'ac': const RawTextInput('100'),
        }),
        explanation: 'PV=۱۰۰، EV=۸۰، AC=۱۰۰: SPI=۰٫۸ و CPI=۰٫۸؛ هر دو نسبت‌اند، نه درصد روزها.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'evm_performance',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(0.8, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'evm_performance',
        nameFa: 'شاخص‌های EVM؛ SPI و CPI',
        nameEn: 'Earned Value Performance SPI CPI',
        description: EvmPerformanceEngine.basis,
      ),
    ],
  );
  static final evmPerformanceRunner = CalculatorRunner(
    definition: evmPerformance,
    engine: const EvmPerformanceEngine(),
  );
  static final threePoint = CalculatorDefinition(
    id: 'three_point',
    categoryId: CalculatorCategoryId.project,
    nameFa: 'برآورد سه‌نقطه‌ای',
    nameEn: 'Three-point Estimation',
    aliases: ['three point'],
    description: 'برآورد سه‌نقطه‌ای با ورودی معتبر و فرض‌های محاسباتی صریح؛ برای توضیح روش بخش تفسیر را بخوانید.',
    formulaLatex: r'E_{tri}=\frac{O+M+P}{3},\quad E_{PERT}=\frac{O+4M+P}{6}',
    assumptions: ThreePointEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'optimistic',
        label: 'برآورد خوش‌بینانه O',
        unit: 'واحد مشترک',
        min: 0,
        defaultValue: 2,
        help: 'نامنفی؛ O ≤ M ≤ P؛ همهٔ مدت‌ها در واحد مشترک مشترک.',
      ),
      NumericFieldDefinition(
        id: 'most_likely',
        label: 'برآورد محتمل M',
        unit: 'واحد مشترک',
        min: 0,
        defaultValue: 4,
        help: 'مقدار محتمل، نه میانگین؛ بین دو کران باشد.',
      ),
      NumericFieldDefinition(
        id: 'pessimistic',
        label: 'برآورد بدبینانه P',
        unit: 'واحد مشترک',
        min: 0,
        defaultValue: 8,
        help: 'کران بالای سناریو؛ تضمین یا صدک توزیع نیست.',
      ),
      ChoiceFieldDefinition(
        id: 'method',
        label: 'مدل برآورد سه‌نقطه‌ای',
        defaultValue: 'triangular',
        help: 'مثلثی پیش‌فرض است؛ PERT وزنی را در صورت پذیرش تقریب آن صریح انتخاب کنید.',
        options: [
          ChoiceOption(id: 'triangular', label: 'توزیع مثلثی'),
          ChoiceOption(id: 'pert', label: 'PERT وزنی'),
        ],
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی روش مشخص',
        inputs: RawCalculatorInput({
          'optimistic': const RawTextInput('2'),
          'most_likely': const RawTextInput('4'),
          'pessimistic': const RawTextInput('8'),
          'method': const RawTextInput('triangular'),
        }),
        explanation: '۲،۴،۸ در مدل مثلثی: میانگین ۴٫۶۶۶۶۶۷ و واریانس ۱۴/۹؛ با PERT میانگین ۲۶/۶ است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'three_point',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(4.666666666666667, unit: 'واحد مشترک'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'three_point',
        nameFa: 'برآورد سه‌نقطه‌ای',
        nameEn: 'Three-point Estimation',
        description: ThreePointEngine.basis,
      ),
    ],
  );
  static final threePointRunner = CalculatorRunner(
    definition: threePoint,
    engine: const ThreePointEngine(),
  );
  static final eacEtc = CalculatorDefinition(
    id: 'eac_etc',
    categoryId: CalculatorCategoryId.project,
    nameFa: 'برآورد EAC و ETC',
    nameEn: 'Estimate at Completion EAC ETC',
    aliases: ['eac etc'],
    description: 'برآورد EAC و ETC با ورودی معتبر و فرض‌های محاسباتی صریح؛ برای توضیح روش بخش تفسیر را بخوانید.',
    formulaLatex: r'EAC=AC+ETC,\quad ETC_{CPI}=\frac{BAC-EV}{CPI}',
    assumptions: EacEtcEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'bac',
        label: 'بودجهٔ مصوب کل BAC',
        unit: 'ریال',
        min: 0,
        defaultValue: 1000,
        help: 'مثبت؛ مبنای دامنه ثابت. PV و EV نباید از BAC بیشتر باشند.',
      ),
      NumericFieldDefinition(
        id: 'pv',
        label: 'ارزش برنامه‌ریزی‌شده PV',
        unit: 'ریال',
        min: 0,
        defaultValue: 100,
        help:
            'ارزش بودجه‌ای کار برنامه‌ریزی‌شدهٔ تجمعی تا تاریخ وضعیت، نامنفی.',
      ),
      NumericFieldDefinition(
        id: 'ev',
        label: 'ارزش کسب‌شده EV',
        unit: 'ریال',
        min: 0,
        defaultValue: 80,
        help: 'ارزش بودجه‌ای کار انجام‌شده تا همان تاریخ؛ هزینهٔ واقعی نیست و می‌تواند از PV بیشتر باشد.',
      ),
      NumericFieldDefinition(
        id: 'ac',
        label: 'هزینهٔ واقعی AC',
        unit: 'ریال',
        min: 0,
        defaultValue: 100,
        help: 'هزینهٔ واقعی تجمعی همان دامنه و تاریخ؛ نامنفی و الزاماً کمتر از EV نیست.',
      ),
      NumericFieldDefinition(
        id: 'new_etc',
        label: 'برآورد جدید کار باقی‌مانده',
        unit: 'ریال',
        min: 0,
        defaultValue: 250,
        help: 'فقط در روش پایین‌به‌بالا استفاده می‌شود؛ نامنفی. در روش‌های دیگر در محاسبه دخالت ندارد.',
      ),
      ChoiceFieldDefinition(
        id: 'method',
        label: 'فرض پیش‌بینی EAC/ETC',
        defaultValue: 'cpi',
        help: 'روش را با فرض آینده انتخاب کنید؛ هیچ روش به‌طور خودکار درست‌تر اعلام نمی‌شود.',
        options: [
          ChoiceOption(id: 'cpi', label: 'ادامهٔ کارایی هزینه CPI'),
          ChoiceOption(id: 'budget', label: 'باقی‌مانده طبق بودجه'),
          ChoiceOption(id: 'cpi_spi', label: 'اثر مشترک CPI و SPI'),
          ChoiceOption(id: 'bottom_up', label: 'برآورد مجدد پایین‌به‌بالا'),
        ],
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی روش مشخص',
        inputs: RawCalculatorInput({
          'bac': const RawTextInput('1000'),
          'pv': const RawTextInput('100'),
          'ev': const RawTextInput('80'),
          'ac': const RawTextInput('100'),
          'new_etc': const RawTextInput('250'),
          'method': const RawTextInput('cpi'),
        }),
        explanation: 'BAC=۱۰۰۰، PV=۱۰۰، EV=۸۰، AC=۱۰۰ و ادامهٔ CPI=۰٫۸: ETC=۱۱۵۰، EAC=۱۲۵۰ ریال.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'eac_etc',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(1250, unit: 'ریال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'eac_etc',
        nameFa: 'برآورد EAC و ETC',
        nameEn: 'Estimate at Completion EAC ETC',
        description: EacEtcEngine.basis,
      ),
    ],
  );
  static final eacEtcRunner = CalculatorRunner(
    definition: eacEtc,
    engine: const EacEtcEngine(),
  );
  static final svCv = CalculatorDefinition(
    id: 'sv_cv',
    categoryId: CalculatorCategoryId.project,
    nameFa: 'انحراف زمان‌بندی و هزینه؛ SV/CV',
    nameEn: 'Schedule and Cost Variance SV CV',
    aliases: ['sv cv'],
    description: 'انحراف زمان‌بندی و هزینه؛ SV/CV با ورودی معتبر و فرض‌های محاسباتی صریح؛ برای توضیح روش بخش تفسیر را بخوانید.',
    formulaLatex: r'SV=EV-PV,\quad CV=EV-AC',
    assumptions: SvCvEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'pv',
        label: 'ارزش برنامه‌ریزی‌شده PV',
        unit: 'ریال',
        min: 0,
        defaultValue: 100,
        help:
            'ارزش بودجه‌ای کار برنامه‌ریزی‌شدهٔ تجمعی تا تاریخ وضعیت، نامنفی.',
      ),
      NumericFieldDefinition(
        id: 'ev',
        label: 'ارزش کسب‌شده EV',
        unit: 'ریال',
        min: 0,
        defaultValue: 80,
        help: 'ارزش بودجه‌ای کار انجام‌شده تا همان تاریخ؛ هزینهٔ واقعی نیست و می‌تواند از PV بیشتر باشد.',
      ),
      NumericFieldDefinition(
        id: 'ac',
        label: 'هزینهٔ واقعی AC',
        unit: 'ریال',
        min: 0,
        defaultValue: 100,
        help: 'هزینهٔ واقعی تجمعی همان دامنه و تاریخ؛ نامنفی و الزاماً کمتر از EV نیست.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی روش مشخص',
        inputs: RawCalculatorInput({
          'pv': const RawTextInput('100'),
          'ev': const RawTextInput('80'),
          'ac': const RawTextInput('100'),
        }),
        explanation: 'PV=۱۰۰، EV=۸۰، AC=۱۰۰: SV=−۲۰ و CV=−۲۰ ریال؛ از SV نمی‌توان روزهای تأخیر را استخراج کرد.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'sv_cv',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(-20, unit: 'ریال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'sv_cv',
        nameFa: 'انحراف زمان‌بندی و هزینه؛ SV/CV',
        nameEn: 'Schedule and Cost Variance SV CV',
        description: SvCvEngine.basis,
      ),
    ],
  );
  static final svCvRunner = CalculatorRunner(
    definition: svCv,
    engine: const SvCvEngine(),
  );
  static final durationComparison = CalculatorDefinition(
    id: 'duration_comparison',
    categoryId: CalculatorCategoryId.project,
    nameFa: 'مقایسهٔ مدت برنامه و واقعی',
    nameEn: 'Planned versus Actual Duration',
    aliases: ['duration comparison'],
    description: 'مقایسهٔ مدت برنامه و واقعی با ورودی معتبر و فرض‌های محاسباتی صریح؛ برای توضیح روش بخش تفسیر را بخوانید.',
    formulaLatex:
        r'\Delta T=T_{actual}-T_{plan},\quad Overrun=\frac{\Delta T}{T_{plan}}',
    assumptions: DurationComparisonEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'planned_duration',
        label: 'مدت برنامه‌ریزی‌شده',
        unit: 'روز',
        min: 0,
        defaultValue: 10,
        help: 'نامنفی و همان مبنای روز کاری/تقویمی و همان دامنهٔ مدت واقعی. برای برنامهٔ صفر نسبت تعریف نمی‌شود.',
      ),
      NumericFieldDefinition(
        id: 'actual_duration',
        label: 'مدت واقعی',
        unit: 'روز',
        min: 0,
        defaultValue: 12,
        help: 'نامنفی؛ برای کار ناتمام، مدت سپری‌شده را با کل مدت برنامه به‌عنوان عملکرد نهایی مقایسه نکنید.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال عددی روش مشخص',
        inputs: RawCalculatorInput({
          'planned_duration': const RawTextInput('10'),
          'actual_duration': const RawTextInput('12'),
        }),
        explanation: 'برنامه ۱۰ روز و واقعی ۱۲ روز: اختلاف +۲ روز، نسبت ۱٫۲ و افزایش ۲۰٪؛ این SPI نیست.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'duration_comparison',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(2, unit: 'روز'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'duration_comparison',
        nameFa: 'مقایسهٔ مدت برنامه و واقعی',
        nameEn: 'Planned versus Actual Duration',
        description: DurationComparisonEngine.basis,
      ),
    ],
  );
  static final durationComparisonRunner = CalculatorRunner(
    definition: durationComparison,
    engine: const DurationComparisonEngine(),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        pertDurationRunner,
        cpmRunner,
        projectFloatRunner,
        evmPerformanceRunner,
        threePointRunner,
        eacEtcRunner,
        svCvRunner,
        durationComparisonRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((r) => r.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({for (final r in runners) r.definition.id: r});
}
