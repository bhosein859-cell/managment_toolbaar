import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class CoqParameters implements CalculatorParameters {
  const CoqParameters({
    required this.prevention,
    required this.appraisal,
    required this.internalFailure,
    required this.externalFailure,
  });
  final double prevention;
  final double appraisal;
  final double internalFailure;
  final double externalFailure;
}

final class CoqEngine implements CalculatorEngine<CoqParameters> {
  const CoqEngine();
  static const name = 'هزینهٔ کیفیت — COQ';
  static const basis =
      'مدل PAF و یک بازه/ارز مشترک با تخصیص بدون هم‌پوشانی فرض شده است. در این ابزار COPQ فقط شکست داخلی و خارجی است؛ تعریف‌های گسترده‌تر سازمانی ممکن است ارزیابی یا هزینهٔ فرصت را هم لحاظ کنند. هزینهٔ پنهان/فرصت خودکار برآورد نمی‌شود. سهم شکست شاخص توصیفی است، نه برچسب قطعی کیفیت خوب یا بد.';
  @override
  String get calculatorId => 'coq';
  @override
  InputBinding<CoqParameters> bind(CalculatorInput input) {
    final p = CoqParameters(
      prevention: input.requireNumber('prevention'),
      appraisal: input.requireNumber('appraisal'),
      internalFailure: input.requireNumber('internal_failure'),
      externalFailure: input.requireNumber('external_failure'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(CoqParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final conformity = p.prevention + p.appraisal,
        failureCost = p.internalFailure + p.externalFailure;
    final total = conformity + failureCost;
    if (!total.isFinite) return toolRange();
    final share = total > 0 ? failureCost / total : 0.0;
    if (invalidNumeric(share, nonzero: failureCost > 0)) return toolRange();
    return toolResult(
      id: calculatorId,
      label: name,
      value: total,
      unit: 'ریال/بازه',
      basis: basis,
      details: [
        metric('conformity', 'پیشگیری و ارزیابی', conformity, unit: 'ریال'),
        metric(
          'copq',
          'شکست داخلی و خارجی (COPQ این مدل)',
          failureCost,
          unit: 'ریال',
        ),
        if (total > 0)
          metric('failure_share', 'سهم شکست از COQ', share, percentage: true)
        else
          textMetric(
            'undefined_share',
            'سهم شکست',
            'برای جمع صفر تعریف نمی‌شود',
          ),
      ],
    );
  }

  List<CalculationIssue> _validate(CoqParameters p) {
    final issues = toolValidate([
      ToolNumber('prevention', 'هزینهٔ پیشگیری', p.prevention, min: 0),
      ToolNumber('appraisal', 'هزینهٔ ارزیابی', p.appraisal, min: 0),
      ToolNumber(
        'internal_failure',
        'هزینهٔ شکست داخلی',
        p.internalFailure,
        min: 0,
      ),
      ToolNumber(
        'external_failure',
        'هزینهٔ شکست خارجی',
        p.externalFailure,
        min: 0,
      ),
    ]);
    if (issues.isNotEmpty) return issues;

    return issues;
  }
}
