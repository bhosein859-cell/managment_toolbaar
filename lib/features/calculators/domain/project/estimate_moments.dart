import 'dart:math' as math;

final class EstimateMoments {
  const EstimateMoments(this.mean, this.sd, this.variance);
  final double mean, sd, variance;
}

/// Ordered nonnegative finite inputs, checked in each independent engine.
EstimateMoments? estimateMoments(
  double o,
  double m,
  double p, {
  required bool pert,
}) {
  if (p == 0) return const EstimateMoments(0, 0, 0);
  final mean =
      (pert ? (o / p + 4 * (m / p) + 1) / 6 : (o / p + m / p + 1) / 3) * p;
  final width = p - o;
  final r = width == 0 ? 0 : (m - o) / width;
  final sd = pert
      ? width / 6
      : width / math.sqrt(18) * math.sqrt(1 + r * r - r);
  final variance = sd * sd;
  if (!mean.isFinite ||
      mean == 0 ||
      !sd.isFinite ||
      !variance.isFinite ||
      (width > 0 && (sd == 0 || variance == 0))) {
    return null;
  }
  return EstimateMoments(mean, sd, variance);
}
