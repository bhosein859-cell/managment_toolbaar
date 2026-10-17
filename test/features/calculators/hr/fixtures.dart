import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/hr/absence_cost_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/hr/cost_per_hire_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/hr/employee_productivity_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/hr/employee_turnover_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/hr/replacement_time_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/hr/training_roi_engine.dart';

double number(Map<String, Object?> v, String id) {
  final x = v[id]!;
  return x is num ? x.toDouble() : double.parse(x as String);
}

List<double> numbers(Map<String, Object?> v, String id) =>
    (v[id] as List<Object?>)
        .map((x) => x is num ? x.toDouble() : double.parse(x as String))
        .toList();
CalculationOutcome typed(String id, Map<String, Object?> v) => switch (id) {
  'cost_per_hire' => const CostPerHireEngine().calculate(
    CostPerHireParameters(
      internalCost: number(v, 'internal_cost'),
      externalCost: number(v, 'external_cost'),
      hires: number(v, 'hires'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  'employee_turnover' => const EmployeeTurnoverEngine().calculate(
    EmployeeTurnoverParameters(
      separations: number(v, 'separations'),
      openingHeadcount: number(v, 'opening_headcount'),
      closingHeadcount: number(v, 'closing_headcount'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  'employee_productivity' => const EmployeeProductivityEngine().calculate(
    EmployeeProductivityParameters(
      output: number(v, 'output'),
      workedHours: number(v, 'worked_hours'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  'training_roi' => const TrainingRoiEngine().calculate(
    TrainingRoiParameters(
      grossBenefits: number(v, 'gross_benefits'),
      attributionRate: number(v, 'attribution_rate'),
      trainingCost: number(v, 'training_cost'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  'replacement_time' => const ReplacementTimeEngine().calculate(
    ReplacementTimeParameters(
      elapsedDays: numbers(v, 'elapsed_days'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  'absence_cost' => const AbsenceCostEngine().calculate(
    AbsenceCostParameters(
      paidAbsentHours: number(v, 'paid_absent_hours'),
      loadedHourlyCost: number(v, 'loaded_hourly_cost'),
      incrementalCoverCost: number(v, 'incremental_cover_cost'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  _ => throw ArgumentError(id),
};
final defaults = <String, Map<String, Object?>>{
  'cost_per_hire': {
    'internal_cost': 20000000,
    'external_cost': 10000000,
    'hires': 3,
    'period_days': 90,
  },
  'employee_turnover': {
    'separations': 5,
    'opening_headcount': 90,
    'closing_headcount': 110,
    'period_days': 90,
  },
  'employee_productivity': {
    'output': 4000,
    'worked_hours': 800,
    'period_days': 90,
  },
  'training_roi': {
    'gross_benefits': 40000000,
    'attribution_rate': 0.5,
    'training_cost': 10000000,
    'period_days': 90,
  },
  'replacement_time': {
    'elapsed_days': [20, 30, 40],
    'period_days': 90,
  },
  'absence_cost': {
    'paid_absent_hours': 40,
    'loaded_hourly_cost': 500000,
    'incremental_cover_cost': 2000000,
    'period_days': 90,
  },
};
CalculationResult success(CalculationOutcome o) =>
    (o as CalculationSuccess).result;
double primary(CalculationOutcome o) =>
    (success(o).primary.value as NumericResultValue).value;
ResultValue detail(CalculationOutcome o, String id) =>
    success(o).details.singleWhere((m) => m.id == id).value;
double metricValue(CalculationOutcome o, String id) =>
    (detail(o, id) as NumericResultValue).value;
CalculationOutcome run(
  String id, [
  Map<String, Object?> overrides = const {},
]) => typed(id, {...defaults[id]!, ...overrides});
