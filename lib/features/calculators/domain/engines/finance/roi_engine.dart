import '../../calculator_domain.dart';
import 'finance_support.dart';

final class RoiParameters implements CalculatorParameters {
  const RoiParameters({required this.netProfit, required this.investment});
  final double netProfit;
  final double investment;
}

final class RoiEngine implements CalculatorEngine<RoiParameters> {
  const RoiEngine();
  static const basis =
      'سود خالص باید پس از کسر تمام هزینه‌های مرتبط، از جمله بهای سرمایه‌گذاری، محاسبه شده باشد؛ اصل سرمایه را دوباره از سود کم نکنید. این ROI ساده است، نه IRR یا بازده سالانه.';
  @override
  String get calculatorId => 'roi';
  @override
  InputBinding<RoiParameters> bind(CalculatorInput input) {
    final p = RoiParameters(
      netProfit: input.requireNumber('net_profit'),
      investment: input.requireNumber('investment'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(RoiParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.netProfit / p.investment;
    return financeResult(
      id: calculatorId,
      label: 'بازده ساده (ROI)',
      value: value,
      percentage: true,
      nonzeroExpected: p.netProfit != 0,
      basis: basis,
    );
  }

  List<CalculationIssue> _validate(RoiParameters p) {
    final issues = validateFinance([
      FinanceField('net_profit', 'سود یا زیان خالص متناظر', p.netProfit),
      FinanceField(
        'investment',
        'کل هزینهٔ سرمایه‌گذاری',
        p.investment,
        min: 0,
        exclusiveMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
