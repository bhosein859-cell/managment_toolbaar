import '../calculator_domain.dart';

enum CapabilityUnit {
  millimeter,
  centimeter,
  second,
  generic;

  String get label => switch (this) {
    millimeter => 'mm',
    centimeter => 'cm',
    second => 's',
    generic => 'واحد مشترک',
  };
}

final class CpParameters implements CalculatorParameters {
  const CpParameters({
    required this.usl,
    required this.lsl,
    required this.sigma,
    this.unit = CapabilityUnit.millimeter,
  });
  final double usl;
  final double lsl;

  /// Positive within-subgroup/process sigma, not an estimate from these limits.
  final double sigma;
  final CapabilityUnit unit;
}

final class CpEngine implements CalculatorEngine<CpParameters> {
  const CpEngine();
  @override
  String get calculatorId => 'cp';

  @override
  InputBinding<CpParameters> bind(CalculatorInput input) {
    final unit = switch (input.requireChoice('measurement_unit')) {
      'mm' => CapabilityUnit.millimeter,
      'cm' => CapabilityUnit.centimeter,
      'seconds' => CapabilityUnit.second,
      'generic' => CapabilityUnit.generic,
      _ => null,
    };
    if (unit == null) {
      return RejectedInput([
        CalculationIssue(
          code: 'invalid_unit',
          fieldId: 'measurement_unit',
          message: 'واحد اندازه‌گیری معتبر نیست.',
        ),
      ]);
    }
    final parameters = CpParameters(
      usl: input.requireNumber('usl'),
      lsl: input.requireNumber('lsl'),
      sigma: input.requireNumber('sigma'),
      unit: unit,
    );
    final issues = _validate(parameters);
    return issues.isEmpty ? BoundInput(parameters) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(CpParameters parameters) {
    final issues = _validate(parameters);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final width = parameters.usl - parameters.lsl;
    double value;
    if (width.isFinite) {
      final ratio = width / parameters.sigma;
      // Reorder only if the intermediate ratio overflows, preserving normal
      // small-number precision without constructing 6 * sigma.
      value = ratio.isFinite ? ratio / 6 : (width / 6) / parameters.sigma;
    } else {
      value = (parameters.usl / 6 - parameters.lsl / 6) / parameters.sigma;
    }
    if (!value.isFinite || value <= 0) {
      return CalculationFailure([
        CalculationIssue(
          code: 'numeric_range',
          message: 'Cp برای این مقیاس اعداد با دقت قابل اتکا محاسبه نشد. مقیاس مشترک ورودی‌ها را بازبینی کنید.',
        ),
      ]);
    }
    return CalculationSuccess(
      CalculationResult(
        primary: ResultMetric(
          id: 'cp',
          label: 'قابلیت بالقوهٔ فرایند (Cp)',
          value: NumericResultValue(value),
        ),
        details: [
          ResultMetric(
            id: 'usl',
            label: 'حد بالای مشخصات',
            value: NumericResultValue(
              parameters.usl,
              unit: parameters.unit.label,
            ),
          ),
          ResultMetric(
            id: 'lsl',
            label: 'حد پایین مشخصات',
            value: NumericResultValue(
              parameters.lsl,
              unit: parameters.unit.label,
            ),
          ),
          ResultMetric(
            id: 'sigma',
            label: 'انحراف معیار درون‌فرایندی',
            value: NumericResultValue(
              parameters.sigma,
              unit: parameters.unit.label,
            ),
          ),
        ],
        warnings: [
          CalculationWarning(
            code: 'statistical_assumptions',
            message: 'تفسیر متعارف Cp به فرایند پایدار، برآورد معتبر سیگمای درون‌فرایندی و توزیع تقریباً نرمال وابسته است.',
          ),
          CalculationWarning(
            code: 'centering_not_measured',
            severity: WarningSeverity.information,
            message: 'Cp جابه‌جایی میانگین نسبت به حدود را نمی‌سنجد و به‌تنهایی جایگزین Cpk یا Pp نیست.',
          ),
        ],
        interpretation: 'Cp نسبت عرض مشخصات به شش برابر سیگمای درون‌فرایندی است؛ شاخص بدون واحد است. بدون معیار قراردادی و بررسی فرض‌ها، برچسب قطعی خوب یا بد ارائه نمی‌شود.',
      ),
    );
  }

  List<CalculationIssue> _validate(CpParameters parameters) {
    final issues = <CalculationIssue>[];
    if (!parameters.usl.isFinite) {
      issues.add(
        CalculationIssue(
          code: 'invalid_usl',
          fieldId: 'usl',
          message: 'حد بالای مشخصات باید عدد متناهی باشد.',
        ),
      );
    }
    if (!parameters.lsl.isFinite) {
      issues.add(
        CalculationIssue(
          code: 'invalid_lsl',
          fieldId: 'lsl',
          message: 'حد پایین مشخصات باید عدد متناهی باشد.',
        ),
      );
    }
    if (parameters.usl.isFinite &&
        parameters.lsl.isFinite &&
        parameters.usl <= parameters.lsl) {
      issues.add(
        CalculationIssue(
          code: 'invalid_limits',
          fieldId: 'usl',
          message: 'حد بالای مشخصات باید بزرگ‌تر از حد پایین مشخصات باشد.',
        ),
      );
    }
    if (!parameters.sigma.isFinite || parameters.sigma <= 0) {
      issues.add(
        CalculationIssue(
          code: 'invalid_sigma',
          fieldId: 'sigma',
          message: 'سیگمای درون‌فرایندی باید عدد متناهی و بزرگ‌تر از صفر باشد.',
        ),
      );
    }
    return issues;
  }
}
