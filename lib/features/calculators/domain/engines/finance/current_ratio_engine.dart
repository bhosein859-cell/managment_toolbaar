import '../../calculator_domain.dart';
import 'finance_support.dart';

final class CurrentRatioParameters implements CalculatorParameters {
  const CurrentRatioParameters({
    required this.currentAssets,
    required this.currentLiabilities,
  });
  final double currentAssets;
  final double currentLiabilities;
}

final class CurrentRatioEngine
    implements CalculatorEngine<CurrentRatioParameters> {
  const CurrentRatioEngine();
  static const basis =
      'دارایی و بدهی جاری باید متعلق به همان تاریخ، واحد پول و صورت مالی باشند. تعریف جاری بر مبنای چرخهٔ عملیاتی/استاندارد حسابداری سازمان است. عدد به‌تنهایی نقدشوندگی یا سلامت مالی را تضمین نمی‌کند؛ آستانهٔ خوب/بد عمومی اعمال نشده است.';
  @override
  String get calculatorId => 'current_ratio';
  @override
  InputBinding<CurrentRatioParameters> bind(CalculatorInput input) {
    final p = CurrentRatioParameters(
      currentAssets: input.requireNumber('current_assets'),
      currentLiabilities: input.requireNumber('current_liabilities'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(CurrentRatioParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.currentAssets / p.currentLiabilities;
    return financeResult(
      id: calculatorId,
      label: 'نسبت جاری',
      value: value,
      unit: 'برابر',
      nonzeroExpected: p.currentAssets > 0,
      basis: basis,
    );
  }

  List<CalculationIssue> _validate(CurrentRatioParameters p) {
    final issues = validateFinance([
      FinanceField('current_assets', 'دارایی جاری', p.currentAssets, min: 0),
      FinanceField(
        'current_liabilities',
        'بدهی جاری',
        p.currentLiabilities,
        min: 0,
        exclusiveMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
