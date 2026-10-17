import '../../calculator_domain.dart';
import '../../decision/decision_math.dart';
import '../../decision/decision_tree.dart';
import '../../statistics/tool_numeric.dart';

final class ExpectedValueTreeParameters implements CalculatorParameters {
  const ExpectedValueTreeParameters(this.tree);
  final DecisionTreeData tree;
}

final class ExpectedValueTreeEngine
    implements CalculatorEngine<ExpectedValueTreeParameters> {
  const ExpectedValueTreeEngine();
  static const basis =
      'درخت ریشه‌دار با گره پایانی، احتمالی یا تصمیم است. یال‌ها از والد به فرزندند؛ ریشه بدون والد، بقیه دقیقاً یک والد و همه متصل‌اند. ارجاع نامعتبر، چرخه، خودارجاعی، یال تکراری و زیرشاخهٔ مشترک DAG رد می‌شوند. گره پایانی عایدی پولی خالص با علامت دلخواه دارد؛ ستون عایدی غیرپایانی باید صفر باشد. احتمال هر شاخهٔ تصادفی بین صفر و یک است و مجموع هر گره در تلرانس ۱۰ به توان منفی ۹ یک؛ فقط خطای کوچک مجاز با تقسیم بر جمع اصلاح می‌شود، نه احتمال‌های دلخواه. برای یال گره تصمیم ضریب یک صرفاً جای‌نگهدار است، نه احتمال انتخاب. محاسبه از برگ به ریشه: احتمال=جمع وزن‌دار فرزندان، تصمیم=بیشترین ارزش مورد انتظار. مطلوبیت خطی پول، ریسک‌خنثی بودن، عایدی‌های خالص هم‌ارز/هم‌زمان و کامل‌بودن حالت‌ها فرض می‌شوند؛ تنزیل زمانی، ریسک‌گریزی و ارزش اطلاعات خودکار نیستند. شاخهٔ احتمال صفر هم باید دادهٔ معتبر داشته باشد. فرزندان نزدیک به بیشینه در تلرانس نسبی ۱۰ به توان منفی ۱۰ هم‌ارزش گزارش می‌شوند؛ خود ارزش گره تصمیم بیشینهٔ محاسبه‌شده است.';
  @override
  String get calculatorId => 'expected_value_tree';
  @override
  InputBinding<ExpectedValueTreeParameters> bind(CalculatorInput input) =>
      switch (bindTree(input)) {
        RejectedTree(:final issues) => RejectedInput(issues),
        BoundTree(:final tree) => _bound(tree),
      };
  InputBinding<ExpectedValueTreeParameters> _bound(DecisionTreeData t) {
    final issues = validateTree(t);
    return issues.isEmpty
        ? BoundInput(ExpectedValueTreeParameters(t))
        : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(ExpectedValueTreeParameters p) {
    final issues = validateTree(p.tree);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return safelyDecide(() {
      final v = evaluateTree(p.tree);
      return decisionResult(
        id: calculatorId,
        label: 'ارزش مورد انتظار در ریشه با فرض ریسک‌خنثی',
        value: v.rootValue,
        unit: 'ریال',
        basis: basis,
        details: [
          seriesMetric(
            'node_ids',
            'شناسهٔ گره‌ها به ترتیب ورودی',
            p.tree.nodes.map((n) => n.id.toDouble()),
          ),
          seriesMetric(
            'node_values',
            'ارزش گره‌ها به همان ترتیب',
            v.nodeValues,
            unit: 'ریال',
          ),
          if (v.parents.isNotEmpty) ...[
            seriesMetric(
              'decision_parents',
              'سر زوج‌های تصمیم؛ شناسهٔ والد (برای تساوی تکرار می‌شود)',
              v.parents,
            ),
            seriesMetric(
              'preferred_children',
              'ته زوج‌های هم‌ردیف؛ فرزند بیشینه/نزدیک‌به‌بیشینه',
              v.choices,
            ),
          ] else
            textMetric(
              'no_decision_nodes',
              'گره تصمیم',
              'این درخت فقط ارزش انتظار/پایانه دارد و انتخابی مدل نشده است',
            ),
        ],
      );
    });
  }
}
