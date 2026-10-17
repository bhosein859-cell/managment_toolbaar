import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  test('pert_duration: independent typed default and assumptions', () {
    final o = run('pert_duration');
    expect(
      primary(o),
      closeTo(4.333333333333333, 1e-10 + (4.333333333333333).abs() * 1e-10),
    );
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('pert_duration.optimistic: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        run('pert_duration', {'optimistic': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('pert_duration.most_likely: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        run('pert_duration', {'most_likely': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('pert_duration.pessimistic: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        run('pert_duration', {'pessimistic': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('cpm: independent typed default and assumptions', () {
    final o = run('cpm');
    expect(primary(o), closeTo(8, 1e-10 + (8).abs() * 1e-10));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('project_float: independent typed default and assumptions', () {
    final o = run('project_float');
    expect(primary(o), closeTo(2, 1e-10 + (2).abs() * 1e-10));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('evm_performance: independent typed default and assumptions', () {
    final o = run('evm_performance');
    expect(primary(o), closeTo(0.8, 1e-10 + (0.8).abs() * 1e-10));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test(
    'evm_performance.pv: rejects negative and all nonfinite values directly',
    () {
      for (final v in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(run('evm_performance', {'pv': v}), isA<CalculationFailure>());
      }
    },
  );
  test(
    'evm_performance.ev: rejects negative and all nonfinite values directly',
    () {
      for (final v in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(run('evm_performance', {'ev': v}), isA<CalculationFailure>());
      }
    },
  );
  test(
    'evm_performance.ac: rejects negative and all nonfinite values directly',
    () {
      for (final v in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(run('evm_performance', {'ac': v}), isA<CalculationFailure>());
      }
    },
  );
  test('three_point: independent typed default and assumptions', () {
    final o = run('three_point');
    expect(
      primary(o),
      closeTo(4.666666666666667, 1e-10 + (4.666666666666667).abs() * 1e-10),
    );
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('three_point.optimistic: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('three_point', {'optimistic': v}), isA<CalculationFailure>());
    }
  });
  test('three_point.most_likely: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('three_point', {'most_likely': v}), isA<CalculationFailure>());
    }
  });
  test('three_point.pessimistic: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('three_point', {'pessimistic': v}), isA<CalculationFailure>());
    }
  });
  test('eac_etc: independent typed default and assumptions', () {
    final o = run('eac_etc');
    expect(primary(o), closeTo(1250, 1e-10 + (1250).abs() * 1e-10));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('eac_etc.bac: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('eac_etc', {'bac': v}), isA<CalculationFailure>());
    }
  });
  test('eac_etc.pv: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('eac_etc', {'pv': v}), isA<CalculationFailure>());
    }
  });
  test('eac_etc.ev: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('eac_etc', {'ev': v}), isA<CalculationFailure>());
    }
  });
  test('eac_etc.ac: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('eac_etc', {'ac': v}), isA<CalculationFailure>());
    }
  });
  test(
    'eac_etc.new_etc: rejects negative and all nonfinite values directly',
    () {
      for (final v in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(run('eac_etc', {'new_etc': v}), isA<CalculationFailure>());
      }
    },
  );
  test('sv_cv: independent typed default and assumptions', () {
    final o = run('sv_cv');
    expect(primary(o), closeTo(-20, 1e-10 + (-20).abs() * 1e-10));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('sv_cv.pv: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('sv_cv', {'pv': v}), isA<CalculationFailure>());
    }
  });
  test('sv_cv.ev: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('sv_cv', {'ev': v}), isA<CalculationFailure>());
    }
  });
  test('sv_cv.ac: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(run('sv_cv', {'ac': v}), isA<CalculationFailure>());
    }
  });
  test('duration_comparison: independent typed default and assumptions', () {
    final o = run('duration_comparison');
    expect(primary(o), closeTo(2, 1e-10 + (2).abs() * 1e-10));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('duration_comparison.planned_duration: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        run('duration_comparison', {'planned_duration': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('duration_comparison.actual_duration: rejects negative and all nonfinite values directly', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(
        run('duration_comparison', {'actual_duration': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  final references = jsonDecode(
    File('test/fixtures/project_reference.json').readAsStringSync(),
  ) as List<dynamic>;
  for (final id in defaults.keys) {
    test('$id: independent Decimal or exhaustive-path oracle', () {
      final rows = references
          .cast<Map<String, dynamic>>()
          .where((r) => r['id'] == id)
          .toList();
      expect(rows, hasLength(id == 'cpm' || id == 'project_float' ? 100 : 20));
      for (final r in rows) {
        final inputs = Map<String, Object?>.from(
              r['inputs'] as Map<String, dynamic>,
            ),
            o = typed(id, inputs),
            expected = double.parse(r['expected'] as String);
        expect(primary(o), closeTo(expected, expected.abs() * 1e-10 + 1e-10));
        for (final key in ['variance', 'cpi', 'cv', 'etc', 'vac']) {
          if (r.containsKey(key)) {
            expect(
              metricValue(o, key),
              closeTo(
                double.parse(r[key] as String),
                double.parse(r[key] as String).abs() * 1e-10 + 1e-10,
              ),
            );
          }
        }
        if (id == 'cpm' || id == 'project_float') {
          final details = r['details'] as Map<String, dynamic>;
          for (final key
              in id == 'cpm'
                  ? ['es', 'ef', 'ls', 'lf']
                  : ['total_float', 'free_float']) {
            final expected = (details[key] as List<dynamic>).map(
              (x) => double.parse(x as String),
            );
            expect(series(o, key), orderedEquals(expected));
          }
          expect(metricValue(o, 'critical_path_count'), r['critical_count']);
          final activities = network(inputs),
              path = series(o, 'critical_path').map((v) => v.toInt()).toList();
          expect(
            activities.singleWhere((a) => a.id == path.first).predecessors,
            isEmpty,
          );
          for (var i = 1; i < path.length; i++) {
            expect(
              activities.singleWhere((a) => a.id == path[i]).predecessors,
              contains(path[i - 1]),
            );
          }
          expect(
            activities.any((a) => a.predecessors.contains(path.last)),
            isFalse,
          );
          final pathLength = path
              .map((id) => activities.singleWhere((a) => a.id == id).duration)
              .fold<double>(0, (a, b) => a + b);
          final horizon = id == 'cpm'
              ? primary(o)
              : metricValue(o, 'project_duration');
          expect(pathLength, closeTo(horizon, 1e-10));
        }
      }
    });
  }
}
