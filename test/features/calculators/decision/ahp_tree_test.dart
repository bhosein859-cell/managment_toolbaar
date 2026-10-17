import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/decision_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/decision/ahp_solver.dart';
import 'package:management_toolbox/features/calculators/domain/decision/decision_tree.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/ahp_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/expected_value_tree_engine.dart';

import 'fixtures.dart';

DecisionTreeNode leaf(int id, double value) =>
    DecisionTreeNode(id: id, kind: DecisionNodeKind.terminal, payoff: value);
DecisionTreeNode choice(int id) =>
    DecisionTreeNode(id: id, kind: DecisionNodeKind.decision, payoff: 0);
DecisionTreeNode chance(int id) =>
    DecisionTreeNode(id: id, kind: DecisionNodeKind.chance, payoff: 0);
DecisionTreeEdge edge(int from, int to, [double p = 1]) =>
    DecisionTreeEdge(from: from, to: to, probability: p);
CalculationOutcome evaluate(
  List<DecisionTreeNode> nodes,
  List<DecisionTreeEdge> edges, {
  double root = 1,
}) => const ExpectedValueTreeEngine().calculate(
  ExpectedValueTreeParameters(
    DecisionTreeData(rootId: root, nodes: nodes, edges: edges),
  ),
);
void treeFails(
  List<DecisionTreeNode> nodes,
  List<DecisionTreeEdge> edges,
  String code, {
  double root = 1,
}) {
  final o = evaluate(nodes, edges, root: root);
  expect(o, isA<CalculationFailure>());
  expect((o as CalculationFailure).issues.any((i) => i.code == code), isTrue);
}

void main() {
  test('AHP known consistent hierarchy, global priorities and near ties', () {
    final o = run('ahp');
    for (var i = 0; i < 3; i++) {
      expect(series(o, 'scores')[i], closeTo([0.4, 0.3, 0.3][i], 1e-12));
    }
    expect(series(o, 'ranks'), [1, 2, 2]);
    expect(series(o, 'criteria_weights')[0], closeTo(2 / 3, 1e-12));
    for (final cr in series(o, 'consistency_ratio')) {
      expect(cr, closeTo(0, 1e-12));
    }
  });
  test('AHP classic reciprocal three-criterion hand-checkable geometric eigenvector', () {
    final o = run('ahp', {
      'criteria': 3,
      'alternatives': 2,
      'criteria_matrix': [1, 1 / 3, 3, 3, 1, 5, 1 / 3, 0.2, 1],
      'local_matrices': List.filled(12, 1.0),
    });
    final w = series(o, 'criteria_weights');
    expect(w[0], closeTo(0.2582849944, 1e-9));
    expect(w[1], closeTo(0.6369855717, 1e-9));
    expect(w[2], closeTo(0.1047294339, 1e-9));
    expect(series(o, 'consistency_ratio').first, closeTo(0.033199215, 1e-8));
  });
  test('AHP inconsistent circulant has known lambda and CR, warning not fabricated refusal', () {
    final o = run('ahp', {
      'criteria': 3,
      'alternatives': 2,
      'criteria_matrix': [1, 9, 1 / 9, 1 / 9, 1, 9, 9, 1 / 9, 1],
      'local_matrices': List.filled(12, 1.0),
    });
    expect(series(o, 'lambda_max').first, closeTo(1 + 9 + 1 / 9, 1e-12));
    expect(
      series(o, 'consistency_ratio').first,
      closeTo(((1 + 9 + 1 / 9) - 3) / 2 / 0.58, 1e-12),
    );
    expect(
      success(o).warnings.any((w) => w.code == 'ahp_consistency_review'),
      isTrue,
    );
  });
  test('AHP rejects reciprocal, diagonal, ranges and incomplete matrices', () {
    fails('ahp', {
      'criteria_matrix': [1, 2, 1, 1],
    }, 'non_reciprocal');
    fails('ahp', {
      'criteria_matrix': [1.01, 2, 0.5, 1],
    }, 'invalid_diagonal');
    for (final x in [0.0, -1.0, 10.0, double.nan, double.infinity]) {
      fails('ahp', {
        'criteria_matrix': [1, x, 0.5, 1],
      }, 'invalid_pairwise');
    }
    fails('ahp', {
      'criteria_matrix': [1, 1, 1],
    }, 'pairwise_shape');
    fails('ahp', {
      'local_matrices': [1],
    }, 'local_shape');
    final local = numbers(defaults['ahp']!, 'local_matrices');
    local[0] = 0;
    fails('ahp', {'local_matrices': local}, 'invalid_pairwise');
    for (final n in [1, 11, 2.5]) {
      fails('ahp', {'alternatives': n});
      fails('ahp', {'criteria': n});
    }
  });
  test('AHP convergence cap never returns guessed weights', () {
    final p = AhpParameters(
      alternatives: 3,
      criteria: 2,
      criteriaMatrix: numbers(defaults['ahp']!, 'criteria_matrix'),
      localMatrices: numbers(defaults['ahp']!, 'local_matrices'),
    );
    for (final (cap, code) in [
      (0, 'invalid_solver'),
      (1, 'ahp_no_convergence'),
    ]) {
      final o =
          AhpEngine(maxIterations: cap).calculate(p) as CalculationFailure;
      expect(o.issues.any((i) => i.code == code), isTrue);
    }
  });
  test(
    'AHP supports largest documented dimensions, RI and immutable matrices',
    () {
      final o = run('ahp', {
        'alternatives': 10,
        'criteria': 10,
        'criteria_matrix': List.filled(100, 1.0),
        'local_matrices': List.filled(1000, 1.0),
      });
      expect(series(o, 'scores'), hasLength(10));
      expect(primary(o), closeTo(0.1, 1e-12));
      expect(ahpRandomIndex[10], 1.49);
      final cm = [1.0, 1.0, 1.0, 1.0];
      final p = AhpParameters(
        alternatives: 2,
        criteria: 2,
        criteriaMatrix: cm,
        localMatrices: List.filled(8, 1),
      );
      cm.clear();
      expect(p.criteriaMatrix, hasLength(4));
      expect(() => p.localMatrices.clear(), throwsUnsupportedError);
    },
  );
  test('Decision tree golden example and all negative/tied choices', () {
    final o = run('expected_value_tree');
    expect(primary(o), 52);
    expect(series(o, 'preferred_children'), [2]);
    final n = evaluate(
      [choice(1), leaf(2, -20), leaf(3, -10)],
      [edge(1, 2), edge(1, 3)],
    );
    expect(primary(n), -10);
    expect(series(n, 'preferred_children'), [3]);
    final tie = evaluate(
      [choice(1), leaf(2, 5), leaf(3, 5)],
      [edge(1, 2), edge(1, 3)],
    );
    expect(series(tie, 'preferred_children'), [2, 3]);
  });
  test('Nested decisions and chance perform backward induction, not only root branching', () {
    final o = evaluate(
      [chance(1), choice(2), leaf(3, 10), leaf(4, 100), leaf(5, -20)],
      [edge(1, 2, 0.5), edge(1, 3, 0.5), edge(2, 4), edge(2, 5)],
    );
    expect(primary(o), closeTo(55, 1e-12));
    expect(series(o, 'preferred_children'), [4]);
  });
  test('Tree may contain only a terminal and explicit omitted optional edges stay absent', () {
    final r = DecisionCalculators.expectedValueTreeRunner;
    final o = r.run(
      RawCalculatorInput({
        'root_id': const RawTextInput('7'),
        'node_ids': RawNumberListInput(['7']),
        'node_types': RawNumberListInput(['0']),
        'payoffs': RawNumberListInput(['-5']),
      }),
    );
    expect(primary(o), -5);
    expect(detail(o, 'no_decision_nodes'), isA<TextResultValue>());
  });
  test('Probability zero still validates data, tiny nonzero sums are normalized only within tolerance', () {
    final o = evaluate(
      [chance(1), leaf(2, 1e308), leaf(3, 1e-300)],
      [edge(1, 2, 0), edge(1, 3, 1)],
    );
    expect(primary(o), 1e-300);
    final near = evaluate(
      [chance(1), leaf(2, 0), leaf(3, 100)],
      [edge(1, 2, 0.4), edge(1, 3, 0.6000000001)],
    );
    expect(primary(near), closeTo(100 * 0.6000000001 / 1.0000000001, 1e-9));
    treeFails(
      [chance(1), leaf(2, double.nan), leaf(3, 10)],
      [edge(1, 2, 0), edge(1, 3, 1)],
      'invalid_payoff',
    );
  });
  test('Tree rejects bad probabilities, incomplete sums and fake decision probabilities', () {
    for (final p in [-0.1, 1.1, double.nan, double.infinity]) {
      treeFails(
        [chance(1), leaf(2, 1)],
        [edge(1, 2, p)],
        'invalid_probability',
      );
    }
    treeFails(
      [chance(1), leaf(2, 1), leaf(3, 2)],
      [edge(1, 2, 0.2), edge(1, 3, 0.3)],
      'probability_sum',
    );
    treeFails(
      [choice(1), leaf(2, 1)],
      [edge(1, 2, 0.5)],
      'decision_edge_factor',
    );
  });
  test(
    'Tree rejects IDs, unknown root/refs, duplicate/self edges and DAG sharing',
    () {
      treeFails([leaf(1, 1), leaf(1, 2)], [], 'invalid_or_duplicate_node');
      treeFails([leaf(0, 1)], [], 'invalid_or_duplicate_node');
      treeFails([leaf(1, 1)], [], 'unknown_root', root: 2);
      treeFails([choice(1), leaf(2, 1)], [edge(1, 99)], 'unknown_reference');
      treeFails(
        [choice(1), leaf(2, 1)],
        [edge(1, 1)],
        'self_or_duplicate_edge',
      );
      treeFails(
        [choice(1), leaf(2, 1)],
        [edge(1, 2), edge(1, 2)],
        'self_or_duplicate_edge',
      );
      treeFails(
        [choice(1), chance(2), chance(3), leaf(4, 1)],
        [edge(1, 2), edge(1, 3), edge(2, 4), edge(3, 4)],
        'not_rooted_tree',
      );
    },
  );
  test(
    'Disconnected zero cycles reject without recursion or infinite traversal',
    () {
      treeFails(
        [leaf(1, 0), chance(2), chance(3)],
        [edge(2, 3), edge(3, 2)],
        'cycle_or_disconnected',
      );
    },
  );
  test('Tree node kind/payoff and degree contracts are checked', () {
    treeFails([choice(1)], [], 'invalid_node_degree');
    treeFails([leaf(1, 0), leaf(2, 1)], [edge(1, 2)], 'invalid_node_degree');
    treeFails(
      [
        const DecisionTreeNode(
          id: 1,
          kind: DecisionNodeKind.decision,
          payoff: 2,
        ),
        leaf(2, 0),
      ],
      [edge(1, 2)],
      'invalid_payoff',
    );
    treeFails([], [], 'node_count');
    treeFails([for (var i = 1; i <= 101; i++) leaf(i, 0)], [], 'node_count');
    treeFails(
      [choice(1), leaf(2, 0)],
      List.filled(100, edge(1, 2)),
      'edge_count',
    );
  });
  test('Tree handles 100-deep valid chain and immutable snapshots', () {
    final nodes = [for (var i = 1; i < 100; i++) choice(i), leaf(100, 7)],
        edges = [for (var i = 1; i < 100; i++) edge(i, i + 1)];
    final t = DecisionTreeData(rootId: 1, nodes: nodes, edges: edges);
    nodes.clear();
    edges.clear();
    expect(
      primary(
        const ExpectedValueTreeEngine().calculate(
          ExpectedValueTreeParameters(t),
        ),
      ),
      7,
    );
    expect(() => t.nodes.clear(), throwsUnsupportedError);
    expect(() => t.edges.clear(), throwsUnsupportedError);
  });
  test('Tree raw shapes, fractional IDs/types and missing edge probability reject explicitly', () {
    final r = DecisionCalculators.expectedValueTreeRunner,
        raw = r.definition.examples.single.inputs;
    for (final (id, list) in [
      ('node_ids', ['1.5', '2', '3', '4', '5', '6', '7']),
      ('node_types', ['1.5', '1', '1', '0', '0', '0', '0']),
      ('node_types', ['0', '1', '1', '0', '0', '0', '0']),
      ('payoffs', ['0']),
      ('from_ids', ['1']),
    ]) {
      final o = r.run(
        RawCalculatorInput({...raw.values, id: RawNumberListInput(list)}),
      );
      expect(o, isA<CalculationFailure>());
      expect(
        (o as CalculationFailure).issues.any(
          (i) => i.code == 'calculation_failed',
        ),
        isFalse,
      );
    }
    final missing = {...raw.values}..remove('probabilities');
    final o = r.run(RawCalculatorInput(missing)) as CalculationFailure;
    expect(o.issues.any((i) => i.code == 'edge_shape'), isTrue);
  });
}
