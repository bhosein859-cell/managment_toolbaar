import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class PpkParameters implements CalculatorParameters {
  const PpkParameters({
    required this.usl,
    required this.lsl,
    required this.mean,
    required this.sigma,
  });
  final double usl;
  final double lsl;
  final double mean;
  final double sigma;
}

final class PpkEngine implements CalculatorEngine<PpkParameters> {
  const PpkEngine();
  static const name = 'عملکرد مرکزدار — Ppk';
  static const basis =
      'این شاخص از انحراف معیار کلی نمونه (شامل نوسان بین زیرگروه‌ها) استفاده می‌کند و با Cp/Cpk درون‌گروهی یکی نیست. کمینهٔ شاخص دو طرف محاسبه می‌شود؛ میانگین خارج از حدود می‌تواند شاخص منفی بدهد و قطع نمی‌شود. در این فرم s کلی از بیرون وارد می‌شود؛ برای نمونهٔ معمول با N مشاهده، s از ریشهٔ مجموع مربع فاصله‌ها از میانگین تقسیم بر N−۱ به دست می‌آید. محاسبهٔ عددی به‌تنهایی نرمال‌بودن یا پایداری را ثابت نمی‌کند؛ تفسیر معمول دم‌ها/توانمندی به فرایند پایدار، دادهٔ مستقل، برآورد مناسب و توزیع تقریباً نرمال وابسته است. حدود مشخصات با حدود کنترل فرق دارند؛ بدون معیار قراردادی برچسب خوب/بد ارائه نمی‌شود.';
  @override
  String get calculatorId => 'ppk';
  @override
  InputBinding<PpkParameters> bind(CalculatorInput input) {
    final p = PpkParameters(
      usl: input.requireNumber('usl'),
      lsl: input.requireNumber('lsl'),
      mean: input.requireNumber('mean'),
      sigma: input.requireNumber('sigma'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(PpkParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final upper = differenceRatio(p.usl, p.mean, p.sigma, 3),
        lower = differenceRatio(p.mean, p.lsl, p.sigma, 3);
    if (invalidNumeric(upper, nonzero: p.usl != p.mean) ||
        invalidNumeric(lower, nonzero: p.mean != p.lsl)) {
      return toolRange();
    }
    final value = math.min(upper, lower);
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      basis: basis,
      details: [
        metric('upper_index', 'شاخص سمت بالا', upper),
        metric('lower_index', 'شاخص سمت پایین', lower),
      ],
    );
  }

  List<CalculationIssue> _validate(PpkParameters p) {
    final issues = toolValidate([
      ToolNumber('usl', 'حد بالای مشخصات', p.usl),
      ToolNumber('lsl', 'حد پایین مشخصات', p.lsl),
      ToolNumber('mean', 'میانگین فرایند', p.mean),
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
