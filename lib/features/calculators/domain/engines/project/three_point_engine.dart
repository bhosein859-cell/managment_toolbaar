import '../../calculator_domain.dart';
import '../../project/estimate_moments.dart';
import '../../statistics/tool_numeric.dart';

final class ThreePointParameters implements CalculatorParameters {
  const ThreePointParameters({
    required this.optimistic,
    required this.mostLikely,
    required this.pessimistic,
    this.method = 'triangular',
  });
  final double optimistic;
  final double mostLikely;
  final double pessimistic;
  final String method;
}

final class ThreePointEngine implements CalculatorEngine<ThreePointParameters> {
  const ThreePointEngine();
  static const basis =
      'O کمینه، M مُد و P بیشینه با O≤M≤P و واحد مشترک‌اند. پیش‌فرض توزیع مثلثی با میانگین (O+M+P)/۳ و واریانس (O²+M²+P²−OM−OP−MP)/۱۸ است؛ این تفسیر به پذیرفتن توزیع مثلثی وابسته است. گزینهٔ PERT از میانگین وزنی و واریانس تقریبی کلاسیک استفاده می‌کند. برابر بودن سه نقطه برآورد قطعی با واریانس صفر می‌دهد؛ هیچ احتمال یا صدک ساختگی تولید نمی‌شود.';
  @override
  String get calculatorId => 'three_point';
  @override
  InputBinding<ThreePointParameters> bind(CalculatorInput input) {
    final p = ThreePointParameters(
      optimistic: input.requireNumber('optimistic'),
      mostLikely: input.requireNumber('most_likely'),
      pessimistic: input.requireNumber('pessimistic'),
      method: input.requireChoice('method'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(ThreePointParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final e = estimateMoments(
      p.optimistic,
      p.mostLikely,
      p.pessimistic,
      pert: p.method == 'pert',
    );
    if (e == null) return toolRange();
    return toolResult(
      id: calculatorId,
      label: 'میانگین مدل انتخابی سه‌نقطه‌ای',
      value: e.mean,
      unit: 'واحد مشترک',
      basis: basis,
      details: [
        textMetric(
          'selected_model',
          'مدل انتخابی',
          p.method == 'pert' ? 'PERT وزنی با واریانس تقریبی' : 'توزیع مثلثی',
        ),
        metric(
          'standard_deviation',
          'انحراف معیار مدل',
          e.sd,
          unit: 'واحد مشترک',
        ),
        metric('variance', 'واریانس مدل', e.variance, unit: 'واحد مشترک مربع'),
      ],
    );
  }

  List<CalculationIssue> _validate(ThreePointParameters p) {
    final issues = toolValidate([
      ToolNumber('optimistic', 'برآورد خوش‌بینانه O', p.optimistic, min: 0),
      ToolNumber('most_likely', 'برآورد محتمل M', p.mostLikely, min: 0),
      ToolNumber('pessimistic', 'برآورد بدبینانه P', p.pessimistic, min: 0),
    ]);
    if (issues.isNotEmpty) return issues;
    if (p.optimistic > p.mostLikely || p.mostLikely > p.pessimistic) {
      issues.add(
        CalculationIssue(
          code: 'unordered_estimates',
          fieldId: 'most_likely',
          message: 'باید O ≤ M ≤ P باشد؛ جابه‌جایی خودکار انجام نمی‌شود.',
        ),
      );
    }
    if (!['triangular', 'pert'].contains(p.method)) {
      issues.add(
        CalculationIssue(
          code: 'invalid_method',
          fieldId: 'method',
          message: 'مدل برآورد معتبر نیست.',
        ),
      );
    }
    return issues;
  }
}
