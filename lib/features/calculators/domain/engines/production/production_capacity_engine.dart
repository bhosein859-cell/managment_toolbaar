import '../../calculator_domain.dart';
import 'production_support.dart';

final class ProductionCapacityParameters implements CalculatorParameters {
  const ProductionCapacityParameters({
    required this.availableTime,
    required this.idealCycle,
    required this.parallelResources,
  });
  final double availableTime;
  final double idealCycle;
  final double parallelResources;
}

final class ProductionCapacityEngine
    implements CalculatorEngine<ProductionCapacityParameters> {
  const ProductionCapacityEngine();
  @override
  String get calculatorId => 'production_capacity';
  @override
  InputBinding<ProductionCapacityParameters> bind(CalculatorInput input) {
    final p = ProductionCapacityParameters(
      availableTime: input.requireNumber('available_time'),
      idealCycle: input.requireNumber('ideal_cycle'),
      parallelResources: input.requireNumber('parallel_resources'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(ProductionCapacityParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = (p.availableTime / p.idealCycle) * p.parallelResources;
    return productionResult(
      id: calculatorId,
      label: 'ظرفیت تولید',
      value: value,
      nonzeroExpected: p.availableTime > 0,
      unit: 'واحد/بازه',
      percentage: false,
      interpretation: 'ظرفیت نظری در بازهٔ انتخابی است، نه تعهد خروجی سالم. خروجی کسری واحد معادل است و شمار قطعات کامل خودکار گرد نمی‌شود. منابع متوالی یا با سرعت متفاوت را نباید با تعداد منابع یکسان جایگزین کرد.',
    );
  }

  List<CalculationIssue> _validate(ProductionCapacityParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'available_time',
          'زمان خالص هر منبع در بازه',
          p.availableTime,
          positive: false,
          integer: false,
        ),
        ProductionNumber(
          'ideal_cycle',
          'زمان سیکل ایده‌آل هر منبع',
          p.idealCycle,
          positive: true,
          integer: false,
        ),
        ProductionNumber(
          'parallel_resources',
          'تعداد منابع یکسان و موازی',
          p.parallelResources,
          positive: true,
          integer: true,
        ),
      ]);
}
