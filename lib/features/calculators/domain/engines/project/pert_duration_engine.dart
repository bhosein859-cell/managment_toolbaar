import '../../calculator_domain.dart';
import '../../project/estimate_moments.dart';
import '../../statistics/tool_numeric.dart';

final class PertDurationParameters implements CalculatorParameters {
  const PertDurationParameters({
    required this.optimistic,
    required this.mostLikely,
    required this.pessimistic,
  });
  final double optimistic;
  final double mostLikely;
  final double pessimistic;
}

final class PertDurationEngine
    implements CalculatorEngine<PertDurationParameters> {
  const PertDurationEngine();
  static const basis =
      'روش PERT کلاسیک: میانگین وزنی (O+۴M+P)/۶، انحراف معیار تقریبی (P−O)/۶ و واریانس مربع آن است. این یک تقریب برنامه‌ریزی است، نه برازش توزیع بتا، تضمین احتمال یا بازهٔ اطمینان. جمع واریانس فعالیت‌ها فقط با فرض استقلال و مسیر ثابت معنا دارد؛ این ابزار شبکه یا مسیر احتمالی پروژه را برآورد نمی‌کند.';
  @override
  String get calculatorId => 'pert_duration';
  @override
  InputBinding<PertDurationParameters> bind(CalculatorInput input) {
    final p = PertDurationParameters(
      optimistic: input.requireNumber('optimistic'),
      mostLikely: input.requireNumber('most_likely'),
      pessimistic: input.requireNumber('pessimistic'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(PertDurationParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final e = estimateMoments(
      p.optimistic,
      p.mostLikely,
      p.pessimistic,
      pert: true,
    );
    if (e == null) return toolRange();
    return toolResult(
      id: calculatorId,
      label: 'مدت مورد انتظار PERT',
      value: e.mean,
      unit: 'روز',
      basis: basis,
      details: [
        metric('standard_deviation', 'انحراف معیار تقریبی', e.sd, unit: 'روز'),
        metric('variance', 'واریانس تقریبی PERT', e.variance, unit: 'روز مربع'),
      ],
    );
  }

  List<CalculationIssue> _validate(PertDurationParameters p) {
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
    return issues;
  }
}
