import '../../calculator_domain.dart';
import '../../statistics/normal_quantile.dart';
import '../../statistics/tool_numeric.dart';

enum SigmaShift { none, convention15 }

final class SigmaLevelParameters implements CalculatorParameters {
  const SigmaLevelParameters({
    required this.dpmo,
    this.shift = SigmaShift.none,
  });
  final double dpmo;
  final SigmaShift shift;
}

final class SigmaLevelEngine implements CalculatorEngine<SigmaLevelParameters> {
  const SigmaLevelEngine();
  static const basis =
      'این خروجی Z معادل نرمال یک‌طرفه از احتمال نقص هر فرصت است، نه انحراف معیار فیزیکی فرایند یا اثبات نرمال‌بودن. شیفت ۱٫۵ تنها قرارداد انتخابی برخی روش‌های شش‌سیگماست و پیش‌فرض فعال نیست؛ قانون عمومی آماری نیست. DPMO دوطرفه یا نرخ واحد معیوب را بدون بررسی تعریف فرصت/دم جایگزین نکنید. برای DPMO صفر/یک میلیون مقدار متناهی نداریم؛ عدم مشاهدهٔ نقص تضمین احتمال صفر نیست و رتبهٔ قطعی خوب/بد داده نمی‌شود.';
  @override
  String get calculatorId => 'sigma_level';
  @override
  InputBinding<SigmaLevelParameters> bind(CalculatorInput input) {
    final shift = switch (input.requireChoice('shift')) {
      'none' => SigmaShift.none,
      'convention_1_5' => SigmaShift.convention15,
      _ => null,
    };
    if (shift == null) {
      return RejectedInput([
        CalculationIssue(
          code: 'invalid_shift',
          fieldId: 'shift',
          message: 'قرارداد شیفت معتبر نیست.',
        ),
      ]);
    }
    final p = SigmaLevelParameters(
      dpmo: input.requireNumber('dpmo'),
      shift: shift,
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(SigmaLevelParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    if (p.dpmo == 0 || p.dpmo == 1000000) {
      return toolFailure(
        'unbounded_sigma',
        'در دو انتهای احتمال، Z نرمال متناهی نیست؛ سطح سیگمای ساختگی یا سقف قراردادی نمایش داده نشد.',
        fieldId: 'dpmo',
      );
    }
    final probability = p.dpmo / 1000000;
    if (probability == 0 || probability >= 1) return toolRange();
    // -Phi^-1(p) avoids losing tiny p through subtraction 1-p.
    final z = -normalQuantile(probability);
    final shift = p.shift == SigmaShift.none ? 0.0 : 1.5;
    return toolResult(
      id: calculatorId,
      label: 'Z معادل یک‌طرفه با قرارداد انتخابی',
      value: z + shift,
      basis: basis,
      details: [
        metric('z_unshifted', 'Z معادل بدون شیفت', z),
        metric('selected_shift', 'شیفت انتخابی، نه سیگمای برآوردی', shift),
      ],
    );
  }

  List<CalculationIssue> _validate(SigmaLevelParameters p) =>
      toolValidate([ToolNumber('dpmo', 'DPMO', p.dpmo, min: 0, max: 1000000)]);
}
