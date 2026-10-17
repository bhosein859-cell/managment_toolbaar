import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class PpParameters implements CalculatorParameters {
  const PpParameters({
    required this.usl,
    required this.lsl,
    required this.sigma,
  });
  final double usl;
  final double lsl;
  final double sigma;
}

final class PpEngine implements CalculatorEngine<PpParameters> {
  const PpEngine();
  static const name = 'عملکرد بالقوه — Pp';
  static const basis =
      'این شاخص از انحراف معیار کلی نمونه (شامل نوسان بین زیرگروه‌ها) استفاده می‌کند و با Cp/Cpk درون‌گروهی یکی نیست. میانگین و مرکزیت در این شاخص سنجیده نمی‌شوند. در این فرم s کلی از بیرون وارد می‌شود؛ برای نمونهٔ معمول با N مشاهده، s از ریشهٔ مجموع مربع فاصله‌ها از میانگین تقسیم بر N−۱ به دست می‌آید. محاسبهٔ عددی به‌تنهایی نرمال‌بودن یا پایداری را ثابت نمی‌کند؛ تفسیر معمول دم‌ها/توانمندی به فرایند پایدار، دادهٔ مستقل، برآورد مناسب و توزیع تقریباً نرمال وابسته است. حدود مشخصات با حدود کنترل فرق دارند؛ بدون معیار قراردادی برچسب خوب/بد ارائه نمی‌شود.';
  @override
  String get calculatorId => 'pp';
  @override
  InputBinding<PpParameters> bind(CalculatorInput input) {
    final p = PpParameters(
      usl: input.requireNumber('usl'),
      lsl: input.requireNumber('lsl'),
      sigma: input.requireNumber('sigma'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(PpParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final value = differenceRatio(p.usl, p.lsl, p.sigma, 6);
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      nonzero: true,
      basis: basis,
    );
  }

  List<CalculationIssue> _validate(PpParameters p) {
    final issues = toolValidate([
      ToolNumber('usl', 'حد بالای مشخصات', p.usl),
      ToolNumber('lsl', 'حد پایین مشخصات', p.lsl),
      ToolNumber(
        'sigma',
        'انحراف معیار کلی نمونه',
        p.sigma,
        min: 0,
        strictMin: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;
    if (p.usl <= p.lsl) {
      issues.add(
        CalculationIssue(
          code: 'invalid_limits',
          fieldId: 'usl',
          message: 'حد بالا باید بزرگ‌تر از حد پایین مشخصات باشد.',
        ),
      );
    }
    return issues;
  }
}
