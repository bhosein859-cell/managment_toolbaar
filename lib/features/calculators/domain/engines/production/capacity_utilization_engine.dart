import '../../calculator_domain.dart';
import 'production_support.dart';

final class CapacityUtilizationParameters implements CalculatorParameters {
  const CapacityUtilizationParameters({
    required this.actualOutput,
    required this.designCapacity,
  });
  final double actualOutput;
  final double designCapacity;
}

final class CapacityUtilizationEngine
    implements CalculatorEngine<CapacityUtilizationParameters> {
  const CapacityUtilizationEngine();
  @override
  String get calculatorId => 'capacity_utilization';
  @override
  InputBinding<CapacityUtilizationParameters> bind(CalculatorInput input) {
    final p = CapacityUtilizationParameters(
      actualOutput: input.requireNumber('actual_output'),
      designCapacity: input.requireNumber('design_capacity'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(CapacityUtilizationParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = p.actualOutput / p.designCapacity;
    return productionResult(
      id: calculatorId,
      label: 'نرخ بهره‌برداری از ظرفیت',
      value: value,
      nonzeroExpected: p.actualOutput > 0,
      unit: null,
      percentage: true,
      interpretation: 'مبنا ظرفیت اسمی/طراحی است. مقدار بیش از ۱۰۰٪ مجاز و با هشدار گزارش می‌شود؛ مبنای دوره، واحد و ظرفیت را بازبینی کنید، نه اینکه نتیجه را به ۱۰۰٪ محدود کنید.',
      warnings: [
        if (value > 1)
          CalculationWarning(
            code: 'above_design_capacity',
            message: 'خروجی از ظرفیت اسمی بیشتر است؛ مبنای ظرفیت، دوره و اضافه‌کاری را بررسی کنید. مقدار محدود نشد.',
          ),
      ],
    );
  }

  List<CalculationIssue> _validate(CapacityUtilizationParameters p) =>
      validateProductionNumbers([
        ProductionNumber(
          'actual_output',
          'خروجی واقعی بازه',
          p.actualOutput,
          positive: false,
          integer: false,
        ),
        ProductionNumber(
          'design_capacity',
          'ظرفیت اسمی/طراحی همان بازه',
          p.designCapacity,
          positive: true,
          integer: false,
        ),
      ]);
}
