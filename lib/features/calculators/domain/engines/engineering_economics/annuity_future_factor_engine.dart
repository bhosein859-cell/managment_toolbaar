import '../../calculator_domain.dart';
import '../../engineering_economics/engineering_math.dart';

final class AnnuityFutureFactorParameters extends EconomicFactorParameters {
  const AnnuityFutureFactorParameters({
    required super.amount,
    required super.rate,
    required super.periods,
  });
}

final class AnnuityFutureFactorEngine
    implements CalculatorEngine<AnnuityFutureFactorParameters> {
  const AnnuityFutureFactorEngine();
  static const basis =
      'جریان A یکنواخت با n پرداخت مساوی در پایان دوره‌های ۱ تا n است (annuity-immediate)؛ در زمان صفر پرداختی نیست. P در زمان صفر و F بلافاصله پس از آخرین پرداخت در n است. نرخ مؤثر ثابت و فاصله‌های هم‌اندازه؛ پیش‌پرداخت، مالیات، کارمزد و تورم منظور نیست. مبلغ ورودی قدر مطلق دریافت یا پرداخت هم‌جهت است. نرخ صفر: عامل F/A و P/A برابر n و عامل A/F و A/P برابر ۱/n است. n=۰ در F/A و P/A جمع خالی و عامل صفر است؛ A/F و A/P در n=۰ تعریف نمی‌شوند.';
  @override
  String get calculatorId => 'annuity_future_factor';
  @override
  InputBinding<AnnuityFutureFactorParameters> bind(CalculatorInput input) {
    final p = AnnuityFutureFactorParameters(
      amount: input.requireNumber('amount'),
      rate: input.requireNumber('rate'),
      periods: input.requireNumber('periods'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  List<CalculationIssue> _validate(AnnuityFutureFactorParameters p) =>
      economicFactorIssues(p.amount, p.rate, p.periods);
  @override
  CalculationOutcome calculate(AnnuityFutureFactorParameters p) =>
      calculateEconomicFactor(calculatorId, EconomicFactor.af, p, basis);
}
