import 'dart:math' as math;

/// Acklam rational inverse-standard-normal approximation (no fitted process
/// sigma). Independent tabulated-point tests use absolute tolerance 5e-8;
/// this is not a bound proved for every representable probability.
/// Open probability interval only; callers handle observational endpoints.
double normalQuantile(double p) {
  if (!p.isFinite || p <= 0 || p >= 1) {
    throw ArgumentError('احتمال باید بین صفر و یک و بدون دو انتها باشد.');
  }
  const a = [
    -3.969683028665376e1,
    2.209460984245205e2,
    -2.759285104469687e2,
    1.383577518672690e2,
    -3.066479806614716e1,
    2.506628277459239,
  ];
  const b = [
    -5.447609879822406e1,
    1.615858368580409e2,
    -1.556989798598866e2,
    6.680131188771972e1,
    -1.328068155288572e1,
  ];
  const c = [
    -7.784894002430293e-3,
    -3.223964580411365e-1,
    -2.400758277161838,
    -2.549732539343734,
    4.374664141464968,
    2.938163982698783,
  ];
  const d = [
    7.784695709041462e-3,
    3.224671290700398e-1,
    2.445134137142996,
    3.754408661907416,
  ];
  if (p < 0.02425 || p > 1 - 0.02425) {
    final lower = p < 0.02425;
    final x = math.sqrt(-2 * math.log(lower ? p : 1 - p));
    final ratio =
        (((((c[0] * x + c[1]) * x + c[2]) * x + c[3]) * x + c[4]) * x + c[5]) /
        ((((d[0] * x + d[1]) * x + d[2]) * x + d[3]) * x + 1);
    return lower ? ratio : -ratio;
  }
  final x = p - 0.5, r = x * x;
  return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) *
      x /
      (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
}
