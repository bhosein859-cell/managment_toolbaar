import '../../calculator_domain.dart';
import '../../statistics/tool_numeric.dart';

final class DpmoParameters implements CalculatorParameters {
  const DpmoParameters({
    required this.defects,
    required this.units,
    required this.opportunities,
  });
  final double defects;
  final double units;
  final double opportunities;
}

final class DpmoEngine implements CalculatorEngine<DpmoParameters> {
  const DpmoEngine();
  static const name = 'نقص در میلیون فرصت — DPMO';
  static const basis =
      'نقص با واحد معیوب یکی نیست؛ یک واحد می‌تواند در فرصت‌های مختلف چند نقص داشته باشد. هر فرصت در این مدل دودویی و فرصت‌ها در همهٔ واحدها ثابت و بدون هم‌پوشانی‌اند؛ تعداد نقص از کل فرصت‌ها بیشتر نمی‌شود. مقدار مشاهده‌شده برآورد احتمال جمعیت یا اثبات استقلال/کیفیت نیست و عدم مشاهدهٔ نقص تضمین نرخ صفر واقعی نیست.';
  @override
  String get calculatorId => 'dpmo';
  @override
  InputBinding<DpmoParameters> bind(CalculatorInput input) {
    final p = DpmoParameters(
      defects: input.requireNumber('defects'),
      units: input.requireNumber('units'),
      opportunities: input.requireNumber('opportunities'),
    );
    final issues = _validate(p);
    return issues.isEmpty ? BoundInput(p) : RejectedInput(issues);
  }

  @override
  CalculationOutcome calculate(DpmoParameters p) {
    final issues = _validate(p);
    if (issues.isNotEmpty) return CalculationFailure(issues);
    final total = p.units * p.opportunities;
    final dpo = p.defects / total;
    final value = dpo * 1000000;
    return toolResult(
      id: calculatorId,
      label: name,
      value: value,
      unit: 'نقص/میلیون فرصت',
      nonzero: p.defects > 0,
      basis: basis,
      details: [
        metric('dpo', 'نقص بر فرصت', dpo),
        metric('total_opportunities', 'کل فرصت بررسی‌شده', total),
      ],
    );
  }

  List<CalculationIssue> _validate(DpmoParameters p) {
    final issues = toolValidate([
      ToolNumber(
        'defects',
        'تعداد نقص‌های ثبت‌شده',
        p.defects,
        min: 0,
        integer: true,
      ),
      ToolNumber(
        'units',
        'تعداد واحد بررسی‌شده',
        p.units,
        min: 0,
        strictMin: true,
        integer: true,
      ),
      ToolNumber(
        'opportunities',
        'فرصت نقص در هر واحد',
        p.opportunities,
        min: 0,
        strictMin: true,
        integer: true,
      ),
    ]);
    if (issues.isNotEmpty) return issues;
    final total = p.units * p.opportunities;
    if (total > 9007199254740991) {
      issues.add(
        CalculationIssue(
          code: 'opportunity_range',
          fieldId: 'opportunities',
          message: 'کل فرصت‌ها باید حداکثر ۲^۵۳−۱ و قابل شمارش دقیق باشد.',
        ),
      );
    } else if (p.defects > total) {
      issues.add(
        CalculationIssue(
          code: 'too_many_defects',
          fieldId: 'defects',
          message: 'در مدل فرصت دودویی، نقص از کل فرصت‌ها بیشتر نمی‌شود.',
        ),
      );
    }
    return issues;
  }
}
