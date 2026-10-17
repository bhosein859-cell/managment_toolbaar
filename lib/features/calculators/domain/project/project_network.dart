import 'dart:collection';
import 'dart:math' as math;

import '../calculator_domain.dart';

/// Numeric business IDs, unrelated to row position. Finish-to-start, zero lag.
final class ProjectActivity {
  ProjectActivity({
    required this.id,
    required this.duration,
    Iterable<int> predecessors = const [],
  }) : predecessors = List.unmodifiable(predecessors);
  final int id;
  final double duration;
  final List<int> predecessors;
}

final class ActivitySchedule {
  const ActivitySchedule({
    required this.activity,
    required this.es,
    required this.ef,
    required this.ls,
    required this.lf,
    required this.totalFloat,
    required this.freeFloat,
    required this.critical,
  });
  final ProjectActivity activity;
  final double es, ef, ls, lf, totalFloat, freeFloat;
  final bool critical;
}

sealed class NetworkOutcome {
  const NetworkOutcome();
}

final class InvalidNetwork extends NetworkOutcome {
  InvalidNetwork(Iterable<CalculationIssue> issues)
    : issues = List.unmodifiable(issues);
  final List<CalculationIssue> issues;
}

final class ScheduledNetwork extends NetworkOutcome {
  ScheduledNetwork({
    required this.duration,
    required this.tolerance,
    required Iterable<ActivitySchedule> rows,
    required Iterable<int> criticalPath,
    required this.criticalPathCount,
  }) : rows = List.unmodifiable(rows),
       criticalPath = List.unmodifiable(criticalPath);
  final double duration, tolerance;
  final List<ActivitySchedule> rows;

  /// One connected source-to-sink path, not the union of critical nodes.
  final List<int> criticalPath;
  final BigInt criticalPathCount;
}

sealed class NetworkBinding {
  const NetworkBinding();
}

final class BoundNetwork extends NetworkBinding {
  BoundNetwork(Iterable<ProjectActivity> activities)
    : activities = List.unmodifiable(activities);
  final List<ProjectActivity> activities;
}

final class RejectedNetwork extends NetworkBinding {
  RejectedNetwork(Iterable<CalculationIssue> issues)
    : issues = List.unmodifiable(issues);
  final List<CalculationIssue> issues;
}

CalculationIssue networkIssue(
  String code,
  String message, {
  String? fieldId,
  int? index,
}) => CalculationIssue(
  code: code,
  message: message,
  fieldId: fieldId,
  itemIndex: index,
);
NetworkBinding bindNetwork(CalculatorInput input) {
  List<double>? list(String id, {bool optional = false}) =>
      switch (input.values[id]) {
        NumberListInputValue(:final values) => values,
        null when optional => <double>[],
        _ => null,
      };
  final ids = list('activity_ids'),
      durations = list('durations'),
      from = list('predecessor_ids', optional: true),
      to = list('successor_ids', optional: true);
  if (ids == null || durations == null || from == null || to == null) {
    return RejectedNetwork([
      networkIssue(
        'network_fields',
        'ورودی شبکه باید فهرست ساختاریافتهٔ عددی باشد.',
      ),
    ]);
  }
  if (ids.isEmpty || ids.length > 200 || ids.length != durations.length) {
    return RejectedNetwork([
      networkIssue(
        'activity_rows',
        'شناسه و مدت باید هم‌اندازه و شامل ۱ تا ۲۰۰ فعالیت باشند.',
        fieldId: 'durations',
      ),
    ]);
  }
  if (from.length != to.length || from.length > 2000) {
    return RejectedNetwork([
      networkIssue(
        'edge_rows',
        'دو فهرست وابستگی باید هم‌اندازه و حداکثر ۲۰۰۰ یال باشند.',
        fieldId: 'successor_ids',
      ),
    ]);
  }
  for (final (name, values) in [
    ('activity_ids', ids),
    ('predecessor_ids', from),
    ('successor_ids', to),
  ]) {
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (!v.isFinite || v < 1 || v > 999999 || v % 1 != 0) {
        return RejectedNetwork([
          networkIssue(
            'invalid_activity_id',
            'شناسه باید عدد صحیح بین ۱ تا ۹۹۹۹۹۹ باشد.',
            fieldId: name,
            index: i,
          ),
        ]);
      }
    }
  }
  final intIds = ids.map((v) => v.toInt()).toList();
  if (intIds.toSet().length != intIds.length) {
    return RejectedNetwork([
      networkIssue(
        'duplicate_activity',
        'شناسهٔ فعالیت تکراری است.',
        fieldId: 'activity_ids',
      ),
    ]);
  }
  final predecessors = {for (final id in intIds) id: <int>[]};
  for (var i = 0; i < from.length; i++) {
    final a = from[i].toInt(), b = to[i].toInt();
    if (!predecessors.containsKey(a) || !predecessors.containsKey(b)) {
      return RejectedNetwork([
        networkIssue(
          'unknown_reference',
          'هر دو سر وابستگی باید شناسهٔ یک فعالیت موجود باشند؛ شمارهٔ ردیف جای شناسه نیست.',
          fieldId: 'successor_ids',
          index: i,
        ),
      ]);
    }
    predecessors[b]!.add(a);
  }
  final activities = [
    for (var i = 0; i < ids.length; i++)
      ProjectActivity(
        id: intIds[i],
        duration: durations[i],
        predecessors: predecessors[intIds[i]]!,
      ),
  ];
  final validation = validateNetwork(activities);
  return validation.isEmpty
      ? BoundNetwork(activities)
      : RejectedNetwork(validation);
}

List<CalculationIssue> validateNetwork(List<ProjectActivity> activities) {
  if (activities.isEmpty || activities.length > 200) {
    return [
      networkIssue(
        'activity_count',
        'شبکه باید ۱ تا ۲۰۰ فعالیت داشته باشد.',
        fieldId: 'activity_ids',
      ),
    ];
  }
  if (activities.fold<int>(0, (s, a) => s + a.predecessors.length) > 2000) {
    return [
      networkIssue(
        'edge_count',
        'حداکثر ۲۰۰۰ وابستگی پشتیبانی می‌شود.',
        fieldId: 'predecessor_ids',
      ),
    ];
  }
  final ids = <int>{};
  for (var i = 0; i < activities.length; i++) {
    final a = activities[i];
    if (a.id < 1 || a.id > 999999) {
      return [
        networkIssue(
          'invalid_activity_id',
          'شناسه خارج از بازهٔ ۱ تا ۹۹۹۹۹۹ است.',
          fieldId: 'activity_ids',
          index: i,
        ),
      ];
    }
    if (!ids.add(a.id)) {
      return [
        networkIssue(
          'duplicate_activity',
          'شناسهٔ فعالیت تکراری است.',
          fieldId: 'activity_ids',
          index: i,
        ),
      ];
    }
    if (!a.duration.isFinite || a.duration < 0) {
      return [
        networkIssue(
          'invalid_duration',
          'مدت باید متناهی و نامنفی باشد؛ صفر برای milestone مجاز است.',
          fieldId: 'durations',
          index: i,
        ),
      ];
    }
  }
  for (final a in activities) {
    final seen = <int>{};
    for (final p in a.predecessors) {
      if (!ids.contains(p)) {
        return [
          networkIssue(
            'unknown_reference',
            'پیش‌نیاز به فعالیت موجود ارجاع نمی‌دهد.',
            fieldId: 'predecessor_ids',
          ),
        ];
      }
      if (p == a.id) {
        return [
          networkIssue(
            'self_dependency',
            'فعالیت نمی‌تواند پیش‌نیاز خودش باشد.',
            fieldId: 'predecessor_ids',
          ),
        ];
      }
      if (!seen.add(p)) {
        return [
          networkIssue(
            'duplicate_edge',
            'وابستگی تکراری پذیرفته نیست.',
            fieldId: 'predecessor_ids',
          ),
        ];
      }
    }
  }
  return [];
}

/// Kahn O(V+E), forward/backward passes; virtual start 0 and finish at makespan.
NetworkOutcome scheduleProject(List<ProjectActivity> activities) {
  final issues = validateNetwork(activities);
  if (issues.isNotEmpty) return InvalidNetwork(issues);
  final byId = {for (final a in activities) a.id: a};
  final successors = {for (final a in activities) a.id: <int>[]};
  final indegree = {for (final a in activities) a.id: a.predecessors.length};
  for (final a in activities) {
    for (final p in a.predecessors) {
      successors[p]!.add(a.id);
    }
  }
  final queue = Queue<int>()
    ..addAll(activities.where((a) => a.predecessors.isEmpty).map((a) => a.id));
  final order = <int>[];
  while (queue.isNotEmpty) {
    final id = queue.removeFirst();
    order.add(id);
    for (final next in successors[id]!) {
      indegree[next] = indegree[next]! - 1;
      if (indegree[next] == 0) queue.add(next);
    }
  }
  if (order.length != activities.length) {
    return InvalidNetwork([
      networkIssue(
        'cycle',
        'شبکه چرخه دارد؛ زمان‌بندی و مسیر بحرانی برای شبکهٔ چرخه‌دار تولید نشد.',
        fieldId: 'predecessor_ids',
      ),
    ]);
  }
  InvalidNetwork range() => InvalidNetwork([
    networkIssue(
      'numeric_range',
      'مقیاس داده باعث سرریز یا از دست رفتن مدت/شناوری قابل اتکا می‌شود؛ عدد ساختگی نمایش داده نشد.',
    ),
  ]);
  final es = <int, double>{},
      ef = <int, double>{},
      ls = <int, double>{},
      lf = <int, double>{};
  var horizon = 0.0;
  for (final id in order) {
    final a = byId[id]!;
    final start = a.predecessors.fold<double>(0, (s, p) => math.max(s, ef[p]!));
    final finish = start + a.duration;
    if (!finish.isFinite || (a.duration > 0 && finish == start)) return range();
    es[id] = start;
    ef[id] = finish;
    horizon = math.max(horizon, finish);
  }
  for (final id in order.reversed) {
    final a = byId[id]!, next = successors[id]!;
    final finish = next.fold<double>(horizon, (s, n) => math.min(s, ls[n]!)),
        start = finish - a.duration;
    if (!start.isFinite || (a.duration > 0 && start == finish)) return range();
    lf[id] = finish;
    ls[id] = start;
  }
  // No absolute 1-day floor: tiny networks retain their own scale.
  final tolerance = horizon * (8 * 2.220446049250313e-16);
  double clean(double v) => v.abs() <= tolerance ? 0 : v;
  final rows = <ActivitySchedule>[];
  for (final a in activities) {
    final id = a.id;
    if (ls[id]! < 0) {
      if (ls[id]!.abs() > tolerance) return range();
      ls[id] = 0;
    }
    final tf = clean(ls[id]! - es[id]!),
        ff = clean(
          successors[id]!.fold<double>(horizon, (s, n) => math.min(s, es[n]!)) -
              ef[id]!,
        );
    if (!tf.isFinite ||
        !ff.isFinite ||
        tf < 0 ||
        ff < 0 ||
        ff > tf + tolerance) {
      return range();
    }
    rows.add(
      ActivitySchedule(
        activity: a,
        es: es[id]!,
        ef: ef[id]!,
        ls: ls[id]!,
        lf: lf[id]!,
        totalFloat: tf,
        freeFloat: ff,
        critical: tf == 0,
      ),
    );
  }
  final critical = rows
      .where((r) => r.critical)
      .map((r) => r.activity.id)
      .toSet();
  final tight = {
    for (final id in order)
      id: successors[id]!
          .where(
            (n) =>
                critical.contains(id) &&
                critical.contains(n) &&
                ef[id] == es[n],
          )
          .toList(),
  };
  final waysToFinish = <int, BigInt>{};
  for (final id in order.reversed) {
    if (!critical.contains(id)) {
      waysToFinish[id] = BigInt.zero;
      continue;
    }
    waysToFinish[id] = successors[id]!.isEmpty
        ? (ef[id] == horizon ? BigInt.one : BigInt.zero)
        : tight[id]!.fold<BigInt>(BigInt.zero, (s, n) => s + waysToFinish[n]!);
  }
  final sources = activities
      .where((a) => a.predecessors.isEmpty && critical.contains(a.id))
      .map((a) => a.id)
      .toList();
  final count = sources.fold<BigInt>(
    BigInt.zero,
    (s, id) => s + waysToFinish[id]!,
  );
  if (count == BigInt.zero) return range();
  final path = <int>[];
  var current = sources.firstWhere((id) => waysToFinish[id]! > BigInt.zero);
  while (true) {
    path.add(current);
    final next = tight[current]!.where((id) => waysToFinish[id]! > BigInt.zero);
    if (next.isEmpty) break;
    current = next.first;
  }
  return ScheduledNetwork(
    duration: horizon,
    tolerance: tolerance,
    rows: rows,
    criticalPath: path,
    criticalPathCount: count,
  );
}
