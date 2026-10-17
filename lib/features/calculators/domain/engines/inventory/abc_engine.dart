import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class AbcParameters implements CalculatorParameters {
  AbcParameters({
    required Iterable<double> annualQuantities,
    required Iterable<double> unitCosts,
    this.aThreshold = 0.8,
    this.bThreshold = 0.95,
  }) : annualQuantities = List.unmodifiable(annualQuantities),
       unitCosts = List.unmodifiable(unitCosts);
  final List<double> annualQuantities, unitCosts;
  final double aThreshold, bThreshold;
}

final class AbcEngine implements CalculatorEngine<AbcParameters> {
  const AbcEngine();
  static const basis =
      'ارزش مصرف سالانه = مقدار مصرف سالانه × بهای واحد است، نه ارزش موجودی لحظه‌ای یا اهمیت بحرانی قلم. دو فهرست هم‌ردیف‌اند و SKU-1 همان ردیف اول ورودی است. ترتیب نزولی ارزش و در تساوی، ترتیب ردیف ورودی حفظ می‌شود. طبقه با سهم تجمعیِ پیش از افزودن قلم تعیین می‌شود: قلم عبوردهندهٔ مرز در طبقهٔ بالاتر می‌ماند؛ ارزش صفر همیشه C است. آستانه‌های تجمعی A/B سیاست قابل تغییرند، نه قانون ۸۰/۲۰ قطعی یا برچسب خوب/بد؛ اقلام بحرانی/کمیاب باید جدا بررسی شوند. سقف این فرم ۱۰۰ قلم است.';
  @override
  String get calculatorId => 'abc';
  @override
  InputBinding<AbcParameters> bind(CalculatorInput input) {
    final p = AbcParameters(
      annualQuantities: input.requireNumberList('annual_quantities'),
      unitCosts: input.requireNumberList('unit_costs'),
      aThreshold: input.requireNumber('a_threshold'),
      bThreshold: input.requireNumber('b_threshold'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(AbcParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final values = <double>[];
    for (var i = 0; i < p.annualQuantities.length; i++) {
      final value = p.annualQuantities[i] * p.unitCosts[i];
      if (invalidNumeric(
        value,
        nonzero: p.annualQuantities[i] > 0 && p.unitCosts[i] > 0,
      )) {
        return toolRange();
      }
      values.add(value);
    }
    final total = compensatedSum(values);
    if (!total.isFinite) return toolRange();
    if (total == 0) {
      return toolFailure(
        'zero_total_value',
        'جمع ارزش مصرف سالانه صفر است؛ سهم و طبقه‌بندی ABC معنادار محاسبه نمی‌شود.',
      );
    }
    final order = List.generate(values.length, (i) => i)
      ..sort((i, j) {
        final c = values[j].compareTo(values[i]);
        return c != 0 ? c : i.compareTo(j);
      });
    final details = <ResultMetric>[];
    final counts = {'A': 0, 'B': 0, 'C': 0};
    var cumulative = 0.0, correction = 0.0;
    for (final index in order) {
      final value = values[index], before = (cumulative + correction) / total;
      final classification = value == 0
          ? 'C'
          : before < p.aThreshold
          ? 'A'
          : before < p.bThreshold
          ? 'B'
          : 'C';
      counts[classification] = counts[classification]! + 1;
      final next = cumulative + value;
      correction += cumulative.abs() >= value.abs()
          ? (cumulative - next) + value
          : (value - next) + cumulative;
      cumulative = next;
      final share = value / total, after = (cumulative + correction) / total;
      if (invalidNumeric(share, nonzero: value > 0) || !after.isFinite) {
        return toolRange();
      }
      final id = 'sku_${index + 1}';
      details.addAll([
        textMetric(
          '${id}_class',
          'طبقهٔ قلم ورودی SKU-${index + 1}',
          classification,
        ),
        metric(
          '${id}_annual_value',
          'ارزش مصرف سالانهٔ SKU-${index + 1}',
          value,
          unit: 'ریال/سال',
        ),
        metric('${id}_share', 'سهم SKU-${index + 1}', share, percentage: true),
        metric(
          '${id}_cumulative',
          'سهم تجمعی پس از SKU-${index + 1}',
          after,
          percentage: true,
        ),
      ]);
    }
    return toolResult(
      id: calculatorId,
      label: 'ارزش کل مصرف سالانهٔ اقلام ABC',
      value: total,
      unit: 'ریال/سال',
      basis: basis,
      details: [
        metric(
          'class_a_count',
          'تعداد اقلام A طبق سیاست مرز انتخابی',
          counts['A']!.toDouble(),
        ),
        metric('class_b_count', 'تعداد اقلام B', counts['B']!.toDouble()),
        metric('class_c_count', 'تعداد اقلام C', counts['C']!.toDouble()),
        ...details,
      ],
    );
  }

  List<CalculationIssue> _validate(AbcParameters p) {
    final issues = toolValidate([
      ToolNumber(
        'a_threshold',
        'مرز تجمعی A',
        p.aThreshold,
        min: 0,
        max: 1,
        strictMin: true,
        strictMax: true,
      ),
      ToolNumber(
        'b_threshold',
        'مرز تجمعی B',
        p.bThreshold,
        min: 0,
        max: 1,
        strictMin: true,
      ),
    ]);
    if (p.bThreshold <= p.aThreshold) {
      issues.add(
        CalculationIssue(
          code: 'invalid_thresholds',
          fieldId: 'b_threshold',
          message: 'مرز B باید از A بزرگ‌تر و حداکثر صد درصد باشد.',
        ),
      );
    }
    if (p.annualQuantities.isEmpty ||
        p.annualQuantities.length > 100 ||
        p.annualQuantities.length != p.unitCosts.length) {
      issues.add(
        CalculationIssue(
          code: 'mismatched_items',
          fieldId: 'unit_costs',
          message: 'دو فهرست باید هم‌اندازه و شامل ۱ تا ۱۰۰ قلم هم‌ردیف باشند.',
        ),
      );
    }
    for (final (id, list) in [
      ('annual_quantities', p.annualQuantities),
      ('unit_costs', p.unitCosts),
    ]) {
      for (var i = 0; i < list.length; i++) {
        if (!list[i].isFinite || list[i] < 0) {
          issues.add(
            CalculationIssue(
              code: 'invalid_item',
              fieldId: id,
              itemIndex: i,
              message: 'مقدار مصرف و بهای واحد باید متناهی و نامنفی باشند.',
            ),
          );
        }
      }
    }
    return issues;
  }
}
