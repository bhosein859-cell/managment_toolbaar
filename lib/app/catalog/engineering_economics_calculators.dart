import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/domain/engines/engineering_economics/annuity_future_factor_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/annuity_present_factor_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/declining_balance_depreciation_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/future_annuity_factor_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/future_present_factor_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/inflation_adjustment_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/present_annuity_factor_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/present_future_factor_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/straight_line_depreciation_engine.dart';
import '../../features/calculators/domain/engines/engineering_economics/time_value_money_engine.dart';

abstract final class EngineeringEconomicsCalculators {
  static final timeValueMoney = CalculatorDefinition(
    id: 'time_value_money',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'ارزش زمانی پول؛ رشد مرکب',
    nameEn: 'Time Value of Money',
    aliases: ['time_value_money'],
    description: 'ارزش زمانی پول؛ رشد مرکب؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'F=P(1+i)^n,\quad I=F-P',
    assumptions: TimeValueMoneyEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'مبلغ امروز P در زمان صفر',
        defaultValue: 1000,
        help: 'قدر مطلق جریان نامنفی، با واحد پول یکسان؛ عامل برای دریافت یا پرداخت یک‌جهت یکسان است و علامت سود/NPV را تعیین نمی‌کند.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ مؤثر هر دوره',
        defaultValue: 10,
        help: 'درصد مؤثر ثابت هر دوره؛ ۱۰ یعنی ۱۰٪ نه ۰٫۱٪. باید بیشتر از منفی ۱۰۰٪ باشد؛ نرخ منفی بالاتر از این حد مجاز است. نرخ اسمی سالانه با دورهٔ ماهانه را مستقیم وارد نکنید.',
        min: -100,
        kind: NumericInputKind.percentage,
        unit: '٪/دوره',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های هم‌اندازه',
        defaultValue: 3,
        help: 'عدد صحیح ۰ تا ۱۰۰۰۰؛ نرخ و فاصلهٔ زمانی جریان‌ها باید دقیقاً همین دوره باشد. یک دوره می‌تواند ماه یا سال باشد، بدون تبدیل خودکار.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'دوره',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1000'),
          'rate': const RawTextInput('10'),
          'periods': const RawTextInput('3'),
        }),
        explanation: '۱۰۰۰ ریال امروز با نرخ مؤثر ۱۰٪ در هر دوره، پس از ۳ دوره: ۱۰۰۰×۱٫۱³=۱۳۳۱ ریال؛ افزایش ۳۳۱ ریال.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'time_value_money',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(1331, unit: 'ریال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'time_value_money',
        nameFa: 'ارزش زمانی پول؛ رشد مرکب',
        nameEn: 'Time Value of Money',
        description: TimeValueMoneyEngine.basis,
      ),
    ],
  );
  static final timeValueMoneyRunner = CalculatorRunner(
    definition: timeValueMoney,
    engine: const TimeValueMoneyEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final futurePresentFactor = CalculatorDefinition(
    id: 'future_present_factor',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'عامل F/P',
    nameEn: 'Single Payment Compound Amount Factor',
    aliases: ['fp', 'F/P'],
    description: 'عامل F/P؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'(F/P,i,n)=(1+i)^n',
    assumptions: FuturePresentFactorEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'مبلغ امروز P در زمان صفر',
        defaultValue: 1000,
        help: 'قدر مطلق جریان نامنفی، با واحد پول یکسان؛ عامل برای دریافت یا پرداخت یک‌جهت یکسان است و علامت سود/NPV را تعیین نمی‌کند.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ مؤثر هر دوره',
        defaultValue: 10,
        help: 'درصد مؤثر ثابت هر دوره؛ ۱۰ یعنی ۱۰٪ نه ۰٫۱٪. باید بیشتر از منفی ۱۰۰٪ باشد؛ نرخ منفی بالاتر از این حد مجاز است. نرخ اسمی سالانه با دورهٔ ماهانه را مستقیم وارد نکنید.',
        min: -100,
        kind: NumericInputKind.percentage,
        unit: '٪/دوره',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های هم‌اندازه',
        defaultValue: 3,
        help: 'عدد صحیح ۰ تا ۱۰۰۰۰؛ نرخ و فاصلهٔ زمانی جریان‌ها باید دقیقاً همین دوره باشد. یک دوره می‌تواند ماه یا سال باشد، بدون تبدیل خودکار.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'دوره',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1000'),
          'rate': const RawTextInput('10'),
          'periods': const RawTextInput('3'),
        }),
        explanation: '۱٫۱³=۱٫۳۳۱؛ P=۱۰۰۰ ⇒ F=۱۳۳۱.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'future_present_factor',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(1.331, unit: 'برابر'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'future_present_factor',
        nameFa: 'عامل F/P',
        nameEn: 'Single Payment Compound Amount Factor',
        description: FuturePresentFactorEngine.basis,
      ),
    ],
  );
  static final futurePresentFactorRunner = CalculatorRunner(
    definition: futurePresentFactor,
    engine: const FuturePresentFactorEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final presentFutureFactor = CalculatorDefinition(
    id: 'present_future_factor',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'عامل P/F',
    nameEn: 'Single Payment Present Worth Factor',
    aliases: ['pf', 'P/F'],
    description: 'عامل P/F؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'(P/F,i,n)=(1+i)^{-n}',
    assumptions: PresentFutureFactorEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'تک‌مبلغ آینده F در پایان n',
        defaultValue: 1000,
        help: 'قدر مطلق جریان نامنفی، با واحد پول یکسان؛ عامل برای دریافت یا پرداخت یک‌جهت یکسان است و علامت سود/NPV را تعیین نمی‌کند.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ مؤثر هر دوره',
        defaultValue: 10,
        help: 'درصد مؤثر ثابت هر دوره؛ ۱۰ یعنی ۱۰٪ نه ۰٫۱٪. باید بیشتر از منفی ۱۰۰٪ باشد؛ نرخ منفی بالاتر از این حد مجاز است. نرخ اسمی سالانه با دورهٔ ماهانه را مستقیم وارد نکنید.',
        min: -100,
        kind: NumericInputKind.percentage,
        unit: '٪/دوره',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های هم‌اندازه',
        defaultValue: 3,
        help: 'عدد صحیح ۰ تا ۱۰۰۰۰؛ نرخ و فاصلهٔ زمانی جریان‌ها باید دقیقاً همین دوره باشد. یک دوره می‌تواند ماه یا سال باشد، بدون تبدیل خودکار.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'دوره',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1000'),
          'rate': const RawTextInput('10'),
          'periods': const RawTextInput('3'),
        }),
        explanation: '۱/۱٫۱³≈۰٫۷۵۱۳۱۴۸؛ F=۱۰۰۰ ⇒ P≈۷۵۱٫۳۱۴۸.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'present_future_factor',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(0.7513148009015778, unit: 'برابر'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'present_future_factor',
        nameFa: 'عامل P/F',
        nameEn: 'Single Payment Present Worth Factor',
        description: PresentFutureFactorEngine.basis,
      ),
    ],
  );
  static final presentFutureFactorRunner = CalculatorRunner(
    definition: presentFutureFactor,
    engine: const PresentFutureFactorEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final futureAnnuityFactor = CalculatorDefinition(
    id: 'future_annuity_factor',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'عامل F/A',
    nameEn: 'Uniform Series Compound Amount Factor',
    aliases: ['fa', 'F/A'],
    description: 'عامل F/A؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'(F/A,i,n)=\frac{(1+i)^n-1}{i}',
    assumptions: FutureAnnuityFactorEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'هر پرداخت مساوی A در پایان دوره',
        defaultValue: 1000,
        help: 'قدر مطلق جریان نامنفی، با واحد پول یکسان؛ عامل برای دریافت یا پرداخت یک‌جهت یکسان است و علامت سود/NPV را تعیین نمی‌کند.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ مؤثر هر دوره',
        defaultValue: 10,
        help: 'درصد مؤثر ثابت هر دوره؛ ۱۰ یعنی ۱۰٪ نه ۰٫۱٪. باید بیشتر از منفی ۱۰۰٪ باشد؛ نرخ منفی بالاتر از این حد مجاز است. نرخ اسمی سالانه با دورهٔ ماهانه را مستقیم وارد نکنید.',
        min: -100,
        kind: NumericInputKind.percentage,
        unit: '٪/دوره',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های هم‌اندازه',
        defaultValue: 3,
        help: 'عدد صحیح ۰ تا ۱۰۰۰۰؛ نرخ و فاصلهٔ زمانی جریان‌ها باید دقیقاً همین دوره باشد. یک دوره می‌تواند ماه یا سال باشد، بدون تبدیل خودکار.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'دوره',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1000'),
          'rate': const RawTextInput('10'),
          'periods': const RawTextInput('3'),
        }),
        explanation: '۱+۱٫۱+۱٫۲۱=۳٫۳۱؛ A=۱۰۰۰ ⇒ F=۳۳۱۰.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'future_annuity_factor',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(3.31, unit: 'برابر'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'future_annuity_factor',
        nameFa: 'عامل F/A',
        nameEn: 'Uniform Series Compound Amount Factor',
        description: FutureAnnuityFactorEngine.basis,
      ),
    ],
  );
  static final futureAnnuityFactorRunner = CalculatorRunner(
    definition: futureAnnuityFactor,
    engine: const FutureAnnuityFactorEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final annuityFutureFactor = CalculatorDefinition(
    id: 'annuity_future_factor',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'عامل A/F',
    nameEn: 'Sinking Fund Factor',
    aliases: ['af', 'A/F'],
    description: 'عامل A/F؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'(A/F,i,n)=\frac{i}{(1+i)^n-1}',
    assumptions: AnnuityFutureFactorEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'هدف آینده F پس از آخرین پرداخت',
        defaultValue: 1000,
        help: 'قدر مطلق جریان نامنفی، با واحد پول یکسان؛ عامل برای دریافت یا پرداخت یک‌جهت یکسان است و علامت سود/NPV را تعیین نمی‌کند.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ مؤثر هر دوره',
        defaultValue: 10,
        help: 'درصد مؤثر ثابت هر دوره؛ ۱۰ یعنی ۱۰٪ نه ۰٫۱٪. باید بیشتر از منفی ۱۰۰٪ باشد؛ نرخ منفی بالاتر از این حد مجاز است. نرخ اسمی سالانه با دورهٔ ماهانه را مستقیم وارد نکنید.',
        min: -100,
        kind: NumericInputKind.percentage,
        unit: '٪/دوره',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های هم‌اندازه',
        defaultValue: 3,
        help: 'عدد صحیح ۰ تا ۱۰۰۰۰؛ نرخ و فاصلهٔ زمانی جریان‌ها باید دقیقاً همین دوره باشد. یک دوره می‌تواند ماه یا سال باشد، بدون تبدیل خودکار.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'دوره',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1000'),
          'rate': const RawTextInput('10'),
          'periods': const RawTextInput('3'),
        }),
        explanation: '۱/۳٫۳۱≈۰٫۳۰۲۱۱۴۸؛ F=۱۰۰۰ ⇒ A≈۳۰۲٫۱۱۴۸.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'annuity_future_factor',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(0.3021148036253776, unit: 'برابر'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'annuity_future_factor',
        nameFa: 'عامل A/F',
        nameEn: 'Sinking Fund Factor',
        description: AnnuityFutureFactorEngine.basis,
      ),
    ],
  );
  static final annuityFutureFactorRunner = CalculatorRunner(
    definition: annuityFutureFactor,
    engine: const AnnuityFutureFactorEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final presentAnnuityFactor = CalculatorDefinition(
    id: 'present_annuity_factor',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'عامل P/A',
    nameEn: 'Uniform Series Present Worth Factor',
    aliases: ['pa', 'P/A'],
    description: 'عامل P/A؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'(P/A,i,n)=\frac{1-(1+i)^{-n}}{i}',
    assumptions: PresentAnnuityFactorEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'هر پرداخت مساوی A در پایان دوره',
        defaultValue: 1000,
        help: 'قدر مطلق جریان نامنفی، با واحد پول یکسان؛ عامل برای دریافت یا پرداخت یک‌جهت یکسان است و علامت سود/NPV را تعیین نمی‌کند.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ مؤثر هر دوره',
        defaultValue: 10,
        help: 'درصد مؤثر ثابت هر دوره؛ ۱۰ یعنی ۱۰٪ نه ۰٫۱٪. باید بیشتر از منفی ۱۰۰٪ باشد؛ نرخ منفی بالاتر از این حد مجاز است. نرخ اسمی سالانه با دورهٔ ماهانه را مستقیم وارد نکنید.',
        min: -100,
        kind: NumericInputKind.percentage,
        unit: '٪/دوره',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های هم‌اندازه',
        defaultValue: 3,
        help: 'عدد صحیح ۰ تا ۱۰۰۰۰؛ نرخ و فاصلهٔ زمانی جریان‌ها باید دقیقاً همین دوره باشد. یک دوره می‌تواند ماه یا سال باشد، بدون تبدیل خودکار.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'دوره',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1000'),
          'rate': const RawTextInput('10'),
          'periods': const RawTextInput('3'),
        }),
        explanation: '۱/۱٫۱+۱/۱٫۲۱+۱/۱٫۳۳۱≈۲٫۴۸۶۸۵۲؛ A=۱۰۰۰ ⇒ P≈۲۴۸۶٫۸۵۲.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'present_annuity_factor',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(2.4868519909842224, unit: 'برابر'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'present_annuity_factor',
        nameFa: 'عامل P/A',
        nameEn: 'Uniform Series Present Worth Factor',
        description: PresentAnnuityFactorEngine.basis,
      ),
    ],
  );
  static final presentAnnuityFactorRunner = CalculatorRunner(
    definition: presentAnnuityFactor,
    engine: const PresentAnnuityFactorEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final annuityPresentFactor = CalculatorDefinition(
    id: 'annuity_present_factor',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'عامل A/P',
    nameEn: 'Capital Recovery Factor',
    aliases: ['ap', 'A/P'],
    description: 'عامل A/P؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'(A/P,i,n)=\frac{i}{1-(1+i)^{-n}}',
    assumptions: AnnuityPresentFactorEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'مبلغ امروز P برای بازیافت با اقساط A',
        defaultValue: 1000,
        help: 'قدر مطلق جریان نامنفی، با واحد پول یکسان؛ عامل برای دریافت یا پرداخت یک‌جهت یکسان است و علامت سود/NPV را تعیین نمی‌کند.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ مؤثر هر دوره',
        defaultValue: 10,
        help: 'درصد مؤثر ثابت هر دوره؛ ۱۰ یعنی ۱۰٪ نه ۰٫۱٪. باید بیشتر از منفی ۱۰۰٪ باشد؛ نرخ منفی بالاتر از این حد مجاز است. نرخ اسمی سالانه با دورهٔ ماهانه را مستقیم وارد نکنید.',
        min: -100,
        kind: NumericInputKind.percentage,
        unit: '٪/دوره',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های هم‌اندازه',
        defaultValue: 3,
        help: 'عدد صحیح ۰ تا ۱۰۰۰۰؛ نرخ و فاصلهٔ زمانی جریان‌ها باید دقیقاً همین دوره باشد. یک دوره می‌تواند ماه یا سال باشد، بدون تبدیل خودکار.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'دوره',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1000'),
          'rate': const RawTextInput('10'),
          'periods': const RawTextInput('3'),
        }),
        explanation: '۱/۲٫۴۸۶۸۵۲≈۰٫۴۰۲۱۱۴۸؛ P=۱۰۰۰ ⇒ A≈۴۰۲٫۱۱۴۸.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'annuity_present_factor',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(0.4021148036253776, unit: 'برابر'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'annuity_present_factor',
        nameFa: 'عامل A/P',
        nameEn: 'Capital Recovery Factor',
        description: AnnuityPresentFactorEngine.basis,
      ),
    ],
  );
  static final annuityPresentFactorRunner = CalculatorRunner(
    definition: annuityPresentFactor,
    engine: const AnnuityPresentFactorEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final straightLineDepreciation = CalculatorDefinition(
    id: 'straight_line_depreciation',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'استهلاک خط مستقیم',
    nameEn: 'Straight Line Depreciation',
    aliases: ['straight_line_depreciation'],
    description: 'استهلاک خط مستقیم؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'D=(C-S)/L,\quad B_k=C-kD',
    assumptions: StraightLineDepreciationEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'cost',
        label: 'بهای تمام‌شده دارایی',
        defaultValue: 1000,
        help: 'نامنفی؛ بهای اولیهٔ دارایی در زمان صفر، بدون تجدید ارزیابی یا مالیات.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'salvage',
        label: 'ارزش اسقاط؛ کف ارزش دفتری',
        defaultValue: 100,
        help: 'نامنفی و حداکثر برابر بهای تمام‌شده؛ با همان واحد پول.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'life',
        label: 'عمر مفید',
        defaultValue: 5,
        help: 'تعداد صحیح سال؛ ۱ تا ۱۰۰۰۰. این مدل سال کامل دارد و قرارداد نیم‌سال/ماهانه خودکار نیست.',
        min: 1,
        max: 10000,
        integerOnly: true,
        unit: 'سال',
      ),
      NumericFieldDefinition(
        id: 'year',
        label: 'سال مورد بررسی',
        defaultValue: 2,
        help: 'صحیح از صفر تا عمر مفید؛ صفر زمان خرید و بدون هزینهٔ استهلاک آن سال است. ارزش ابتدا و پایان سال و استهلاک انباشته گزارش می‌شود.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'سال',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'cost': const RawTextInput('1000'),
          'salvage': const RawTextInput('100'),
          'life': const RawTextInput('5'),
          'year': const RawTextInput('2'),
        }),
        explanation: 'بهای ۱۰۰۰، اسقاط ۱۰۰ و عمر ۵ سال: استهلاک سالانه ۱۸۰؛ سال دوم انباشته ۳۶۰ و ارزش پایان سال ۶۴۰.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'straight_line_depreciation',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(180, unit: 'ریال/سال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'straight_line_depreciation',
        nameFa: 'استهلاک خط مستقیم',
        nameEn: 'Straight Line Depreciation',
        description: StraightLineDepreciationEngine.basis,
      ),
    ],
  );
  static final straightLineDepreciationRunner = CalculatorRunner(
    definition: straightLineDepreciation,
    engine: const StraightLineDepreciationEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final decliningBalanceDepreciation = CalculatorDefinition(
    id: 'declining_balance_depreciation',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'استهلاک ماندهٔ نزولی',
    nameEn: 'Declining Balance Depreciation',
    aliases: ['declining_balance_depreciation'],
    description: 'استهلاک ماندهٔ نزولی؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'B_k=\max(S,C(1-d)^k),\quad D_k=B_{k-1}-B_k',
    assumptions: DecliningBalanceDepreciationEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'cost',
        label: 'بهای تمام‌شده دارایی',
        defaultValue: 1000,
        help: 'نامنفی؛ بهای اولیهٔ دارایی در زمان صفر، بدون تجدید ارزیابی یا مالیات.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'salvage',
        label: 'ارزش اسقاط؛ کف ارزش دفتری',
        defaultValue: 100,
        help: 'نامنفی و حداکثر برابر بهای تمام‌شده؛ با همان واحد پول.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'depreciation_rate',
        label: 'نرخ ثابت استهلاک مانده نزولی',
        defaultValue: 20,
        help: 'درصد سالانه از ارزش دفتری ابتدای سال، در بازهٔ ۰ تا ۱۰۰٪؛ نرخ تنزیل یا نرخ تورم نیست. نرخ صفر بدون استهلاک و نرخ ۱۰۰٪ رسیدن به کف در سال اول است.',
        min: 0,
        max: 100,
        kind: NumericInputKind.percentage,
        unit: '٪/سال',
      ),
      NumericFieldDefinition(
        id: 'life',
        label: 'عمر مفید',
        defaultValue: 5,
        help: 'تعداد صحیح سال؛ ۱ تا ۱۰۰۰۰. این مدل سال کامل دارد و قرارداد نیم‌سال/ماهانه خودکار نیست.',
        min: 1,
        max: 10000,
        integerOnly: true,
        unit: 'سال',
      ),
      NumericFieldDefinition(
        id: 'year',
        label: 'سال مورد بررسی',
        defaultValue: 2,
        help: 'صحیح از صفر تا عمر مفید؛ صفر زمان خرید و بدون هزینهٔ استهلاک آن سال است. ارزش ابتدا و پایان سال و استهلاک انباشته گزارش می‌شود.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'سال',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'cost': const RawTextInput('1000'),
          'salvage': const RawTextInput('100'),
          'depreciation_rate': const RawTextInput('20'),
          'life': const RawTextInput('5'),
          'year': const RawTextInput('2'),
        }),
        explanation: 'بهای ۱۰۰۰، کف ۱۰۰ و نرخ ۲۰٪: سال اول ۲۰۰ و ارزش ۸۰۰؛ سال دوم ۱۶۰، ارزش ۶۴۰ و انباشته ۳۶۰.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'declining_balance_depreciation',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(160, unit: 'ریال/سال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'declining_balance_depreciation',
        nameFa: 'استهلاک ماندهٔ نزولی',
        nameEn: 'Declining Balance Depreciation',
        description: DecliningBalanceDepreciationEngine.basis,
      ),
    ],
  );
  static final decliningBalanceDepreciationRunner = CalculatorRunner(
    definition: decliningBalanceDepreciation,
    engine: const DecliningBalanceDepreciationEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final inflationAdjustment = CalculatorDefinition(
    id: 'inflation_adjustment',
    categoryId: CalculatorCategoryId.engineeringEconomics,
    nameFa: 'تعدیل مبلغ اسمی با تورم',
    nameEn: 'Inflation Adjusted Purchasing Power',
    aliases: ['inflation_adjustment'],
    description: 'تعدیل مبلغ اسمی با تورم؛ روش، زمان جریان و فرض‌ها کنار نتیجه مشخص است؛ ورودی ناقص از مثال پر نمی‌شود.',
    formulaLatex: r'V_{real,0}=\frac{V_{nominal,n}}{(1+\pi)^n}',
    assumptions: InflationAdjustmentEngine.basis,
    fields: [
      NumericFieldDefinition(
        id: 'amount',
        label: 'مبلغ اسمی در پایان n دوره',
        defaultValue: 1000,
        help: 'قدر مطلق جریان نامنفی، با واحد پول یکسان؛ عامل برای دریافت یا پرداخت یک‌جهت یکسان است و علامت سود/NPV را تعیین نمی‌کند.',
        min: 0,
        unit: 'ریال',
      ),
      NumericFieldDefinition(
        id: 'rate',
        label: 'نرخ تورم مؤثر هر دوره',
        defaultValue: 10,
        help: 'درصد مؤثر ثابت هر دوره؛ ۱۰ یعنی ۱۰٪ نه ۰٫۱٪. باید بیشتر از منفی ۱۰۰٪ باشد؛ نرخ منفی بالاتر از این حد مجاز است. نرخ اسمی سالانه با دورهٔ ماهانه را مستقیم وارد نکنید.',
        min: -100,
        kind: NumericInputKind.percentage,
        unit: '٪/دوره',
      ),
      NumericFieldDefinition(
        id: 'periods',
        label: 'تعداد دوره‌های هم‌اندازه',
        defaultValue: 3,
        help: 'عدد صحیح ۰ تا ۱۰۰۰۰؛ نرخ و فاصلهٔ زمانی جریان‌ها باید دقیقاً همین دوره باشد. یک دوره می‌تواند ماه یا سال باشد، بدون تبدیل خودکار.',
        min: 0,
        max: 10000,
        integerOnly: true,
        unit: 'دوره',
      ),
    ],
    examples: [
      CalculatorExample(
        title: 'مثال قابل بررسی دستی',
        inputs: RawCalculatorInput({
          'amount': const RawTextInput('1000'),
          'rate': const RawTextInput('10'),
          'periods': const RawTextInput('3'),
        }),
        explanation: 'مبلغ اسمی ۱۰۰۰ پس از ۳ دوره تورم ۱۰٪: قدرت خرید پایه ۱۰۰۰/۱٫۱³≈۷۵۱٫۳۱۴۸ ریال.',
        expectedResult: CalculationResult(
          primary: ResultMetric(
            id: 'inflation_adjustment',
            label: 'نتیجهٔ مرجع مثال',
            value: NumericResultValue(751.3148009015778, unit: 'ریال'),
          ),
        ),
      ),
    ],
    relatedTerms: [
      RelatedTerm(
        id: 'inflation_adjustment',
        nameFa: 'تعدیل مبلغ اسمی با تورم',
        nameEn: 'Inflation Adjusted Purchasing Power',
        description: InflationAdjustmentEngine.basis,
      ),
    ],
  );
  static final inflationAdjustmentRunner = CalculatorRunner(
    definition: inflationAdjustment,
    engine: const InflationAdjustmentEngine(),
    normalizer: const InputNormalizer(requireExplicitFields: true),
  );
  static final List<CalculatorRunner<CalculatorParameters>> runners =
      List.unmodifiable([
        timeValueMoneyRunner,
        futurePresentFactorRunner,
        presentFutureFactorRunner,
        futureAnnuityFactorRunner,
        annuityFutureFactorRunner,
        presentAnnuityFactorRunner,
        annuityPresentFactorRunner,
        straightLineDepreciationRunner,
        decliningBalanceDepreciationRunner,
        inflationAdjustmentRunner,
      ]);
  static final List<CalculatorDefinition> definitions = List.unmodifiable(
    runners.map((r) => r.definition),
  );
  static final Map<String, CalculatorRunner<CalculatorParameters>> byId =
      Map.unmodifiable({for (final r in runners) r.definition.id: r});
}
