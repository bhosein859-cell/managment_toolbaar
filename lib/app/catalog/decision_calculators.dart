import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/decision/ahp_engine.dart';
import '../../features/calculators/domain/engines/decision/cost_benefit_comparison_engine.dart';
import '../../features/calculators/domain/engines/decision/decision_matrix_engine.dart';
import '../../features/calculators/domain/engines/decision/expected_value_tree_engine.dart';
import '../../features/calculators/domain/engines/decision/topsis_engine.dart';
import '../../features/calculators/domain/engines/decision/two_option_break_even_engine.dart';
import '../../features/calculators/domain/engines/decision/weight_sensitivity_engine.dart';
import '../../features/calculators/domain/engines/decision/weighted_scoring_engine.dart';

abstract final class DecisionCalculators {
  static final ahp = CalculatorDefinition(
    id: 'ahp',
    categoryId: CalculatorCategoryId.decisionMaking,
    nameFa: 'AHP؛ اولویت و سازگاری',
    nameEn: 'AHP Priorities and Consistency',
    aliases: ['ahp'],
    description: 'AHP؛ اولویت و سازگاری؛ خروجی مشروط به داده و فرض‌های مدل، نه انتخاب قطعی. تغییر ابعاد نیازمند دادهٔ هم‌اندازه است؛ مقدار ناقص حدس زده نمی‌شود.',
    formulaLatex:
        r'Aw=\lambda_{max}w,\quad CR=\frac{(\lambda_{max}-n)/(n-1)}{RI}',
    assumptions: AhpEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'alternatives',
        label: 'تعداد گزینه‌های AHP',
        defaultValue: 3,
        min: 2,
        max: 10,
        integerOnly: true,
        help: 'عدد صحیح ۲ تا ۱۰؛ برای هر معیار ماتریس زوجی گزینه‌ها لازم است.',
      ),
      NumericFieldDefinition(
        id: 'criteria',
        label: 'تعداد معیارهای AHP',
        defaultValue: 2,
        min: 2,
        max: 10,
        integerOnly: true,
        help: 'عدد صحیح ۲ تا ۱۰؛ RI فقط برای این دامنه تعریف شده است.',
      ),
      NumberListFieldDefinition(
        id: 'criteria_matrix',
        label: 'ماتریس زوجی معیارها؛ سطری',
        maxItems: 100,
        defaultValue: [1, 2, 0.5, 1],
        min: 0.1111111111111111,
        max: 9,
        help: 'تعداد معیار به توان دو خانه، هر عدد در یک سطر. قطر یک، درایه‌ها متقابل و بین ۱/۹ و ۹.',
      ),
      NumberListFieldDefinition(
        id: 'local_matrices',
        label: 'ماتریس‌های زوجی گزینه‌ها؛ معیار به معیار',
        maxItems: 1000,
        defaultValue: [
          1,
          1.6666666666666667,
          2.5,
          0.6,
          1,
          1.5,
          0.4,
          0.6666666666666666,
          1,
          1,
          0.6666666666666666,
          0.4,
          1.5,
          1,
          0.6,
          2.5,
          1.6666666666666667,
          1,
        ],
        min: 0.1111111111111111,
        max: 9,
        help: 'ابتدا تمام خانه‌های سطری ماتریس گزینه‌ها برای معیار اول، سپس معیار دوم و ...؛ دقیقاً معیار×گزینه×گزینه خانه.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ مرجع قابل بررسی',
        inputs: RawCalculatorInput({
          'alternatives': const RawTextInput('3'),
          'criteria': const RawTextInput('2'),
          'criteria_matrix': RawNumberListInput(['1', '2', '0.5', '1']),
          'local_matrices': RawNumberListInput([
            '1',
            '1.6666666666666667',
            '2.5',
            '0.6',
            '1',
            '1.5',
            '0.4',
            '0.6666666666666666',
            '1',
            '1',
            '0.6666666666666666',
            '0.4',
            '1.5',
            '1',
            '0.6',
            '2.5',
            '1.6666666666666667',
            '1',
          ]),
        }),
        explanation: 'وزن معیارها ۲/۳ و ۱/۳؛ اولویت محلی معیار اول ۰٫۵،۰٫۳،۰٫۲ و دوم ۰٫۲،۰٫۳،۰٫۵: اولویت جهانی ۰٫۴،۰٫۳،۰٫۳، با CR نزدیک صفر.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'ahp',
            label: 'نتیجهٔ مرجع نمونه',
            value: NumericResultValue(0.4, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'ahp',
        nameFa: 'AHP؛ اولویت و سازگاری',
        nameEn: 'AHP Priorities and Consistency',
        description: AhpEngine.basis,
      ),
    ],
  );
  static final ahpRunner = CalculatorRunner(
    definition: ahp,
    engine: const AhpEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final topsis = CalculatorDefinition(
    id: 'topsis',
    categoryId: CalculatorCategoryId.decisionMaking,
    nameFa: 'رتبه‌بندی TOPSIS',
    nameEn: 'TOPSIS Vector Normalization',
    aliases: ['topsis'],
    description: 'رتبه‌بندی TOPSIS؛ خروجی مشروط به داده و فرض‌های مدل، نه انتخاب قطعی. تغییر ابعاد نیازمند دادهٔ هم‌اندازه است؛ مقدار ناقص حدس زده نمی‌شود.',
    formulaLatex: r'r_{ij}=\frac{x_{ij}}{\sqrt{\sum_i x_{ij}^2}},\quad C_i=\frac{D_i^-}{D_i^++D_i^-}',
    assumptions: TopsisEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'alternatives',
        label: 'تعداد گزینه‌ها',
        defaultValue: 3,
        min: 2,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح ۲ تا ۲۰؛ هر گزینه یک سطر ماتریس.',
      ),
      NumericFieldDefinition(
        id: 'criteria',
        label: 'تعداد معیارها',
        defaultValue: 2,
        min: 1,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح ۱ تا ۲۰؛ هر معیار یک ستون.',
      ),
      NumberListFieldDefinition(
        id: 'matrix',
        label: 'ماتریس؛ خانه‌ها به ترتیب سطری',
        maxItems: 400,
        defaultValue: [3, 1, 2, 2, 1, 3],
        help: 'هر عدد در یک سطر: ابتدا تمام معیارهای گزینهٔ اول، سپس گزینهٔ دوم و ...؛ تعداد دقیقاً گزینه×معیار.',
      ),
      NumberListFieldDefinition(
        id: 'weights',
        label: 'وزن معیارها',
        maxItems: 20,
        defaultValue: [0.6, 0.4],
        min: 0,
        help: 'وزن نسبی نامنفی؛ حداقل یکی مثبت. جمع لازم نیست یک باشد و به‌صراحت نرمال می‌شود؛ صفر یعنی بدون سهم.',
      ),
      NumberListFieldDefinition(
        id: 'directions',
        label: 'نوع هر معیار: منفعت یا هزینه',
        maxItems: 20,
        defaultValue: [1, 1],
        min: -1,
        max: 1,
        help:
            'برای هر ستون ۱=بیشتر بهتر، منفی ۱=کمتر بهتر؛ تعداد برابر معیارها.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ مرجع قابل بررسی',
        inputs: RawCalculatorInput({
          'alternatives': const RawTextInput('3'),
          'criteria': const RawTextInput('2'),
          'matrix': RawNumberListInput(['3', '1', '2', '2', '1', '3']),
          'weights': RawNumberListInput(['0.6', '0.4']),
          'directions': RawNumberListInput(['1', '1']),
        }),
        explanation: 'ماتریس متقارن (۳،۱)،(۲،۲)،(۱،۳)، وزن ۰٫۶/۰٫۴ و دو منفعت: نزدیکی‌ها ۰٫۶،۰٫۵،۰٫۴؛ گزینهٔ نخست در این مدل بالاتر است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'topsis',
            label: 'نتیجهٔ مرجع نمونه',
            value: NumericResultValue(0.6, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'topsis',
        nameFa: 'رتبه‌بندی TOPSIS',
        nameEn: 'TOPSIS Vector Normalization',
        description: TopsisEngine.basis,
      ),
    ],
  );
  static final topsisRunner = CalculatorRunner(
    definition: topsis,
    engine: const TopsisEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final decisionMatrix = CalculatorDefinition(
    id: 'decision_matrix',
    categoryId: CalculatorCategoryId.decisionMaking,
    nameFa: 'ماتریس تصمیم با نرمال‌سازی',
    nameEn: 'Min-max Decision Matrix',
    aliases: ['decision matrix'],
    description: 'ماتریس تصمیم با نرمال‌سازی؛ خروجی مشروط به داده و فرض‌های مدل، نه انتخاب قطعی. تغییر ابعاد نیازمند دادهٔ هم‌اندازه است؛ مقدار ناقص حدس زده نمی‌شود.',
    formulaLatex:
        r'u_{benefit}=\frac{x-min}{max-min},\quad S_i=\sum_j w_j u_{ij}',
    assumptions: DecisionMatrixEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'alternatives',
        label: 'تعداد گزینه‌ها',
        defaultValue: 3,
        min: 2,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح ۲ تا ۲۰؛ هر گزینه یک سطر ماتریس.',
      ),
      NumericFieldDefinition(
        id: 'criteria',
        label: 'تعداد معیارها',
        defaultValue: 2,
        min: 1,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح ۱ تا ۲۰؛ هر معیار یک ستون.',
      ),
      NumberListFieldDefinition(
        id: 'matrix',
        label: 'ماتریس؛ خانه‌ها به ترتیب سطری',
        maxItems: 400,
        defaultValue: [3, 1, 2, 2, 1, 3],
        help: 'هر عدد در یک سطر: ابتدا تمام معیارهای گزینهٔ اول، سپس گزینهٔ دوم و ...؛ تعداد دقیقاً گزینه×معیار.',
      ),
      NumberListFieldDefinition(
        id: 'weights',
        label: 'وزن معیارها',
        maxItems: 20,
        defaultValue: [0.6, 0.4],
        min: 0,
        help: 'وزن نسبی نامنفی؛ حداقل یکی مثبت. جمع لازم نیست یک باشد و به‌صراحت نرمال می‌شود؛ صفر یعنی بدون سهم.',
      ),
      NumberListFieldDefinition(
        id: 'directions',
        label: 'نوع هر معیار: منفعت یا هزینه',
        maxItems: 20,
        defaultValue: [1, 1],
        min: -1,
        max: 1,
        help:
            'برای هر ستون ۱=بیشتر بهتر، منفی ۱=کمتر بهتر؛ تعداد برابر معیارها.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ مرجع قابل بررسی',
        inputs: RawCalculatorInput({
          'alternatives': const RawTextInput('3'),
          'criteria': const RawTextInput('2'),
          'matrix': RawNumberListInput(['3', '1', '2', '2', '1', '3']),
          'weights': RawNumberListInput(['0.6', '0.4']),
          'directions': RawNumberListInput(['1', '1']),
        }),
        explanation: 'سه گزینه (۳،۱)،(۲،۲)،(۱،۳)، دو معیار منفعت و وزن‌های ۰٫۶/۰٫۴: امتیازها ۰٫۶،۰٫۵،۰٫۴.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'decision_matrix',
            label: 'نتیجهٔ مرجع نمونه',
            value: NumericResultValue(0.6, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'decision_matrix',
        nameFa: 'ماتریس تصمیم با نرمال‌سازی',
        nameEn: 'Min-max Decision Matrix',
        description: DecisionMatrixEngine.basis,
      ),
    ],
  );
  static final decisionMatrixRunner = CalculatorRunner(
    definition: decisionMatrix,
    engine: const DecisionMatrixEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final expectedValueTree = CalculatorDefinition(
    id: 'expected_value_tree',
    categoryId: CalculatorCategoryId.decisionMaking,
    nameFa: 'درخت تصمیم؛ ارزش مورد انتظار',
    nameEn: 'Decision Tree Expected Monetary Value',
    aliases: ['expected value tree'],
    description: 'درخت تصمیم؛ ارزش مورد انتظار؛ خروجی مشروط به داده و فرض‌های مدل، نه انتخاب قطعی. تغییر ابعاد نیازمند دادهٔ هم‌اندازه است؛ مقدار ناقص حدس زده نمی‌شود.',
    formulaLatex: r'V_{chance}=\sum p_kV_k,\quad V_{decision}=\max_k V_k',
    assumptions: ExpectedValueTreeEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'root_id',
        label: 'شناسهٔ ریشه',
        defaultValue: 1,
        min: 1,
        max: 999999,
        integerOnly: true,
        help: 'عدد صحیح شناسهٔ گرهٔ موجود، نه شمارهٔ ردیف.',
      ),
      NumberListFieldDefinition(
        id: 'node_ids',
        label: 'شناسهٔ گره‌ها',
        maxItems: 100,
        defaultValue: [1, 2, 3, 4, 5, 6, 7],
        min: 1,
        max: 999999,
        help: 'شناسهٔ صحیح یکتا؛ ستون‌های نوع/عایدی هم‌ردیف‌اند.',
      ),
      NumberListFieldDefinition(
        id: 'node_types',
        label: 'نوع گره‌ها به همان ترتیب',
        maxItems: 100,
        defaultValue: [2, 1, 1, 0, 0, 0, 0],
        min: 0,
        max: 2,
        help: 'صفر=پایانی، یک=احتمالی، دو=تصمیم. درخت از والد به فرزند است.',
      ),
      NumberListFieldDefinition(
        id: 'payoffs',
        label: 'عایدی خالص گره‌ها به همان ترتیب',
        maxItems: 100,
        defaultValue: [0, 0, 0, 100, -20, 80, 10],
        help: 'پایانه: ریال خالص مثبت/منفی؛ غیرپایانه باید صفر باشد. عایدی‌ها هم‌زمان یا قبلاً تنزیل‌شده و هم‌ارزند.',
      ),
      NumberListFieldDefinition(
        id: 'from_ids',
        label: 'سر یال‌ها؛ شناسهٔ والد',
        maxItems: 99,
        defaultValue: [1, 1, 2, 2, 3, 3],
        min: 1,
        max: 999999,
        isRequired: false,
        minItems: 0,
        help: 'هر ردیف همراه ته و ضریب، یک یال است؛ برای درخت تک‌پایانه هر سه ستون یال را خالی کنید.',
      ),
      NumberListFieldDefinition(
        id: 'to_ids',
        label: 'ته یال‌ها؛ شناسهٔ فرزند',
        maxItems: 99,
        defaultValue: [2, 3, 4, 5, 6, 7],
        min: 1,
        max: 999999,
        isRequired: false,
        minItems: 0,
        help: 'هم‌اندازه با سر/ضریب؛ هر گره جز ریشه یک والد. ارجاع نامعتبر، چرخه یا اشتراک زیرشاخه رد می‌شود.',
      ),
      NumberListFieldDefinition(
        id: 'probabilities',
        label: 'احتمال یال تصادفی / ضریب یال تصمیم',
        maxItems: 99,
        defaultValue: [1, 1, 0.6, 0.4, 0.5, 0.5],
        min: 0,
        max: 1,
        isRequired: false,
        minItems: 0,
        help: 'برای والد احتمالی p در صفر تا یک و جمع فرزندان یک؛ برای والد تصمیم فقط ضریب یک، نه احتمال انتخاب.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ مرجع قابل بررسی',
        inputs: RawCalculatorInput({
          'root_id': const RawTextInput('1'),
          'node_ids': RawNumberListInput(['1', '2', '3', '4', '5', '6', '7']),
          'node_types': RawNumberListInput(['2', '1', '1', '0', '0', '0', '0']),
          'payoffs': RawNumberListInput([
            '0',
            '0',
            '0',
            '100',
            '-20',
            '80',
            '10',
          ]),
          'from_ids': RawNumberListInput(['1', '1', '2', '2', '3', '3']),
          'to_ids': RawNumberListInput(['2', '3', '4', '5', '6', '7']),
          'probabilities': RawNumberListInput([
            '1',
            '1',
            '0.6',
            '0.4',
            '0.5',
            '0.5',
          ]),
        }),
        explanation: 'ریشه بین شاخهٔ احتمالی با ۰٫۶×۱۰۰+۰٫۴×(−۲۰)=۵۲ و شاخهٔ ۰٫۵×۸۰+۰٫۵×۱۰=۴۵ انتخاب می‌کند؛ در مدل ریسک‌خنثی ارزش ریشه ۵۲ ریال است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'expected_value_tree',
            label: 'نتیجهٔ مرجع نمونه',
            value: NumericResultValue(52, unit: 'ریال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'expected_value_tree',
        nameFa: 'درخت تصمیم؛ ارزش مورد انتظار',
        nameEn: 'Decision Tree Expected Monetary Value',
        description: ExpectedValueTreeEngine.basis,
      ),
    ],
  );
  static final expectedValueTreeRunner = CalculatorRunner(
    definition: expectedValueTree,
    engine: const ExpectedValueTreeEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final weightSensitivity = CalculatorDefinition(
    id: 'weight_sensitivity',
    categoryId: CalculatorCategoryId.decisionMaking,
    nameFa: 'تحلیل حساسیت تک‌معیار وزن',
    nameEn: 'One-at-a-time Weight Sensitivity',
    aliases: ['weight sensitivity'],
    description: 'تحلیل حساسیت تک‌معیار وزن؛ خروجی مشروط به داده و فرض‌های مدل، نه انتخاب قطعی. تغییر ابعاد نیازمند دادهٔ هم‌اندازه است؛ مقدار ناقص حدس زده نمی‌شود.',
    formulaLatex:
        r'w_j=t,\quad w_k=(1-t)\frac{w_{k,base}}{\sum_{l\ne j}w_{l,base}}',
    assumptions: WeightSensitivityEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'alternatives',
        label: 'تعداد گزینه‌ها',
        defaultValue: 3,
        min: 2,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح ۲ تا ۲۰؛ هر گزینه یک سطر ماتریس.',
      ),
      NumericFieldDefinition(
        id: 'criteria',
        label: 'تعداد معیارها',
        defaultValue: 2,
        min: 1,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح ۱ تا ۲۰؛ هر معیار یک ستون.',
      ),
      NumberListFieldDefinition(
        id: 'matrix',
        label: 'ماتریس؛ خانه‌ها به ترتیب سطری',
        maxItems: 400,
        defaultValue: [3, 1, 2, 2, 1, 3],
        help: 'هر عدد در یک سطر: ابتدا تمام معیارهای گزینهٔ اول، سپس گزینهٔ دوم و ...؛ تعداد دقیقاً گزینه×معیار.',
      ),
      NumberListFieldDefinition(
        id: 'weights',
        label: 'وزن معیارها',
        maxItems: 20,
        defaultValue: [0.6, 0.4],
        min: 0,
        help: 'وزن نسبی نامنفی؛ حداقل یکی مثبت. جمع لازم نیست یک باشد و به‌صراحت نرمال می‌شود؛ صفر یعنی بدون سهم.',
      ),
      NumberListFieldDefinition(
        id: 'directions',
        label: 'نوع هر معیار: منفعت یا هزینه',
        maxItems: 20,
        defaultValue: [1, 1],
        min: -1,
        max: 1,
        help:
            'برای هر ستون ۱=بیشتر بهتر، منفی ۱=کمتر بهتر؛ تعداد برابر معیارها.',
      ),
      NumericFieldDefinition(
        id: 'selected_criterion',
        label: 'شمارهٔ معیار برای تغییر وزن',
        defaultValue: 1,
        min: 1,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح یک‌مبنا در محدودهٔ معیارهای ماتریس.',
      ),
      NumberListFieldDefinition(
        id: 'sweep_weights',
        label: 'وزن‌های سناریوی معیار منتخب',
        maxItems: 21,
        defaultValue: [0, 0.5, 1],
        min: 0,
        max: 1,
        help: 'هر سطر یک کسر از صفر تا یک، نه درصد؛ حداکثر ۲۱ سناریو. وزن بقیه به نسبت وزن‌های اولیه بازتوزیع می‌شود.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ مرجع قابل بررسی',
        inputs: RawCalculatorInput({
          'alternatives': const RawTextInput('3'),
          'criteria': const RawTextInput('2'),
          'matrix': RawNumberListInput(['3', '1', '2', '2', '1', '3']),
          'weights': RawNumberListInput(['0.6', '0.4']),
          'directions': RawNumberListInput(['1', '1']),
          'selected_criterion': const RawTextInput('1'),
          'sweep_weights': RawNumberListInput(['0', '0.5', '1']),
        }),
        explanation: 'در ماتریس نمونه با معیار اول، وزن‌های سناریو ۰،۰٫۵،۱: گزینهٔ سوم، سپس هر سه هم‌رتبه، سپس گزینهٔ اول بالاترند؛ امتیاز پایهٔ بیشینه ۰٫۶ است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'weight_sensitivity',
            label: 'نتیجهٔ مرجع نمونه',
            value: NumericResultValue(0.6, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'weight_sensitivity',
        nameFa: 'تحلیل حساسیت تک‌معیار وزن',
        nameEn: 'One-at-a-time Weight Sensitivity',
        description: WeightSensitivityEngine.basis,
      ),
    ],
  );
  static final weightSensitivityRunner = CalculatorRunner(
    definition: weightSensitivity,
    engine: const WeightSensitivityEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final weightedScoring = CalculatorDefinition(
    id: 'weighted_scoring',
    categoryId: CalculatorCategoryId.decisionMaking,
    nameFa: 'امتیازدهی وزنی روی مقیاس مشترک',
    nameEn: 'Weighted Scoring Common Scale',
    aliases: ['weighted scoring'],
    description: 'امتیازدهی وزنی روی مقیاس مشترک؛ خروجی مشروط به داده و فرض‌های مدل، نه انتخاب قطعی. تغییر ابعاد نیازمند دادهٔ هم‌اندازه است؛ مقدار ناقص حدس زده نمی‌شود.',
    formulaLatex: r'S_i=\sum_j \frac{w_j}{\sum_k w_k}x_{ij}',
    assumptions: WeightedScoringEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'alternatives',
        label: 'تعداد گزینه‌ها',
        defaultValue: 3,
        min: 2,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح ۲ تا ۲۰؛ هر گزینه یک سطر ماتریس.',
      ),
      NumericFieldDefinition(
        id: 'criteria',
        label: 'تعداد معیارها',
        defaultValue: 2,
        min: 1,
        max: 20,
        integerOnly: true,
        help: 'عدد صحیح ۱ تا ۲۰؛ هر معیار یک ستون.',
      ),
      NumberListFieldDefinition(
        id: 'matrix',
        label: 'ماتریس؛ خانه‌ها به ترتیب سطری',
        maxItems: 400,
        defaultValue: [8, 6, 7, 9, 9, 5],
        help: 'هر عدد در یک سطر: ابتدا تمام معیارهای گزینهٔ اول، سپس گزینهٔ دوم و ...؛ تعداد دقیقاً گزینه×معیار.',
      ),
      NumberListFieldDefinition(
        id: 'weights',
        label: 'وزن معیارها',
        maxItems: 20,
        defaultValue: [0.6, 0.4],
        min: 0,
        help: 'وزن نسبی نامنفی؛ حداقل یکی مثبت. جمع لازم نیست یک باشد و به‌صراحت نرمال می‌شود؛ صفر یعنی بدون سهم.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ مرجع قابل بررسی',
        inputs: RawCalculatorInput({
          'alternatives': const RawTextInput('3'),
          'criteria': const RawTextInput('2'),
          'matrix': RawNumberListInput(['8', '6', '7', '9', '9', '5']),
          'weights': RawNumberListInput(['0.6', '0.4']),
        }),
        explanation: 'امتیازهای هم‌مقیاس (۸،۶)،(۷،۹)،(۹،۵) و وزن ۰٫۶/۰٫۴: ۷٫۲،۷٫۸،۷٫۴؛ گزینهٔ دوم در این مدل بالاتر است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'weighted_scoring',
            label: 'نتیجهٔ مرجع نمونه',
            value: NumericResultValue(7.8, unit: null),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'weighted_scoring',
        nameFa: 'امتیازدهی وزنی روی مقیاس مشترک',
        nameEn: 'Weighted Scoring Common Scale',
        description: WeightedScoringEngine.basis,
      ),
    ],
  );
  static final weightedScoringRunner = CalculatorRunner(
    definition: weightedScoring,
    engine: const WeightedScoringEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final costBenefitComparison = CalculatorDefinition(
    id: 'cost_benefit_comparison',
    categoryId: CalculatorCategoryId.decisionMaking,
    nameFa: 'مقایسهٔ هزینه و منفعت دو گزینه',
    nameEn: 'Two-option Cost Benefit Comparison',
    aliases: ['cost benefit comparison'],
    description: 'مقایسهٔ هزینه و منفعت دو گزینه؛ خروجی مشروط به داده و فرض‌های مدل، نه انتخاب قطعی. تغییر ابعاد نیازمند دادهٔ هم‌اندازه است؛ مقدار ناقص حدس زده نمی‌شود.',
    formulaLatex: r'NB_i=B_i-C_i,\quad \Delta NB=NB_B-NB_A',
    assumptions: CostBenefitComparisonEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'cost_a',
        label: 'هزینهٔ گزینهٔ A',
        unit: 'ریال',
        defaultValue: 100,
        min: 0,
        help: 'نامنفی؛ تمام هزینه‌های پولی بدون هم‌پوشانی در افق مشترک.',
      ),
      NumericFieldDefinition(
        id: 'benefit_a',
        label: 'منفعت گزینهٔ A',
        unit: 'ریال',
        defaultValue: 160,
        min: 0,
        help:
            'نامنفی؛ منفعت پولی با مبنای ارزش‌گذاری مستند؛ با هزینه خلط نشود.',
      ),
      NumericFieldDefinition(
        id: 'cost_b',
        label: 'هزینهٔ گزینهٔ B',
        unit: 'ریال',
        defaultValue: 120,
        min: 0,
        help: 'نامنفی و هم‌مبنا با گزینهٔ A.',
      ),
      NumericFieldDefinition(
        id: 'benefit_b',
        label: 'منفعت گزینهٔ B',
        unit: 'ریال',
        defaultValue: 210,
        min: 0,
        help: 'نامنفی و هم‌مبنا؛ منافع غیرپولی خودکار تبدیل نمی‌شوند.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'افق مشترک مقایسه',
        unit: 'روز',
        defaultValue: 365,
        min: 0,
        help: 'مثبت؛ هر دو گزینه باید بر همین دامنه و افق باشند. نقش زمینه دارد و سالانه‌سازی/تنزیل خودکار انجام نمی‌دهد.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ مرجع قابل بررسی',
        inputs: RawCalculatorInput({
          'cost_a': const RawTextInput('100'),
          'benefit_a': const RawTextInput('160'),
          'cost_b': const RawTextInput('120'),
          'benefit_b': const RawTextInput('210'),
          'period_days': const RawTextInput('365'),
        }),
        explanation: 'A: هزینهٔ ۱۰۰ و منفعت ۱۶۰، B: هزینهٔ ۱۲۰ و منفعت ۲۱۰ در افق یکسان؛ خالص‌ها ۶۰ و۹۰ و اختلاف B نسبت به A برابر +۳۰ ریال است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'cost_benefit_comparison',
            label: 'نتیجهٔ مرجع نمونه',
            value: NumericResultValue(30, unit: 'ریال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'cost_benefit_comparison',
        nameFa: 'مقایسهٔ هزینه و منفعت دو گزینه',
        nameEn: 'Two-option Cost Benefit Comparison',
        description: CostBenefitComparisonEngine.basis,
      ),
    ],
  );
  static final costBenefitComparisonRunner = CalculatorRunner(
    definition: costBenefitComparison,
    engine: const CostBenefitComparisonEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final twoOptionBreakEven = CalculatorDefinition(
    id: 'two_option_break_even',
    categoryId: CalculatorCategoryId.decisionMaking,
    nameFa: 'نقطهٔ سربه‌سر هزینهٔ دو گزینه',
    nameEn: 'Two-option Cost Crossover',
    aliases: ['two option break even'],
    description: 'نقطهٔ سربه‌سر هزینهٔ دو گزینه؛ خروجی مشروط به داده و فرض‌های مدل، نه انتخاب قطعی. تغییر ابعاد نیازمند دادهٔ هم‌اندازه است؛ مقدار ناقص حدس زده نمی‌شود.',
    formulaLatex: r'Q^*=\frac{F_B-F_A}{v_A-v_B}',
    assumptions: TwoOptionBreakEvenEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'fixed_a',
        label: 'هزینهٔ ثابت A',
        unit: 'ریال',
        defaultValue: 100,
        min: 0,
        help: 'نامنفی، برای افق و ظرفیت تعریف‌شده؛ نه هزینهٔ متغیر هر واحد.',
      ),
      NumericFieldDefinition(
        id: 'variable_a',
        label: 'هزینهٔ متغیر واحد A',
        unit: 'ریال/واحد',
        defaultValue: 5,
        min: 0,
        help: 'نامنفی و ثابت در دامنهٔ مقدار مورد بررسی.',
      ),
      NumericFieldDefinition(
        id: 'fixed_b',
        label: 'هزینهٔ ثابت B',
        unit: 'ریال',
        defaultValue: 200,
        min: 0,
        help: 'نامنفی و مربوط به همان افق A.',
      ),
      NumericFieldDefinition(
        id: 'variable_b',
        label: 'هزینهٔ متغیر واحد B',
        unit: 'ریال/واحد',
        defaultValue: 3,
        min: 0,
        help: 'نامنفی و بر همان واحد مقدار.',
      ),
      NumericFieldDefinition(
        id: 'period_days',
        label: 'افق مشترک مقایسه',
        unit: 'روز',
        defaultValue: 365,
        min: 0,
        help: 'مثبت؛ هر دو گزینه باید بر همین دامنه و افق باشند. نقش زمینه دارد و سالانه‌سازی/تنزیل خودکار انجام نمی‌دهد.',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'نمونهٔ مرجع قابل بررسی',
        inputs: RawCalculatorInput({
          'fixed_a': const RawTextInput('100'),
          'variable_a': const RawTextInput('5'),
          'fixed_b': const RawTextInput('200'),
          'variable_b': const RawTextInput('3'),
          'period_days': const RawTextInput('365'),
        }),
        explanation: 'A=۱۰۰+۵Q و B=۲۰۰+۳Q ⇒ تقاطع Q=۵۰ و هزینهٔ هر دو ۳۵۰ ریال؛ بالاتر از آن B در همین مدل کم‌هزینه‌تر است.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'two_option_break_even',
            label: 'نتیجهٔ مرجع نمونه',
            value: NumericResultValue(50, unit: 'واحد'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'two_option_break_even',
        nameFa: 'نقطهٔ سربه‌سر هزینهٔ دو گزینه',
        nameEn: 'Two-option Cost Crossover',
        description: TwoOptionBreakEvenEngine.basis,
      ),
    ],
  );
  static final twoOptionBreakEvenRunner = CalculatorRunner(
    definition: twoOptionBreakEven,
    engine: const TwoOptionBreakEvenEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        ahpRunner,
        topsisRunner,
        decisionMatrixRunner,
        expectedValueTreeRunner,
        weightSensitivityRunner,
        weightedScoringRunner,
        costBenefitComparisonRunner,
        twoOptionBreakEvenRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((r) => r.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({for (final r in runners) r.definition.id: r});
}
