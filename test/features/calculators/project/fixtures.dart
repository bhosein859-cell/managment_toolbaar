import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/cpm_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/duration_comparison_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/eac_etc_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/evm_performance_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/pert_duration_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/project_float_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/sv_cv_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/three_point_engine.dart';
import 'package:management_toolbox/features/calculators/domain/project/project_network.dart';

double number(Map<String, Object?> v, String id) {
  final x = v[id]!;
  return x is num ? x.toDouble() : double.parse(x as String);
}

List<double> numbers(Map<String, Object?> v, String id) =>
    (v[id] as List<Object?>)
        .map((x) => x is num ? x.toDouble() : double.parse(x as String))
        .toList();
List<ProjectActivity> network(Map<String, Object?> v) {
  final ids = numbers(v, 'activity_ids').map((x) => x.toInt()).toList(),
      d = numbers(v, 'durations'),
      from = numbers(v, 'predecessor_ids'),
      to = numbers(v, 'successor_ids');
  return [
    for (var i = 0; i < ids.length; i++)
      ProjectActivity(
        id: ids[i],
        duration: d[i],
        predecessors: [
          for (var j = 0; j < from.length; j++)
            if (to[j] == ids[i]) from[j].toInt(),
        ],
      ),
  ];
}

CalculationOutcome typed(String id, Map<String, Object?> v) => switch (id) {
  'pert_duration' => const PertDurationEngine().calculate(
    PertDurationParameters(
      optimistic: number(v, 'optimistic'),
      mostLikely: number(v, 'most_likely'),
      pessimistic: number(v, 'pessimistic'),
    ),
  ),
  'cpm' => const CpmEngine().calculate(CpmParameters(network(v))),
  'project_float' => const ProjectFloatEngine().calculate(
    ProjectFloatParameters(network(v)),
  ),
  'evm_performance' => const EvmPerformanceEngine().calculate(
    EvmPerformanceParameters(
      pv: number(v, 'pv'),
      ev: number(v, 'ev'),
      ac: number(v, 'ac'),
    ),
  ),
  'three_point' => const ThreePointEngine().calculate(
    ThreePointParameters(
      optimistic: number(v, 'optimistic'),
      mostLikely: number(v, 'most_likely'),
      pessimistic: number(v, 'pessimistic'),
      method: v['method'] as String,
    ),
  ),
  'eac_etc' => const EacEtcEngine().calculate(
    EacEtcParameters(
      bac: number(v, 'bac'),
      pv: number(v, 'pv'),
      ev: number(v, 'ev'),
      ac: number(v, 'ac'),
      newEtc: number(v, 'new_etc'),
      method: v['method'] as String,
    ),
  ),
  'sv_cv' => const SvCvEngine().calculate(
    SvCvParameters(
      pv: number(v, 'pv'),
      ev: number(v, 'ev'),
      ac: number(v, 'ac'),
    ),
  ),
  'duration_comparison' => const DurationComparisonEngine().calculate(
    DurationComparisonParameters(
      planned: number(v, 'planned_duration'),
      actual: number(v, 'actual_duration'),
    ),
  ),
  _ => throw ArgumentError(id),
};
final defaults = <String, Map<String, Object?>>{
  'pert_duration': {'optimistic': 2, 'most_likely': 4, 'pessimistic': 8},
  'cpm': {
    'activity_ids': [1, 2, 3, 4],
    'durations': [3, 2, 4, 1],
    'predecessor_ids': [1, 1, 2, 3],
    'successor_ids': [2, 3, 4, 4],
  },
  'project_float': {
    'activity_ids': [1, 2, 3, 4],
    'durations': [3, 2, 4, 1],
    'predecessor_ids': [1, 1, 2, 3],
    'successor_ids': [2, 3, 4, 4],
  },
  'evm_performance': {'pv': 100, 'ev': 80, 'ac': 100},
  'three_point': {
    'optimistic': 2,
    'most_likely': 4,
    'pessimistic': 8,
    'method': 'triangular',
  },
  'eac_etc': {
    'bac': 1000,
    'pv': 100,
    'ev': 80,
    'ac': 100,
    'new_etc': 250,
    'method': 'cpi',
  },
  'sv_cv': {'pv': 100, 'ev': 80, 'ac': 100},
  'duration_comparison': {'planned_duration': 10, 'actual_duration': 12},
};
CalculationResult success(CalculationOutcome o) =>
    (o as CalculationSuccess).result;
double primary(CalculationOutcome o) =>
    (success(o).primary.value as NumericResultValue).value;
ResultValue detail(CalculationOutcome o, String id) =>
    success(o).details.singleWhere((m) => m.id == id).value;
double metricValue(CalculationOutcome o, String id) =>
    (detail(o, id) as NumericResultValue).value;
List<double> series(CalculationOutcome o, String id) =>
    (detail(o, id) as NumberListResultValue).values;
CalculationOutcome run(
  String id, [
  Map<String, Object?> overrides = const {},
]) => typed(id, {...defaults[id]!, ...overrides});
