import '../../calculator_domain.dart';
import 'production_support.dart';

final class UnitProductionCostParameters implements CalculatorParameters {
  const UnitProductionCostParameters({
    required this.allocatedCost,
    required this.goodOutput,
  });
  final double allocatedCost;
  final double goodOutput;
}

final class UnitProductionCostEngine
    implements CalculatorEngine<UnitProductionCostParameters> {
  const UnitProductionCostEngine();
  @override
  String get calculatorId => 'unit_production_cost';
  @override
  InputBinding<UnitProductionCostParameters> bind(CalculatorInput input) {
    final p = UnitProductionCostParameters(
      allocatedCost: input.requireNumber('allocated_cost'),
      goodOutput: input.requireNumber('good_output'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(UnitProductionCostParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.allocatedCost / p.goodOutput;
    return productionResult(
      id: calculatorId,
      label: 'هزینهٔ تولید واحد',
      value: value,
      nonzeroExpected: p.allocatedCost > 0,
      unit: 'ریال/واحد سالم',
      percentage: false,
      interpretation: 'نتیجه میانگین هزینهٔ ساخت تخصیص‌یافته به هر واحد سالم است. روش تخصیص سربار و مرز دوره باید همراه گزارش ثبت شود؛ ابزار قیمت فروش پیشنهاد نمی‌دهد.',
    );
  }

  List<CalculationIssue> _validate(UnitProductionCostParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'allocated_cost',
          'کل هزینهٔ ساخت تخصیص‌یافته',
          p.allocatedCost,
          positive: false,
          integer: false,
        ),
        ProductionNumber(
          'good_output',
          'خروجی سالم متناظر',
          p.goodOutput,
          positive: true,
          integer: false,
        ),
      ]);
}
