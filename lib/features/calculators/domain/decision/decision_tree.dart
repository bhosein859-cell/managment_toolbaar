import 'dart:collection';
import 'dart:math' as math;

import '../calculator_domain.dart';
import '../statistics/tool_numeric.dart';
import 'decision_math.dart';

enum DecisionNodeKind { terminal, chance, decision }

final class DecisionTreeNode {
  const DecisionTreeNode({
    required this.id,
    required this.kind,
    required this.payoff,
  });
  final int id;
  final DecisionNodeKind kind;
  final double payoff;
}

final class DecisionTreeEdge {
  const DecisionTreeEdge({
    required this.from,
    required this.to,
    required this.probability,
  });
  final int from, to;
  final double probability;
}

final class DecisionTreeData {
  DecisionTreeData({
    required this.rootId,
    required Iterable<DecisionTreeNode> nodes,
    required Iterable<DecisionTreeEdge> edges,
  }) : nodes = List.unmodifiable(nodes),
       edges = List.unmodifiable(edges);
  final double rootId;
  final List<DecisionTreeNode> nodes;
  final List<DecisionTreeEdge> edges;
}

sealed class TreeBinding {
  const TreeBinding();
}

final class BoundTree extends TreeBinding {
  const BoundTree(this.tree);
  final DecisionTreeData tree;
}

final class RejectedTree extends TreeBinding {
  const RejectedTree(this.issues);
  final List<CalculationIssue> issues;
}

TreeBinding bindTree(CalculatorInput input) {
  List<double> list(String id) => switch (input.values[id]) {
    NumberListInputValue(:final values) => values,
    null => <double>[],
    _ => throw StateError('نوع فهرست شبکه معتبر نیست'),
  };
  final ids = list('node_ids'),
      types = list('node_types'),
      payoffs = list('payoffs'),
      from = list('from_ids'),
      to = list('to_ids'),
      prob = list('probabilities');
  if (ids.isEmpty ||
      ids.length > 100 ||
      ids.length != types.length ||
      ids.length != payoffs.length) {
    return RejectedTree([
      decisionIssue(
        'node_shape',
        'سه ستون شناسه/نوع/عایدی باید هم‌اندازه و شامل ۱ تا ۱۰۰ گره باشند.',
        'node_ids',
      ),
    ]);
  }
  if (from.length != to.length ||
      from.length != prob.length ||
      from.length > 99) {
    return RejectedTree([
      decisionIssue(
        'edge_shape',
        'ستون‌های سر/ته/ضریب یال باید هم‌اندازه و حداکثر ۹۹ یال باشند.',
        'from_ids',
      ),
    ]);
  }
  for (final (field, values) in [
    ('node_ids', ids),
    ('from_ids', from),
    ('to_ids', to),
  ]) {
    if (values.any((v) => !v.isFinite || v % 1 != 0 || v < 1 || v > 999999)) {
      return RejectedTree([
        decisionIssue(
          'invalid_node_id',
          'شناسهٔ گره عدد صحیح از ۱ تا ۹۹۹۹۹۹ است، نه شمارهٔ ردیف.',
          'node_ids' == field ? 'node_ids' : field,
        ),
      ]);
    }
  }
  if (types.any((v) => v != 0 && v != 1 && v != 2)) {
    return RejectedTree([
      decisionIssue(
        'invalid_node_type',
        'نوع گره فقط صفر پایانی، یک احتمالی یا دو تصمیم است.',
        'node_types',
      ),
    ]);
  }
  return BoundTree(
    DecisionTreeData(
      rootId: input.requireNumber('root_id'),
      nodes: [
        for (var i = 0; i < ids.length; i++)
          DecisionTreeNode(
            id: ids[i].toInt(),
            kind: DecisionNodeKind.values[types[i].toInt()],
            payoff: payoffs[i],
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
    ),
  );
}

List<CalculationIssue> validateTree(DecisionTreeData p) {
  final issues = toolValidate([
    ToolNumber(
      'root_id',
      'شناسهٔ ریشه',
      p.rootId,
      min: 1,
      max: 999999,
      integer: true,
    ),
  ]);
  if (issues.isNotEmpty) return issues;
  if (p.nodes.isEmpty || p.nodes.length > 100) {
    return [decisionIssue('node_count', '۱ تا ۱۰۰ گره لازم است.', 'node_ids')];
  }
  if (p.edges.length > 99) {
    return [
      decisionIssue(
        'edge_count',
        'حداکثر ۹۹ یال برای درخت پشتیبانی می‌شود.',
        'from_ids',
      ),
    ];
  }
  final byId = <int, DecisionTreeNode>{};
  for (final node in p.nodes) {
    if (node.id < 1 || node.id > 999999 || byId.containsKey(node.id)) {
      return [
        decisionIssue(
          'invalid_or_duplicate_node',
          'شناسه باید معتبر و یکتا باشد.',
          'node_ids',
        ),
      ];
    }
    if (!node.payoff.isFinite ||
        (node.kind != DecisionNodeKind.terminal && node.payoff != 0)) {
      return [
        decisionIssue(
          'invalid_payoff',
          'عایدی باید متناهی باشد؛ برای گره غیرپایانی ستون عایدی را صفر بگذارید.',
          'payoffs',
        ),
      ];
    }
    byId[node.id] = node;
  }
  final root = p.rootId.toInt();
  if (!byId.containsKey(root)) {
    return [
      decisionIssue(
        'unknown_root',
        'ریشه باید شناسهٔ یک گرهٔ موجود باشد.',
        'root_id',
      ),
    ];
  }
  final incoming = {for (final n in p.nodes) n.id: 0},
      out = {for (final n in p.nodes) n.id: <DecisionTreeEdge>[]};
  final seen = <(int, int)>{};
  for (final e in p.edges) {
    if (!byId.containsKey(e.from) || !byId.containsKey(e.to)) {
      return [
        decisionIssue(
          'unknown_reference',
          'هر دو سر یال باید به شناسهٔ موجود ارجاع دهند.',
          'to_ids',
        ),
      ];
    }
    if (e.from == e.to || !seen.add((e.from, e.to))) {
      return [
        decisionIssue(
          'self_or_duplicate_edge',
          'خودارجاعی یا یال تکراری پذیرفته نیست.',
          'from_ids',
        ),
      ];
    }
    if (!e.probability.isFinite || e.probability < 0 || e.probability > 1) {
      return [
        decisionIssue(
          'invalid_probability',
          'احتمال باید متناهی و بین صفر و یک باشد.',
          'probabilities',
        ),
      ];
    }
    if (byId[e.from]!.kind == DecisionNodeKind.decision && e.probability != 1) {
      return [
        decisionIssue(
          'decision_edge_factor',
          'برای یال انتخابیِ گره تصمیم ضریب یک بنویسید؛ این احتمال تصادفی نیست.',
          'probabilities',
        ),
      ];
    }
    incoming[e.to] = incoming[e.to]! + 1;
    out[e.from]!.add(e);
  }
  if (incoming[root] != 0 ||
      p.nodes.any((n) => n.id != root && incoming[n.id] != 1)) {
    return [
      decisionIssue(
        'not_rooted_tree',
        'درخت یک ریشهٔ بدون والد و برای هر گرهٔ دیگر دقیقاً یک والد می‌خواهد؛ زیرشاخهٔ مشترک DAG یا گرهٔ جدا پشتیبانی نمی‌شود.',
        'from_ids',
      ),
    ];
  }
  for (final node in p.nodes) {
    final children = out[node.id]!;
    if ((node.kind == DecisionNodeKind.terminal && children.isNotEmpty) ||
        (node.kind != DecisionNodeKind.terminal && children.isEmpty)) {
      return [
        decisionIssue(
          'invalid_node_degree',
          'پایانه نباید فرزند داشته باشد و گرهٔ تصمیم/احتمال حداقل یک فرزند لازم دارد.',
          'node_types',
        ),
      ];
    }
    if (node.kind == DecisionNodeKind.chance &&
        (compensatedSum(children.map((e) => e.probability)) - 1).abs() > 1e-9) {
      return [
        decisionIssue(
          'probability_sum',
          'جمع احتمال فرزندان هر گرهٔ احتمالی باید در تلرانس ۱۰ به توان منفی ۹ برابر یک باشد.',
          'probabilities',
        ),
      ];
    }
  }
  final queue = Queue<int>()..add(root);
  var visited = 0;
  while (queue.isNotEmpty) {
    final id = queue.removeFirst();
    visited++;
    queue.addAll(out[id]!.map((e) => e.to));
  }
  if (visited != p.nodes.length) {
    return [
      decisionIssue(
        'cycle_or_disconnected',
        'چرخه یا مؤلفهٔ جدا از ریشه وجود دارد؛ درخت معتبر نیست.',
        'from_ids',
      ),
    ];
  }
  return [];
}

final class TreeEvaluation {
  const TreeEvaluation(
    this.rootValue,
    this.nodeValues,
    this.parents,
    this.choices,
  );
  final double rootValue;
  final List<double> nodeValues, parents, choices;
}

TreeEvaluation evaluateTree(DecisionTreeData p) {
  final out = {for (final n in p.nodes) n.id: <DecisionTreeEdge>[]},
      byId = {for (final n in p.nodes) n.id: n};
  for (final e in p.edges) {
    out[e.from]!.add(e);
  }
  final order = <int>[], q = Queue<int>()..add(p.rootId.toInt());
  while (q.isNotEmpty) {
    final id = q.removeFirst();
    order.add(id);
    q.addAll(out[id]!.map((e) => e.to));
  }
  final values = <int, double>{}, parents = <double>[], choices = <double>[];
  for (final id in order.reversed) {
    final node = byId[id]!, edges = out[id]!;
    if (node.kind == DecisionNodeKind.terminal) {
      values[id] = node.payoff;
    } else if (node.kind == DecisionNodeKind.chance) {
      values[id] = weightedValue([
        for (final e in edges) values[e.to]!,
      ], normalizedWeights(edges.map((e) => e.probability).toList()));
    } else {
      final best = edges.map((e) => values[e.to]!).reduce(math.max);
      values[id] = best;
      for (final e in edges) {
        if (nearScore(values[e.to]!, best)) {
          parents.add(id.toDouble());
          choices.add(e.to.toDouble());
        }
      }
    }
  }
  return TreeEvaluation(
    values[p.rootId.toInt()]!,
    [for (final n in p.nodes) values[n.id]!],
    parents,
    choices,
  );
}
