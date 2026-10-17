import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/decision/decision_table.dart';
import 'package:management_toolbox/features/calculators/domain/decision/decision_tree.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/ahp_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/cost_benefit_comparison_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/decision_matrix_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/expected_value_tree_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/topsis_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/two_option_break_even_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/weight_sensitivity_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/weighted_scoring_engine.dart';

double number(Map<String, Object?> v, String id) {
  final x = v[id]!;
  return x is num ? x.toDouble() : double.parse(x as String);
}

List<double> numbers(Map<String, Object?> v, String id) =>
    (v[id] as List<Object?>)
        .map((x) => x is num ? x.toDouble() : double.parse(x as String))
        .toList();
DecisionTable table(Map<String, Object?> v, {bool directions = true}) =>
    DecisionTable(
      alternatives: number(v, 'alternatives'),
      criteria: number(v, 'criteria'),
      values: numbers(v, 'matrix'),
      weights: numbers(v, 'weights'),
      directions: directions ? numbers(v, 'directions') : [],
    );
DecisionTreeData tree(Map<String, Object?> v) {
  final ids = numbers(v, 'node_ids'),
      types = numbers(v, 'node_types'),
      payoff = numbers(v, 'payoffs'),
      from = numbers(v, 'from_ids'),
      to = numbers(v, 'to_ids'),
      prob = numbers(v, 'probabilities');
  return DecisionTreeData(
    rootId: number(v, 'root_id'),
    nodes: [
      for (var i = 0; i < ids.length; i++)
        DecisionTreeNode(
          id: ids[i].toInt(),
          kind: DecisionNodeKind.values[types[i].toInt()],
          payoff: payoff[i],
        ),
    ],
    edges: [
      for (var i = 0; i < from.length; i++)
        DecisionTreeEdge(
          from: from[i].toInt(),
          to: to[i].toInt(),
          probability: prob[i],
        ),
    ],
  );
}

CalculationOutcome typed(String id, Map<String, Object?> v) => switch (id) {
  'ahp' => const AhpEngine().calculate(
    AhpParameters(
      alternatives: number(v, 'alternatives'),
      criteria: number(v, 'criteria'),
      criteriaMatrix: numbers(v, 'criteria_matrix'),
      localMatrices: numbers(v, 'local_matrices'),
    ),
  ),
  'topsis' => const TopsisEngine().calculate(TopsisParameters(table: table(v))),
  'decision_matrix' => const DecisionMatrixEngine().calculate(
    DecisionMatrixParameters(table: table(v)),
  ),
  'expected_value_tree' => const ExpectedValueTreeEngine().calculate(
    ExpectedValueTreeParameters(tree(v)),
  ),
  'weight_sensitivity' => const WeightSensitivityEngine().calculate(
    WeightSensitivityParameters(
      table: table(v),
      selectedCriterion: number(v, 'selected_criterion'),
      sweepWeights: numbers(v, 'sweep_weights'),
    ),
  ),
  'weighted_scoring' => const WeightedScoringEngine().calculate(
    WeightedScoringParameters(table: table(v, directions: false)),
  ),
  'cost_benefit_comparison' => const CostBenefitComparisonEngine().calculate(
    CostBenefitComparisonParameters(
      costA: number(v, 'cost_a'),
      benefitA: number(v, 'benefit_a'),
      costB: number(v, 'cost_b'),
      benefitB: number(v, 'benefit_b'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  'two_option_break_even' => const TwoOptionBreakEvenEngine().calculate(
    TwoOptionBreakEvenParameters(
      fixedA: number(v, 'fixed_a'),
      variableA: number(v, 'variable_a'),
      fixedB: number(v, 'fixed_b'),
      variableB: number(v, 'variable_b'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  _ => throw ArgumentError(id),
};
final defaults = <String, Map<String, Object?>>{
  'ahp': {
    'alternatives': 3,
    'criteria': 2,
    'criteria_matrix': [1, 2, 0.5, 1],
    'local_matrices': [
      1,
      1.6666666666666667,
      2.5,
      0.6,
      1,
      1.5,
      0.4,
      0.6666666666666666,
      1,
      1,
      0.6666666666666666,
      0.4,
      1.5,
      1,
      0.6,
      2.5,
      1.6666666666666667,
      1,
    ],
  },
  'topsis': {
    'alternatives': 3,
    'criteria': 2,
    'matrix': [3, 1, 2, 2, 1, 3],
    'weights': [0.6, 0.4],
    'directions': [1, 1],
  },
  'decision_matrix': {
    'alternatives': 3,
    'criteria': 2,
    'matrix': [3, 1, 2, 2, 1, 3],
    'weights': [0.6, 0.4],
    'directions': [1, 1],
  },
  'expected_value_tree': {
    'root_id': 1,
    'node_ids': [1, 2, 3, 4, 5, 6, 7],
    'node_types': [2, 1, 1, 0, 0, 0, 0],
    'payoffs': [0, 0, 0, 100, -20, 80, 10],
    'from_ids': [1, 1, 2, 2, 3, 3],
    'to_ids': [2, 3, 4, 5, 6, 7],
    'probabilities': [1, 1, 0.6, 0.4, 0.5, 0.5],
  },
  'weight_sensitivity': {
    'alternatives': 3,
    'criteria': 2,
    'matrix': [3, 1, 2, 2, 1, 3],
    'weights': [0.6, 0.4],
    'directions': [1, 1],
    'selected_criterion': 1,
    'sweep_weights': [0, 0.5, 1],
  },
  'weighted_scoring': {
    'alternatives': 3,
    'criteria': 2,
    'matrix': [8, 6, 7, 9, 9, 5],
    'weights': [0.6, 0.4],
  },
  'cost_benefit_comparison': {
    'cost_a': 100,
    'benefit_a': 160,
    'cost_b': 120,
    'benefit_b': 210,
    'period_days': 365,
  },
  'two_option_break_even': {
    'fixed_a': 100,
    'variable_a': 5,
    'fixed_b': 200,
    'variable_b': 3,
    'period_days': 365,
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
List<double> series(CalculationOutcome o, String id) =>
    (detail(o, id) as NumberListResultValue).values;
CalculationOutcome run(
  String id, [
  Map<String, Object?> overrides = const {},
]) => typed(id, {...defaults[id]!, ...overrides});
void fails(String id, Map<String, Object?> values, [String? code]) {
  final o = run(id, values);
  if (o is! CalculationFailure) {
    throw StateError('Expected failure: $id $values');
  }
  if (code != null && !o.issues.any((i) => i.code == code)) {
    throw StateError('Expected $code: ${o.issues.map((i) => i.code)}');
  }
}
