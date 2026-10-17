import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/project_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/cpm_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/project/project_float_engine.dart';
import 'package:management_toolbox/features/calculators/domain/project/project_network.dart';

import 'fixtures.dart';

ProjectActivity a(
  int id,
  double duration, [
  List<int> predecessors = const [],
]) => ProjectActivity(id: id, duration: duration, predecessors: predecessors);
void invalid(List<ProjectActivity> activities, String code) {
  for (final o in [
    const CpmEngine().calculate(CpmParameters(activities)),
    const ProjectFloatEngine().calculate(ProjectFloatParameters(activities)),
  ]) {
    expect(o, isA<CalculationFailure>());
    expect((o as CalculationFailure).issues.any((i) => i.code == code), isTrue);
  }
}

void main() {
  test('CPM: golden forward/backward passes and connected path', () {
    final o = run('cpm');
    expect(primary(o), 8);
    expect(series(o, 'activity_ids'), [1, 2, 3, 4]);
    expect(series(o, 'es'), [0, 3, 3, 7]);
    expect(series(o, 'ef'), [3, 5, 7, 8]);
    expect(series(o, 'ls'), [0, 5, 3, 7]);
    expect(series(o, 'lf'), [3, 7, 7, 8]);
    expect(series(o, 'critical_path'), [1, 3, 4]);
    expect(series(o, 'critical_activities'), [1, 3, 4]);
    expect(metricValue(o, 'critical_path_count'), 1);
  });
  test(
    'Float: TF differs from FF with delayed downstream noncritical work',
    () {
      final o = const ProjectFloatEngine().calculate(
        ProjectFloatParameters([
          a(1, 3),
          a(2, 2, [1]),
          a(3, 5, [1]),
          a(4, 1, [2]),
          a(5, 1, [3, 4]),
        ]),
      );
      expect(series(o, 'total_float'), [0, 2, 0, 2, 0]);
      expect(series(o, 'free_float'), [0, 0, 0, 2, 0]);
      expect(primary(o), 2);
    },
  );
  test('Multiple critical paths: union is not a path, deterministic connected representative', () {
    final o = const CpmEngine().calculate(
      CpmParameters([
        a(4, 1, [2, 3]),
        a(3, 4, [1]),
        a(2, 4, [1]),
        a(1, 3),
      ]),
    );
    expect(primary(o), 8);
    expect(series(o, 'critical_activities'), [4, 3, 2, 1]);
    expect(series(o, 'critical_path'), [1, 3, 4]);
    expect(metricValue(o, 'critical_path_count'), 2);
  });
  test(
    'Disconnected components share virtual finish: shorter terminal gets FF',
    () {
      final o = const ProjectFloatEngine().calculate(
        ProjectFloatParameters([a(10, 5), a(20, 2)]),
      );
      expect(series(o, 'total_float'), [0, 3]);
      expect(series(o, 'free_float'), [0, 3]);
      expect(series(o, 'critical_path'), [10]);
    },
  );
  test(
    'Zero milestones, all-zero networks, isolated nodes and many sources/sinks',
    () {
      for (final nodes in [
        [a(7, 0)],
        [
          a(1, 0),
          a(2, 0, [1]),
          a(3, 0, [1]),
        ],
        [a(1, 0), a(2, 0)],
      ]) {
        final s = scheduleProject(nodes) as ScheduledNetwork;
        expect(s.duration, 0);
        expect(
          s.rows.every(
            (r) => r.totalFloat == 0 && r.freeFloat == 0 && r.critical,
          ),
          isTrue,
        );
        expect(s.criticalPath, isNotEmpty);
      }
      expect(
        (scheduleProject([
          a(1, 0),
          a(2, 0),
        ]) as ScheduledNetwork).criticalPathCount,
        BigInt.two,
      );
    },
  );
  test('Kahn rejects full, partial and zero-duration cycles', () {
    invalid([
      a(1, 1, [2]),
      a(2, 1, [1]),
    ], 'cycle');
    invalid([
      a(1, 1),
      a(2, 0, [3]),
      a(3, 0, [2]),
    ], 'cycle');
    invalid([
      a(1, 0, [3]),
      a(2, 0, [1]),
      a(3, 0, [2]),
    ], 'cycle');
  });
  test('Unknown refs, duplicates, self edges and invalid IDs are not silently dropped', () {
    invalid([
      a(1, 1, [2]),
    ], 'unknown_reference');
    invalid([a(1, 1), a(1, 2)], 'duplicate_activity');
    invalid([
      a(1, 1, [1]),
    ], 'self_dependency');
    invalid([
      a(1, 1),
      a(2, 1, [1, 1]),
    ], 'duplicate_edge');
    for (final id in [0, -1, 1000000]) {
      invalid([a(id, 1)], 'invalid_activity_id');
    }
    expect(scheduleProject([a(999999, 1)]), isA<ScheduledNetwork>());
  });
  test('Direct model rejects nonfinite or negative duration', () {
    for (final d in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      invalid([a(1, d)], 'invalid_duration');
    }
  });
  test('Network limits: empty and oversized nodes/edges reject', () {
    invalid([], 'activity_count');
    invalid([for (var i = 1; i <= 201; i++) a(i, 1)], 'activity_count');
    invalid([a(1, 1), a(2, 1, List.filled(2001, 1))], 'edge_count');
  });
  test(
    '200 activities schedule without recursion, also fractional durations',
    () {
      for (final duration in [1.0, 0.1]) {
        final s = scheduleProject([
          for (var i = 1; i <= 200; i++) a(i, duration, i == 1 ? [] : [i - 1]),
        ]) as ScheduledNetwork;
        expect(s.duration, closeTo(duration * 200, 1e-10));
        expect(s.criticalPath, hasLength(200));
        expect(s.criticalPathCount, BigInt.one);
        expect(s.rows.every((r) => r.critical), isTrue);
      }
    },
  );
  test('Count exponential paths with BigInt without enumerating paths', () {
    final nodes = [
      for (var i = 1; i <= 60; i++) a(i, 0, [for (var j = 1; j < i; j++) j]),
    ];
    final s = scheduleProject(nodes) as ScheduledNetwork;
    expect(s.criticalPathCount, BigInt.one << 58);
    expect(s.criticalPath, hasLength(60));
    final o = const CpmEngine().calculate(CpmParameters(nodes));
    expect(detail(o, 'critical_path_count'), isA<TextResultValue>());
  });
  test('Tiny scale retains nonzero times, huge scale refuses lost durations/overflow', () {
    final s = scheduleProject([
      a(1, 1e-300),
      a(2, 1e-300, [1]),
    ]) as ScheduledNetwork;
    expect(s.rows.first.ef, 1e-300);
    expect(s.duration, 2e-300);
    invalid([
      a(1, 1e308),
      a(2, 1e308, [1]),
    ], 'numeric_range');
    invalid([
      a(1, 1e308),
      a(2, 1, [1]),
    ], 'numeric_range');
    invalid([a(1, 1e308), a(2, 1)], 'numeric_range');
  });
  test('Tolerance has no one-day floor, only slack is normalized', () {
    final s = scheduleProject([
      a(1, 1e-20),
      a(2, 1e-20),
      a(3, 1e-25),
    ]) as ScheduledNetwork;
    expect(s.rows.last.ef, 1e-25);
    expect(s.rows.last.critical, isFalse);
    expect(s.tolerance, lessThan(1e-30));
  });
  test('Near-equal slack classification discloses scaled epsilon', () {
    final s = scheduleProject([a(1, 1), a(2, 1 - 1e-16)]) as ScheduledNetwork;
    expect(s.rows.last.critical, isTrue);
    expect(s.criticalPathCount, BigInt.one);
    expect(s.criticalPath, [1]);
    expect(s.tolerance, greaterThan(0));
    expect(series(run('cpm'), 'critical_path'), isNotEmpty);
  });
  test('Near-critical alternatives do not multiply or shorten the actual longest paths', () {
    final s = scheduleProject([
      a(1, 0),
      a(2, 1 - 1e-15, [1]),
      a(3, 1, [1]),
      a(4, 0, [2, 3]),
      a(5, 1 - 1e-15, [4]),
      a(6, 1, [4]),
      a(7, 0, [5, 6]),
    ]) as ScheduledNetwork;
    expect(s.rows.every((r) => r.critical), isTrue);
    expect(s.criticalPathCount, BigInt.one);
    expect(s.criticalPath, [1, 3, 4, 6, 7]);
  });
  test('Immutable inputs and schedule snapshots', () {
    final predecessors = [1];
    final node = ProjectActivity(
      id: 2,
      duration: 1,
      predecessors: predecessors,
    );
    predecessors.clear();
    expect(node.predecessors, [1]);
    expect(() => node.predecessors.clear(), throwsUnsupportedError);
    final nodes = [a(1, 1), node];
    final p = CpmParameters(nodes);
    nodes.clear();
    expect(p.activities, hasLength(2));
    expect(() => p.activities.clear(), throwsUnsupportedError);
    final s = scheduleProject(p.activities) as ScheduledNetwork;
    expect(() => s.rows.clear(), throwsUnsupportedError);
    expect(() => s.criticalPath.clear(), throwsUnsupportedError);
  });
  for (final runner in [
    ProjectCalculators.cpmRunner,
    ProjectCalculators.projectFloatRunner,
  ]) {
    test(
      '${runner.definition.id}: structural form rejects fractional, missing, mismatched and duplicate refs',
      () {
        final raw = runner.definition.examples.single.inputs;
        for (final (key, values) in [
          ('activity_ids', ['1', '1', '3', '4']),
          ('activity_ids', ['1.5', '2', '3', '4']),
          ('predecessor_ids', ['1', '1', '2', '99']),
          ('successor_ids', ['2', '3']),
          ('durations', ['1', '2']),
        ]) {
          final o = runner.run(
            RawCalculatorInput({
              ...raw.values,
              key: RawNumberListInput(values),
            }),
          );
          expect(o, isA<CalculationFailure>());
          expect(
            (o as CalculationFailure).issues.any(
              (i) => i.code == 'calculation_failed',
            ),
            isFalse,
          );
        }
      },
    );
    test(
      '${runner.definition.id}: empty dependency lists mean no edges, not default graph',
      () {
        final raw = runner.definition.examples.single.inputs;
        final o = runner.run(
          RawCalculatorInput({
            ...raw.values,
            'predecessor_ids': RawNumberListInput([]),
            'successor_ids': RawNumberListInput([]),
          }),
        );
        expect(o, isA<CalculationSuccess>());
        expect(primary(o), runner.definition.id == 'cpm' ? 4 : 3);
        expect(series(o, 'critical_path'), [3]);
      },
    );
  }
  test('Binding validates normalized shape, IDs and row capacities too', () {
    final valid = <String, InputValue>{
      'activity_ids': NumberListInputValue([1, 2]),
      'durations': NumberListInputValue([1, 2]),
    };
    expect(bindNetwork(CalculatorInput(valid)), isA<BoundNetwork>());
    for (final values in [
      <String, InputValue>{},
      {...valid, 'activity_ids': NumberInputValue(1)},
      {...valid, 'activity_ids': NumberListInputValue([])},
      {
        ...valid,
        'activity_ids': NumberListInputValue([1, 2.5]),
      },
      {
        ...valid,
        'activity_ids': NumberListInputValue([0, 2]),
      },
      {
        ...valid,
        'activity_ids': NumberListInputValue([1, 1000000]),
      },
      {
        ...valid,
        'predecessor_ids': NumberListInputValue([1]),
      },
      {
        ...valid,
        'predecessor_ids': NumberListInputValue(List.filled(2001, 1)),
        'successor_ids': NumberListInputValue(List.filled(2001, 2)),
      },
    ]) {
      expect(bindNetwork(CalculatorInput(values)), isA<RejectedNetwork>());
    }
  });
  test('Optional empty series is supported only with minItems zero and nonrequired', () {
    expect(
      () => NumberListFieldDefinition(id: 'edges', label: 'یال', minItems: 0),
      throwsArgumentError,
    );
    final f = NumberListFieldDefinition(
      id: 'edges',
      label: 'یال',
      isRequired: false,
      minItems: 0,
      defaultValue: [],
    );
    expect(f.defaultValue, isEmpty);
  });
}
