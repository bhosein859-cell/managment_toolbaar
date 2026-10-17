import 'dart:math' as math;

import '../../calculator_domain.dart';
import 'finance_support.dart';

final class IrrParameters implements CalculatorParameters {
  IrrParameters(Iterable<double> cashFlows)
    : cashFlows = List.unmodifiable(cashFlows);

  /// CF0 at time zero, CF1 ... CFn at equally spaced period ends.
  final List<double> cashFlows;
}

/// Conservative IRR: only one sign change (ignoring zero flows), so the
/// discounted-cash-flow polynomial has exactly one positive discount-factor
/// root. Multi-sign-change series are explicitly rejected, never guessed.
final class IrrEngine implements CalculatorEngine<IrrParameters> {
  const IrrEngine({this.maxIterations = 256});
  final int maxIterations;
  static const basis =
      'اولین سطر CF0 در زمان صفر و سطرهای بعد پایان دوره‌های مساوی‌اند؛ نرخ خروجی مؤثر همان دوره است، نه الزاماً سالانه. این حل‌گر فقط سری با یک تغییر علامت پس از حذف صفرها را حل می‌کند؛ سری غیرمتعارف با احتمال چند ریشه صریحاً رد می‌شود. IRR معیار توصیهٔ شخصی یا تضمین سود نیست؛ XIRR و تاریخ نامنظم پشتیبانی نمی‌شود.';
  @override
  String get calculatorId => 'irr';
  @override
  InputBinding<IrrParameters> bind(CalculatorInput input) {
    final p = IrrParameters(input.requireNumberList('cash_flows'));
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(IrrParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    var previousSign = 0.0;
    var changes = 0;
    for (final flow in p.cashFlows) {
      if (flow == 0) continue;
      if (previousSign != 0 && flow.sign != previousSign) changes++;
      previousSign = flow.sign;
    }
    if (changes == 0) {
      return financeFailure(
        'no_irr',
        'جریان‌ها تغییر علامت ندارند؛ معادله در دامنهٔ نرخ بیشتر از منفی صد درصد ریشه ندارد.',
        fieldId: 'cash_flows',
      );
    }
    if (changes > 1) {
      return financeFailure(
        'nonconventional_flows',
        'بیش از یک تغییر علامت وجود دارد؛ ممکن است صفر، یک یا چند IRR وجود داشته باشد. این حل‌گر همهٔ ریشه‌ها را تضمین نمی‌کند و یک جواب انتخابی نمایش نمی‌دهد.',
        fieldId: 'cash_flows',
      );
    }
    if (maxIterations < 1) {
      return financeFailure(
        'no_convergence',
        'بودجهٔ تکرار کافی نیست؛ هیچ نرخ حدسی نمایش داده نشد.',
      );
    }
    // y=log(1+r) spans safely representable negative rates to r≈1e300.
    var lower = math.log(1 - 0.9999999999999999);
    var upper = math.log(1e300);
    var low = _evaluate(p.cashFlows, lower);
    final high = _evaluate(p.cashFlows, upper);
    if (low.sum.sign == high.sum.sign && low.sum != 0 && high.sum != 0) {
      return financeFailure(
        'root_out_of_range',
        'ریشه در بازهٔ عددی قابل بررسی این نسخه محصور نشد؛ این پیام به معنی نبود ریاضی IRR نیست. دامنهٔ حل از نرخ قابل نمایش نزدیک منفی صد درصد تا حدود ۱۰^۳۰۰ است.',
      );
    }
    // Preserve a true zero-rate case without log/exp cancellation noise.
    if (_zeroAtOrigin(p.cashFlows)) {
      lower = 0;
      upper = 0;
    }
    for (var iteration = 1; iteration <= maxIterations; iteration++) {
      final y = lower + (upper - lower) / 2;
      final current = _evaluate(p.cashFlows, y);
      if (current.relativeResidual <= 1e-12) {
        final rate = financeExpm1(y);
        if (!rate.isFinite || rate <= -1 || !(rate * 100).isFinite) {
          return financeRange();
        }
        final verified = _evaluate(p.cashFlows, financeLog1p(rate));
        if (verified.relativeResidual > 1e-10) {
          return financeFailure(
            'insufficient_precision',
            'ریشهٔ تبدیل‌شده به نرخ، دقت کافی برای معادله ندارد؛ نرخ ظاهری نمایش داده نشد.',
          );
        }
        return financeResult(
          id: calculatorId,
          label: 'نرخ بازده داخلی هر دوره',
          value: rate,
          percentage: true,
          basis: basis,
          details: [
            financeMetric('iterations', 'تعداد تکرار حل', iteration.toDouble()),
            financeMetric(
              'relative_residual',
              'باقیماندهٔ نسبی معادله',
              verified.relativeResidual,
            ),
            financeMetric(
              'period_count',
              'تعداد فاصله‌های مساوی',
              p.cashFlows.length - 1.0,
              unit: 'دوره',
            ),
          ],
        );
      }
      if (current.sum.sign == low.sum.sign) {
        lower = y;
        low = current;
      } else {
        upper = y;
      }
      if (lower == upper) break;
    }
    return financeFailure(
      'no_convergence',
      'حل IRR با معیار باقیماندهٔ لازم همگرا نشد؛ نرخ حدسی یا آخرین تکرار به‌عنوان جواب نمایش داده نمی‌شود.',
    );
  }

  List<CalculationIssue> _validate(IrrParameters p) {
    if (p.cashFlows.length < 2 || p.cashFlows.length > 1000) {
      return [
        CalculationIssue(
          code: 'invalid_flow_count',
          fieldId: 'cash_flows',
          message: 'IRR به ۲ تا ۱۰۰۰ سطر شامل CF0 نیاز دارد.',
        ),
      ];
    }
    for (var i = 0; i < p.cashFlows.length; i++) {
      if (!p.cashFlows[i].isFinite) {
        return [
          CalculationIssue(
            code: 'invalid_cash_flow',
            fieldId: 'cash_flows',
            itemIndex: i,
            message: 'همهٔ جریان‌ها باید متناهی باشند.',
          ),
        ];
      }
    }
    if (p.cashFlows.every((v) => v == 0)) {
      return [
        CalculationIssue(
          code: 'indeterminate_irr',
          fieldId: 'cash_flows',
          message: 'همهٔ جریان‌ها صفرند؛ IRR یکتا و معناداری تعیین نمی‌شود.',
        ),
      ];
    }
    if (p.cashFlows.first == 0) {
      return [
        CalculationIssue(
          code: 'zero_initial_flow',
          fieldId: 'cash_flows',
          message: 'در این نسخه CF0 باید غیرصفر باشد؛ سطرهای صفر اولیه را با حفظ تعریف زمان‌بندی بازبینی کنید.',
        ),
      ];
    }
    return [];
  }

  bool _zeroAtOrigin(List<double> flows) {
    final scale = flows.map((v) => v.abs()).reduce(math.max);
    var sum = 0.0, correction = 0.0;
    for (final flow in flows) {
      final term = flow / scale;
      if (flow != 0 && term == 0) return false;
      final next = sum + term;
      correction += sum.abs() >= term.abs()
          ? (sum - next) + term
          : (term - next) + sum;
      sum = next;
    }
    return sum + correction == 0;
  }

  // Log scaling + compensated signed summation prevents discounted-term
  // overflow. Omitted underflow-scale terms are below binary64 resolution of
  // the normalized sum. Residual is relative to the sum of absolute terms.
  _IrrEvaluation _evaluate(List<double> flows, double y) {
    final logs = <double>[];
    var largest = double.negativeInfinity;
    for (var i = 0; i < flows.length; i++) {
      final logTerm = flows[i] == 0
          ? double.negativeInfinity
          : math.log(flows[i].abs()) - i * y;
      logs.add(logTerm);
      if (logTerm > largest) largest = logTerm;
    }
    var sum = 0.0, correction = 0.0, magnitude = 0.0;
    for (var i = 0; i < flows.length; i++) {
      if (flows[i] == 0) continue;
      final absolute = math.exp(logs[i] - largest);
      final term = flows[i].sign * absolute;
      final next = sum + term;
      correction += sum.abs() >= term.abs()
          ? (sum - next) + term
          : (term - next) + sum;
      sum = next;
      magnitude += absolute;
    }
    final result = sum + correction;
    return _IrrEvaluation(result, result.abs() / magnitude);
  }
}

final class _IrrEvaluation {
  const _IrrEvaluation(this.sum, this.relativeResidual);
  final double sum, relativeResidual;
}
