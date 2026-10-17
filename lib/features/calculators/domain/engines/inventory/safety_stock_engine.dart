import 'dart:math' as math;

import '../../calculator_domain.dart';
import '../../statistics/normal_quantile.dart';
import '../../statistics/tool_numeric.dart';

final class SafetyStockParameters implements CalculatorParameters {
  const SafetyStockParameters({
    required this.meanDemand,
    required this.demandSd,
    required this.meanLead,
    required this.leadSd,
    required this.serviceLevel,
  });
  final double meanDemand;
  final double demandSd;
  final double meanLead;
  final double leadSd;
  final double serviceLevel;
}

final class SafetyStockEngine
    implements CalculatorEngine<SafetyStockParameters> {
  const SafetyStockEngine();
  static const name = 'ذخیرهٔ اطمینان آماری';
  static const basis =
      'تقاضای روزانه مستقل و هم‌توزیع و مستقل از زمان تأمین فرض شده است؛ واریانس تقاضای زمان تأمین با L×σd²+d²×σL² تقریب می‌شود. احتمال ورودی سطح خدمت چرخه‌ای یک‌طرفه است، نه fill rate. مدل نرمال، تقاضای فصلی/هم‌بسته، تأمین وابسته به تقاضا و دم سنگین را تضمین نمی‌کند. برای زمان تأمین ثابت σL=۰ بگذارید؛ واحد همهٔ زمان‌ها روز یکسان است.';
  @override
  String get calculatorId => 'safety_stock';
  @override
  InputBinding<SafetyStockParameters> bind(CalculatorInput input) {
    final p = SafetyStockParameters(
      meanDemand: input.requireNumber('mean_demand'),
      demandSd: input.requireNumber('demand_sd'),
      meanLead: input.requireNumber('mean_lead'),
      leadSd: input.requireNumber('lead_sd'),
      serviceLevel: input.requireNumber('service_level'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(SafetyStockParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final a = math.sqrt(p.meanLead) * p.demandSd, b = p.meanDemand * p.leadSd;
    if (invalidNumeric(a, nonzero: p.meanLead > 0 && p.demandSd > 0) ||
        invalidNumeric(b, nonzero: p.meanDemand > 0 && p.leadSd > 0)) {
      return toolRange();
    }
    final sd = stableHypot(a, b);
    if (!sd.isFinite) return toolRange();
    final z = normalQuantile(p.serviceLevel), value = z * sd;
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      unit: 'واحد',
      nonzero: z > 0 && sd > 0,
      basis: basis,
      details: [
        metric('z', 'ضریب نرمال یک‌طرفه', z),
        metric(
          'lead_demand_sd',
          'انحراف معیار تقاضای زمان تأمین',
          sd,
          unit: 'واحد',
        ),
      ],
    );
  }

  List<CalculationIssue> _validate(SafetyStockParameters p) {
    final issues = toolValidate([
      ToolNumber('mean_demand', 'میانگین تقاضای روزانه', p.meanDemand, min: 0),
      ToolNumber('demand_sd', 'انحراف معیار تقاضای روزانه', p.demandSd, min: 0),
      ToolNumber('mean_lead', 'میانگین زمان تأمین', p.meanLead, min: 0),
      ToolNumber('lead_sd', 'انحراف معیار زمان تأمین', p.leadSd, min: 0),
      ToolNumber(
        'service_level',
        'سطح خدمت چرخه‌ای یک‌طرفه',
        p.serviceLevel,
        min: 0.5,
        max: 1,
        strictMax: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;
    if ((p.meanDemand == 0 && p.demandSd > 0) ||
        (p.meanLead == 0 && p.leadSd > 0)) {
      issues.add(
        CalculationIssue(
          code: 'inconsistent_moments',
          fieldId: p.meanDemand == 0 && p.demandSd > 0
              ? 'demand_sd'
              : 'lead_sd',
          message: 'برای متغیر نامنفی، میانگین صفر با انحراف معیار مثبت سازگار نیست.',
        ),
      );
    }
    return issues;
  }
}
