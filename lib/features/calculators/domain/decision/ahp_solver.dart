import 'dart:math' as math;

import '../calculator_domain.dart';
import '../statistics/tool_numeric.dart';
import 'decision_math.dart';

const ahpRandomIndex = {
  1: 0.0,
  2: 0.0,
  3: 0.58,
  4: 0.90,
  5: 1.12,
  6: 1.24,
  7: 1.32,
  8: 1.41,
  9: 1.45,
  10: 1.49,
};
List<CalculationIssue> validatePairwise(List<double> a, int n, String field) {
  if (a.length != n * n) {
    return [
      decisionIssue(
        'pairwise_shape',
        'هر ماتریس مقایسهٔ زوجی باید دقیقاً n×n خانه داشته باشد؛ ترتیب سطری است.',
        field,
      ),
    ];
  }
  if (a.any((v) => !v.isFinite || v < 1 / 9 || v > 9)) {
    return [
      decisionIssue(
        'invalid_pairwise',
        'نسبت‌های زوجی باید مثبت و در مقیاس پیوستهٔ ۱/۹ تا ۹ باشند.',
        field,
      ),
    ];
  }
  for (var i = 0; i < n; i++) {
    if ((a[i * n + i] - 1).abs() > 1e-9) {
      return [
        decisionIssue(
          'invalid_diagonal',
          'قطر ماتریس مقایسهٔ زوجی باید یک باشد (تلرانس ۱۰ به توان منفی ۹).',
          field,
        ),
      ];
    }
    for (var j = i + 1; j < n; j++) {
      if ((a[i * n + j] * a[j * n + i] - 1).abs() > 1e-8) {
        return [
          decisionIssue(
            'non_reciprocal',
            'ماتریس باید متقابل باشد: حاصل‌ضرب هر دو درایهٔ متناظر معکوس نزدیک یک، با تلرانس ۱۰ به توان منفی ۸.',
            field,
          ),
        ];
      }
    }
  }
  return [];
}

final class AhpWeights {
  const AhpWeights(
    this.weights,
    this.lambda,
    this.ci,
    this.cr,
    this.iterations,
  );
  final List<double> weights;
  final double lambda, ci, cr;
  final int iterations;
}

AhpWeights principalWeights(
  List<double> a,
  int n, {
  required int maxIterations,
}) {
  var w = List<double>.filled(n, 1 / n);
  for (var iteration = 1; iteration <= maxIterations; iteration++) {
    final aw = [
      for (var i = 0; i < n; i++)
        compensatedSum([for (var j = 0; j < n; j++) a[i * n + j] * w[j]]),
    ];
    final sum = compensatedSum(aw), next = [for (final v in aw) v / sum];
    final delta = compensatedSum([
      for (var i = 0; i < n; i++) (next[i] - w[i]).abs(),
    ]);
    w = next;
    if (delta <= 1e-12) {
      final product = [
        for (var i = 0; i < n; i++)
          compensatedSum([for (var j = 0; j < n; j++) a[i * n + j] * w[j]]),
      ];
      final lambda =
          compensatedSum([for (var i = 0; i < n; i++) product[i] / w[i]]) / n;
      final residual = [
        for (var i = 0; i < n; i++) (product[i] - lambda * w[i]).abs(),
      ].reduce(math.max);
      if (residual > 1e-8) break;
      final rawCi = (lambda - n) / (n - 1);
      if (rawCi < -1e-8) throw DecisionMathError();
      final ci = math.max(0.0, rawCi),
          ri = ahpRandomIndex[n]!,
          cr = ri == 0 ? 0.0 : ci / ri;
      return AhpWeights(
        List.unmodifiable(w),
        checked(lambda),
        checked(ci),
        checked(cr),
        iteration,
      );
    }
  }
  throw DecisionMathError(
    'ahp_no_convergence',
    'بردار ویژهٔ AHP در سقف تکرار با دقت مشخص همگرا نشد؛ وزن یا رتبهٔ حدسی تولید نشد.',
  );
}
