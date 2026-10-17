import 'dart:math' as math;

import '../calculator_domain.dart';
import '../statistics/tool_numeric.dart';

const economicCaution =
    'این محاسبه آموزشی و مشروط به فرض‌هاست، نه توصیهٔ شخصی سرمایه‌گذاری یا قاعدهٔ مالیاتی. واحد پول در همهٔ ورودی‌ها یکسان است؛ زمان، نرخ و جریان باید هم‌دوره باشند.';
const maxEconomicPeriods = 10000.0;

final class EconomicMathError implements Exception {}

double economicChecked(double value, {bool nonzero = false}) {
  if (!value.isFinite || (nonzero && value == 0)) throw EconomicMathError();
  return value;
}

CalculationOutcome economicSafe(CalculationOutcome Function() body) {
  try {
    return body();
  } on EconomicMathError {
    return toolRange();
  }
}

/// Accurate for rates too small for 1+x to differ from one.
double economicLog1p(double x) {
  final u = 1 + x;
  return u == 1 ? x : math.log(u) * (x / (u - 1));
}

double economicExpm1(double x) {
  if (x.abs() >= 0.5) return math.exp(x) - 1;
  var term = x, sum = x;
  for (var k = 2; k <= 100; k++) {
    term *= x / k;
    final next = sum + term;
    if (next == sum) break;
    sum = next;
  }
  return sum;
}

enum EconomicFactor { fp, pf, fa, af, pa, ap }

abstract class EconomicFactorParameters implements CalculatorParameters {
  const EconomicFactorParameters({
    required this.amount,
    required this.rate,
    required this.periods,
  });
  final double amount, rate, periods;
}

List<CalculationIssue> economicFactorIssues(
  double amount,
  double rate,
  double periods,
) => toolValidate([
  ToolNumber('amount', 'مبلغ نامنفی جریان', amount, min: 0),
  ToolNumber('rate', 'نرخ مؤثر هر دوره', rate, min: -1, strictMin: true),
  ToolNumber(
    'periods',
    'تعداد دوره',
    periods,
    min: 0,
    max: maxEconomicPeriods,
    integer: true,
  ),
]);

/// Log of the positive factor. Zero-period empty sums are handled separately.
double economicFactorLog(EconomicFactor kind, double rate, double periods) {
  if (periods == 0) {
    if (kind == EconomicFactor.fp || kind == EconomicFactor.pf) return 0;
    throw EconomicMathError();
  }
  final logGrowth = periods * economicLog1p(rate);
  if (kind == EconomicFactor.fp) return logGrowth;
  if (kind == EconomicFactor.pf) return -logGrowth;
  double logFa;
  if (rate == 0) {
    logFa = math.log(periods);
  } else if (logGrowth.abs() < 0.5) {
    logFa =
        math.log(periods) +
        math.log(economicExpm1(logGrowth) / logGrowth) +
        math.log(economicLog1p(rate) / rate);
  } else if (rate > 0) {
    logFa = logGrowth + economicLog1p(-math.exp(-logGrowth)) - math.log(rate);
  } else {
    logFa = math.log(-economicExpm1(logGrowth)) - math.log(-rate);
  }
  return switch (kind) {
    EconomicFactor.fa => logFa,
    EconomicFactor.af => -logFa,
    EconomicFactor.pa => logFa - logGrowth,
    EconomicFactor.ap => logGrowth - logFa,
    _ => throw StateError('عامل تک‌مبلغی قبلاً پردازش شده است'),
  };
}

double economicFactorValue(EconomicFactor kind, double rate, double periods) {
  if (periods == 0 &&
      (kind == EconomicFactor.fa || kind == EconomicFactor.pa)) {
    return 0;
  }
  return economicChecked(
    math.exp(economicFactorLog(kind, rate, periods)),
    nonzero: true,
  );
}

double economicConverted(double amount, double factor) {
  if (amount == 0 || factor == 0) return 0;
  final direct = amount * factor;
  if (direct.isFinite && direct != 0) return direct;
  return economicChecked(
    math.exp(math.log(amount) + math.log(factor)),
    nonzero: true,
  );
}

CalculationOutcome economicResult({
  required String id,
  required String label,
  required double value,
  required String basis,
  String? unit,
  List<ResultMetric> details = const [],
  List<CalculationWarning> warnings = const [],
}) {
  economicChecked(value);
  return toolResult(
    id: id,
    label: label,
    value: value,
    unit: unit,
    basis: '$basis\n$economicCaution',
    details: details,
    warnings: [
      CalculationWarning(
        code: 'educational_economics',
        message: economicCaution,
      ),
      ...warnings,
    ],
  );
}

CalculationOutcome calculateEconomicFactor(
  String id,
  EconomicFactor kind,
  EconomicFactorParameters p,
  String basis,
) {
  final issues = economicFactorIssues(p.amount, p.rate, p.periods);
  if (issues.isNotEmpty) return CalculationFailure(issues);
  if (p.periods == 0 &&
      (kind == EconomicFactor.af || kind == EconomicFactor.ap)) {
    return toolFailure(
      'undefined_zero_period',
      'برای A/F و A/P با صفر پرداخت، مبلغ قسط یکتا تعریف نمی‌شود؛ تعداد دوره باید مثبت باشد.',
      fieldId: 'periods',
    );
  }
  return economicSafe(() {
    final factor = economicFactorValue(kind, p.rate, p.periods),
        converted = economicConverted(p.amount, factor);
    return economicResult(
      id: id,
      label: 'عامل ${kind.name.toUpperCase()[0]}/${kind.name.toUpperCase()[1]}',
      value: factor,
      unit: 'برابر',
      basis: basis,
      details: [
        metric(
          'converted_amount',
          switch (kind) {
            EconomicFactor.fp => 'F در پایان دورهٔ n',
            EconomicFactor.pf => 'P در زمان صفر',
            EconomicFactor.fa => 'F پس از آخرین پرداخت در n',
            EconomicFactor.af => 'هر A در پایان دوره‌های ۱ تا n',
            EconomicFactor.pa => 'P در زمان صفر برای سری پایان‌دوره',
            EconomicFactor.ap => 'هر A در پایان دوره‌های ۱ تا n',
          },
          converted,
          unit: 'ریال',
        ),
        metric('source_amount', 'مبلغ مبنای ورودی', p.amount, unit: 'ریال'),
        metric('effective_rate', 'نرخ مؤثر هر دوره', p.rate, percentage: true),
        metric('periods', 'تعداد دوره‌های هم‌اندازه', p.periods),
      ],
    );
  });
}

/// Closed-form book value with a salvage floor; avoid factor underflow when
/// multiplication by a large cost still yields a representable book value.
double decliningBook(double cost, double salvage, double rate, double year) {
  final logMultiplier = year * economicLog1p(-rate);
  if (salvage > 0 && logMultiplier <= math.log(salvage) - math.log(cost)) {
    return salvage;
  }
  final direct = cost * math.exp(logMultiplier);
  final raw = direct > 0
      ? direct
      : economicChecked(
          math.exp(math.log(cost) + logMultiplier),
          nonzero: true,
        );
  return math.max(salvage, math.min(cost, raw));
}
