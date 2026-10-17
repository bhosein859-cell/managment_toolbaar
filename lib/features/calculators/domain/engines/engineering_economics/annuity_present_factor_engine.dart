import '../../calculator_domain.dart';
import '../../engineering_economics/engineering_math.dart';

final class AnnuityPresentFactorParameters extends EconomicFactorParameters {
  const AnnuityPresentFactorParameters({
    required super.amount,
    required super.rate,
    required super.periods,
  });
}

final class AnnuityPresentFactorEngine
    implements CalculatorEngine<AnnuityPresentFactorParameters> {
  const AnnuityPresentFactorEngine();
  static const basis =
      'جریان A یکنواخت با n پرداخت مساوی در پایان دوره‌های ۱ تا n است (annuity-immediate)؛ در زمان صفر پرداختی نیست. P در زمان صفر و F بلافاصله پس از آخرین پرداخت در n است. نرخ مؤثر ثابت و فاصله‌های هم‌اندازه؛ پیش‌پرداخت، مالیات، کارمزد و تورم منظور نیست. مبلغ ورودی قدر مطلق دریافت یا پرداخت هم‌جهت است. نرخ صفر: عامل F/A و P/A برابر n و عامل A/F و A/P برابر ۱/n است. n=۰ در F/A و P/A جمع خالی و عامل صفر است؛ A/F و A/P در n=۰ تعریف نمی‌شوند.';
  @override
  String get calculatorId => 'annuity_present_factor';
  @override
  InputBinding<AnnuityPresentFactorParameters> bind(CalculatorInput input) {
    final p = AnnuityPresentFactorParameters(
      amount: input.requireNumber('amount'),
      rate: input.requireNumber('rate'),
      periods: input.requireNumber('periods'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  List<CalculationIssue> _validate(AnnuityPresentFactorParameters p) =>
      economicFactorIssues(p.amount, p.rate, p.periods);
  @override
  CalculationOutcome calculate(AnnuityPresentFactorParameters p) =>
      calculateEconomicFactor(calculatorId, EconomicFactor.ap, p, basis);
}
