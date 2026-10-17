import '../../calculator_domain.dart';
import '../../engineering_economics/engineering_math.dart';

final class FutureAnnuityFactorParameters extends EconomicFactorParameters {
  const FutureAnnuityFactorParameters({
    required super.amount,
    required super.rate,
    required super.periods,
  });
}

final class FutureAnnuityFactorEngine
    implements CalculatorEngine<FutureAnnuityFactorParameters> {
  const FutureAnnuityFactorEngine();
  static const basis =
      'جریان A یکنواخت با n پرداخت مساوی در پایان دوره‌های ۱ تا n است (annuity-immediate)؛ در زمان صفر پرداختی نیست. P در زمان صفر و F بلافاصله پس از آخرین پرداخت در n است. نرخ مؤثر ثابت و فاصله‌های هم‌اندازه؛ پیش‌پرداخت، مالیات، کارمزد و تورم منظور نیست. مبلغ ورودی قدر مطلق دریافت یا پرداخت هم‌جهت است. نرخ صفر: عامل F/A و P/A برابر n و عامل A/F و A/P برابر ۱/n است. n=۰ در F/A و P/A جمع خالی و عامل صفر است؛ A/F و A/P در n=۰ تعریف نمی‌شوند.';
  @override
  String get calculatorId => 'future_annuity_factor';
  @override
  InputBinding<FutureAnnuityFactorParameters> bind(CalculatorInput input) {
    final p = FutureAnnuityFactorParameters(
      amount: input.requireNumber('amount'),
      rate: input.requireNumber('rate'),
      periods: input.requireNumber('periods'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  List<CalculationIssue> _validate(FutureAnnuityFactorParameters p) =>
      economicFactorIssues(p.amount, p.rate, p.periods);
  @override
  CalculationOutcome calculate(FutureAnnuityFactorParameters p) =>
      calculateEconomicFactor(calculatorId, EconomicFactor.fa, p, basis);
}
