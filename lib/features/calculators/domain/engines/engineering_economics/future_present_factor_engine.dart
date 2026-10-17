import '../../calculator_domain.dart';
import '../../engineering_economics/engineering_math.dart';

final class FuturePresentFactorParameters extends EconomicFactorParameters {
  const FuturePresentFactorParameters({
    required super.amount,
    required super.rate,
    required super.periods,
  });
}

final class FuturePresentFactorEngine
    implements CalculatorEngine<FuturePresentFactorParameters> {
  const FuturePresentFactorEngine();
  static const basis =
      'جریان تک‌مبلغی است: P در زمان صفر و F در پایان دورهٔ n؛ ترکیب گسسته با نرخ مؤثر ثابت i در هر دوره. مالیات، کارمزد، ریسک و تورم جداگانه‌اند. n=۰ یعنی همان لحظه و عامل یک؛ نرخ صفر عامل یک. مبلغ ورودی قدر مطلق دریافت یا پرداخت هم‌جهت است، نه جریان مختلط.';
  @override
  String get calculatorId => 'future_present_factor';
  @override
  InputBinding<FuturePresentFactorParameters> bind(CalculatorInput input) {
    final p = FuturePresentFactorParameters(
      amount: input.requireNumber('amount'),
      rate: input.requireNumber('rate'),
      periods: input.requireNumber('periods'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  List<CalculationIssue> _validate(FuturePresentFactorParameters p) =>
      economicFactorIssues(p.amount, p.rate, p.periods);
  @override
  CalculationOutcome calculate(FuturePresentFactorParameters p) =>
      calculateEconomicFactor(calculatorId, EconomicFactor.fp, p, basis);
}
