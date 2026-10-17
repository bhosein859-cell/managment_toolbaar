import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class EvmPerformanceParameters implements CalculatorParameters {
  const EvmPerformanceParameters({
    required this.pv,
    required this.ev,
    required this.ac,
  });
  final double pv;
  final double ev;
  final double ac;
}

final class EvmPerformanceEngine
    implements CalculatorEngine<EvmPerformanceParameters> {
  const EvmPerformanceEngine();
  static const basis =
      'PV، EV و AC تجمعی و مربوط به یک دامنه، تاریخ وضعیت و واحد پول‌اند. SPI=EV/PV و CPI=EV/AC بی‌بعدند. برای محاسبهٔ هر دو شاخص PV و AC باید مثبت باشند؛ EV صفر مجاز است. EV لزوماً از PV یا AC کمتر نیست. SPI شاخص ارزش بودجه‌ای زمان‌بندی است، نه نسبت روزهای واقعی یا تضمین پایان به‌موقع؛ در پایان پروژه می‌تواند به یک میل کند و تأخیر تقویمی را پنهان کند. مقادیر به‌تنهایی تشخیص علت یا پیش‌بینی قطعی نیستند.';
  @override
  String get calculatorId => 'evm_performance';
  @override
  InputBinding<EvmPerformanceParameters> bind(CalculatorInput input) {
    final p = EvmPerformanceParameters(
      pv: input.requireNumber('pv'),
      ev: input.requireNumber('ev'),
      ac: input.requireNumber('ac'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(EvmPerformanceParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final spi = p.ev / p.pv, cpi = p.ev / p.ac;
    if (invalidNumeric(spi, nonzero: p.ev > 0) ||
        invalidNumeric(cpi, nonzero: p.ev > 0)) {
      return toolRange();
    }
    return toolResult(
      id: calculatorId,
      label: 'شاخص عملکرد زمان‌بندی SPI',
      value: spi,
      basis: basis,
      details: [metric('cpi', 'شاخص عملکرد هزینه CPI', cpi)],
    );
  }

  List<CalculationIssue> _validate(EvmPerformanceParameters p) {
    final issues = toolValidate([
      ToolNumber('pv', 'ارزش برنامه‌ریزی‌شده PV', p.pv, min: 0),
      ToolNumber('ev', 'ارزش کسب‌شده EV', p.ev, min: 0),
      ToolNumber('ac', 'هزینهٔ واقعی AC', p.ac, min: 0),
    ]);
    if (issues.isNotEmpty) return issues;
    for (final (id, value) in [('pv', p.pv), ('ac', p.ac)]) {
      if (value == 0) {
        issues.add(
          CalculationIssue(
            code: 'undefined_index',
            fieldId: id,
            message: 'برای شاخص مربوط، مخرج باید مثبت باشد؛ تقسیم بر صفر یا شاخص ساختگی نمایش داده نشد.',
          ),
        );
      }
    }
    return issues;
  }
}
