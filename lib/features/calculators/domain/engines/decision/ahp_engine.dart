import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../decision/ahp_solver.dart';
import '../../decision/decision_math.dart';
import '../../statistics/tool_numeric.dart';

final class AhpParameters implements CalculatorParameters {
  AhpParameters({
    required this.alternatives,
    required this.criteria,
    required Iterable<double> criteriaMatrix,
    required Iterable<double> localMatrices,
  }) : criteriaMatrix = List.unmodifiable(criteriaMatrix),
       localMatrices = List.unmodifiable(localMatrices);
  final double alternatives, criteria;
  final List<double> criteriaMatrix, localMatrices;
}

final class AhpEngine implements CalculatorEngine<AhpParameters> {
  const AhpEngine({this.maxIterations = 10000});
  final int maxIterations;
  static const basis =
      'AHP دو سطح معیار/گزینه با بردار ویژهٔ اصلی Perron، تکرار توانی با تغییر L1 حداکثر ۱۰ به توان منفی ۱۲ و باقیماندهٔ حداکثر ۱۰ به توان منفی ۸ است. ماتریس‌ها مثبت، متقابل و روی مقیاس پیوستهٔ ۱/۹ تا ۹ با قطر یک‌اند؛ اعداد لزوماً فقط صحیح‌های ساتی نیستند. ابتدا ماتریس معیارها و سپس یک ماتریس گزینه‌ها برای هر معیار به ترتیب وارد می‌شود؛ وزن جهانی جمع وزن معیار × اولویت محلی گزینه است. λmax و CI=(λmax−n)/(n−۱) و CR=CI/RI برای تمام ماتریس‌ها محاسبه می‌شوند. RI جدول متعارف برای ابعاد ۲ تا ۱۰ است؛ برای n=۲، RI صفر و CR قراردادی صفر است و آزمون مستقل سازگاری مفیدی نیست. CR بیش از ۰٫۱ صرفاً هشدار بازبینی قضاوت، نه رد خودکار داده یا حکم کیفیت تصمیم است. در عدم همگرایی رتبهٔ حدسی داده نمی‌شود. هم‌رتبگی با تلرانس نسبی ۱۰ به توان منفی ۱۰ گزارش می‌شود. استقلال ترجیحات، ساختار سلسله‌مراتبی و قضاوت‌های قابل مقایسه فرض شده‌اند؛ وارونگی رتبه با تغییر مجموعهٔ گزینه‌ها ممکن است.';
  @override
  String get calculatorId => 'ahp';
  @override
  InputBinding<AhpParameters> bind(CalculatorInput input) {
    final p = AhpParameters(
      alternatives: input.requireNumber('alternatives'),
      criteria: input.requireNumber('criteria'),
      criteriaMatrix: input.requireNumberList('criteria_matrix'),
      localMatrices: input.requireNumberList('local_matrices'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(AhpParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    return safelyDecide(() {
      final n = p.alternatives.toInt(),
          m = p.criteria.toInt(),
          criteria = principalWeights(
            p.criteriaMatrix,
            m,
            maxIterations: maxIterations,
          ),
          local = [
            for (var j = 0; j < m; j++)
              principalWeights(
                p.localMatrices.sublist(j * n * n, (j + 1) * n * n),
                n,
                maxIterations: maxIterations,
              ),
          ];
      final scores = [
        for (var i = 0; i < n; i++)
          weightedValue([
            for (var j = 0; j < m; j++) local[j].weights[i],
          ], criteria.weights),
      ];
      final all = [criteria, ...local], crs = all.map((v) => v.cr).toList();
      return decisionResult(
        id: calculatorId,
        label: 'بیشترین اولویت جهانی AHP در این مدل',
        value: scores.reduce(math.max),
        basis: basis,
        details: [
          ...rankingMetrics(scores),
          seriesMetric(
            'criteria_weights',
            'اولویت معیارها از بردار ویژه',
            criteria.weights,
          ),
          seriesMetric(
            'local_priorities',
            'اولویت‌های محلی؛ معیار به معیار و گزینه به گزینه',
            local.expand((v) => v.weights),
          ),
          seriesMetric(
            'lambda_max',
            'λmax؛ ابتدا معیارها، سپس ماتریس‌های محلی',
            all.map((v) => v.lambda),
          ),
          seriesMetric(
            'consistency_index',
            'CI همان ترتیب',
            all.map((v) => v.ci),
          ),
          seriesMetric(
            'consistency_ratio',
            'CR همان ترتیب؛ RI صفر به‌صورت قراردادی صفر',
            crs,
          ),
          seriesMetric(
            'iterations',
            'تعداد تکرار همان ترتیب',
            all.map((v) => v.iterations.toDouble()),
          ),
        ],
        warnings: [
          if (crs.any((v) => v > 0.1))
            CalculationWarning(
              code: 'ahp_consistency_review',
              message: 'حداقل یک CR از ۰٫۱ بیشتر است؛ این آستانهٔ متعارف برای بازبینی قضاوت است، نه اثبات بدبودن تصمیم. همهٔ CRها را بررسی کنید.',
            ),
        ],
      );
    });
  }

  List<CalculationIssue> _validate(AhpParameters p) {
    final issues = toolValidate([
      ToolNumber(
        'alternatives',
        'تعداد گزینه',
        p.alternatives,
        min: 2,
        max: 10,
        integer: true,
      ),
      ToolNumber(
        'criteria',
        'تعداد معیار',
        p.criteria,
        min: 2,
        max: 10,
        integer: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;
    if (maxIterations < 1) {
      return [
        CalculationIssue(
          code: 'invalid_solver',
          message: 'سقف تکرار حل‌گر باید مثبت باشد.',
        ),
      ];
    }
    final n = p.alternatives.toInt(), m = p.criteria.toInt();
    issues.addAll(validatePairwise(p.criteriaMatrix, m, 'criteria_matrix'));
    if (p.localMatrices.length != m * n * n) {
      issues.add(
        decisionIssue(
          'local_shape',
          'دقیقاً معیار × گزینه × گزینه خانه برای ماتریس‌های محلی لازم است.',
          'local_matrices',
        ),
      );
      return issues;
    }
    for (var j = 0; j < m; j++) {
      issues.addAll(
        validatePairwise(
          p.localMatrices.sublist(j * n * n, (j + 1) * n * n),
          n,
          'local_matrices',
        ),
      );
    }
    return issues;
  }
}
