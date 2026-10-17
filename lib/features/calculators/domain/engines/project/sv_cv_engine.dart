import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class SvCvParameters implements CalculatorParameters {
  const SvCvParameters({required this.pv, required this.ev, required this.ac});
  final double pv;
  final double ev;
  final double ac;
}

final class SvCvEngine implements CalculatorEngine<SvCvParameters> {
  const SvCvEngine();
  static const basis =
      'SV=EV−PV و CV=EV−AC هر دو بر حسب پول بودجه‌ای‌اند؛ SV مدت تأخیر به روز نیست. مثبت/منفی بودن تنها جهت اختلاف را نشان می‌دهد، نه علت یا حکم قطعی دربارهٔ پروژه. داده‌ها تجمعی، نامنفی و هم‌دامنه/هم‌تاریخ/هم‌ارزند؛ صفر مجاز است. این ابزار شاخص نسبتی یا پیش‌بینی پایان نمی‌سازد.';
  @override
  String get calculatorId => 'sv_cv';
  @override
  InputBinding<SvCvParameters> bind(CalculatorInput input) {
    final p = SvCvParameters(
      pv: input.requireNumber('pv'),
      ev: input.requireNumber('ev'),
      ac: input.requireNumber('ac'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(SvCvParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return toolResult(
      id: calculatorId,
      label: 'انحراف زمان‌بندی بودجه‌ای SV',
      value: p.ev - p.pv,
      unit: 'ریال',
      basis: basis,
      details: [metric('cv', 'انحراف هزینه CV', p.ev - p.ac, unit: 'ریال')],
    );
  }

  List<CalculationIssue> _validate(SvCvParameters p) {
    final issues = toolValidate([
      ToolNumber('pv', 'ارزش برنامه‌ریزی‌شده PV', p.pv, min: 0),
      ToolNumber('ev', 'ارزش کسب‌شده EV', p.ev, min: 0),
      ToolNumber('ac', 'هزینهٔ واقعی AC', p.ac, min: 0),
    ]);
    if (issues.isNotEmpty) return issues;
    return issues;
  }
}
