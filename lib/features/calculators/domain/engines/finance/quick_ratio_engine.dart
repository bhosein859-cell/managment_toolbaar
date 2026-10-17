import '../../calculator_domain.dart';
import 'finance_support.dart';

final class QuickRatioParameters implements CalculatorParameters {
  const QuickRatioParameters({
    required this.currentAssets,
    required this.inventory,
    required this.prepayments,
    required this.currentLiabilities,
  });
  final double currentAssets;
  final double inventory;
  final double prepayments;
  final double currentLiabilities;
}

final class QuickRatioEngine implements CalculatorEngine<QuickRatioParameters> {
  const QuickRatioEngine();
  static const basis =
      'در این نسخه دارایی سریع = دارایی جاری منهای موجودی و پیش‌پرداخت است. این اقلام باید داخل همان دارایی جاری و بدون هم‌پوشانی باشند؛ مطالبات خالص و طبقه‌بندی را طبق روش سازمان ثبت کنید. سایر اقلام غیرنقدشونده را سازمان باید ارزیابی کند؛ مقایسه فقط با تعریف مشترک معتبر است.';
  @override
  String get calculatorId => 'quick_ratio';
  @override
  InputBinding<QuickRatioParameters> bind(CalculatorInput input) {
    final p = QuickRatioParameters(
      currentAssets: input.requireNumber('current_assets'),
      inventory: input.requireNumber('inventory'),
      prepayments: input.requireNumber('prepayments'),
      currentLiabilities: input.requireNumber('current_liabilities'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(QuickRatioParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final quickAssets = p.currentAssets - p.inventory - p.prepayments;
    final value = quickAssets / p.currentLiabilities;
    if (lostNonzero(value, quickAssets > 0)) return financeRange();
    return financeResult(
      id: calculatorId,
      label: 'نسبت آنی',
      value: value,
      unit: 'برابر',
      basis: basis,
      details: [
        financeMetric(
          'quick_assets',
          'دارایی سریع با تعریف انتخابی',
          quickAssets,
          unit: 'ریال',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(QuickRatioParameters p) {
    final issues = validateFinance([
      FinanceField('current_assets', 'دارایی جاری کل', p.currentAssets, min: 0),
      FinanceField('inventory', 'موجودی داخل دارایی جاری', p.inventory, min: 0),
      FinanceField(
        'prepayments',
        'پیش‌پرداخت داخل دارایی جاری',
        p.prepayments,
        min: 0,
      ),
      FinanceField(
        'current_liabilities',
        'بدهی جاری همان تاریخ',
        p.currentLiabilities,
        min: 0,
        exclusiveMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;
    if (p.inventory > p.currentAssets ||
        p.prepayments > p.currentAssets - p.inventory) {
      issues.add(
        CalculationIssue(
          code: 'inconsistent_assets',
          fieldId: p.inventory > p.currentAssets ? 'inventory' : 'prepayments',
          message: 'موجودی و پیش‌پرداختِ بدون هم‌پوشانی نباید در مجموع از دارایی جاری بیشتر باشند.',
        ),
      );
    }
    return issues;
  }
}
