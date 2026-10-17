import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/decision/decision_math.dart';
import 'package:management_toolbox/features/calculators/domain/decision/decision_table.dart';
import 'package:management_toolbox/features/calculators/domain/engines/decision/weight_sensitivity_engine.dart';

import 'fixtures.dart';

void main() {
  for (final id in [
    'decision_matrix',
    'topsis',
    'weighted_scoring',
    'weight_sensitivity',
  ]) {
    test('$id: dimensions and matrix/weight length mismatches reject', () {
      for (final v in [0, 1, 21, 2.5]) {
        fails(id, {'alternatives': v});
      }
      for (final v in [0, 21, 1.5]) {
        fails(id, {'criteria': v});
      }
      fails(id, {
        'matrix': [1, 2],
      }, 'matrix_shape');
      fails(id, {
        'weights': [1],
      }, 'weight_shape');
    });
    test('$id: negative, NaN, infinite or all-zero weights reject', () {
      for (final w in [
        [0.0, 0.0],
        [-1.0, 2.0],
        [double.nan, 1.0],
        [1.0, double.infinity],
        <double>[],
      ]) {
        fails(id, {'weights': w});
      }
    });
    test(
      '$id: nonfinite matrix cells reject, relative weights need not sum to one',
      () {
        for (final x in [
          double.nan,
          double.infinity,
          double.negativeInfinity,
        ]) {
          fails(id, {
            'matrix': [x, 1, 2, 2, 1, 3],
          });
        }
        final o = run(id);
        for (final weights in [
          [6.0, 4.0],
          [6e307, 4e307],
        ]) {
          expect(
            primary(run(id, {'weights': weights})),
            closeTo(primary(o), 1e-12),
          );
        }
        fails(id, {
          'weights': [1e308, 1e-308],
        }, 'numeric_range');
      },
    );
  }
  for (final id in ['decision_matrix', 'topsis', 'weight_sensitivity']) {
    test('$id: criterion types and counts are validated', () {
      fails(id, {
        'directions': [1],
      }, 'direction_shape');
      for (final d in [
        [1, 0],
        [1, 2],
        [double.nan, 1],
      ]) {
        fails(id, {'directions': d}, 'invalid_direction');
      }
    });
  }
  test('Known min-max hand data and cost reversal', () {
    final o = run('decision_matrix');
    expect(
      series(o, 'scores'),
      orderedEquals([0.6, 0.5, 0.4].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'normalized_matrix'),
      orderedEquals([1, 0, 0.5, 0.5, 0, 1].map((v) => closeTo(v, 1e-12))),
    );
    final cost = run('decision_matrix', {
      'directions': [-1, 1],
    });
    expect(
      series(cost, 'scores'),
      orderedEquals([0.0, 0.5, 1.0].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(cost, 'top_options'),
      orderedEquals([3].map((v) => closeTo(v, 1e-12))),
    );
  });
  test('Min-max handles signed data and constant columns without weight redistribution', () {
    final o = run('decision_matrix', {
      'alternatives': 2,
      'matrix': [2, -1, 2, 3],
      'weights': [1, 1],
    });
    expect(
      series(o, 'normalized_matrix'),
      orderedEquals([0, 0, 0, 1].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'scores'),
      orderedEquals([0, 0.5].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      success(o).warnings.any((w) => w.code == 'constant_criteria'),
      isTrue,
    );
    final all = run('decision_matrix', {
      'matrix': [5, 7, 5, 7, 5, 7],
    });
    expect(
      series(all, 'scores'),
      orderedEquals([0, 0, 0].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(all, 'ranks'),
      orderedEquals([1, 1, 1].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(all, 'top_options'),
      orderedEquals([1, 2, 3].map((v) => closeTo(v, 1e-12))),
    );
  });
  test('TOPSIS known dominance, benefit/cost, endpoints zero/one', () {
    final o = run('topsis', {
      'alternatives': 2,
      'matrix': [1, 9, 9, 1],
      'weights': [1, 1],
      'directions': [1, -1],
    });
    expect(
      series(o, 'scores'),
      orderedEquals([0, 1].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'ranks'),
      orderedEquals([2, 1].map((v) => closeTo(v, 1e-12))),
    );
    final reverse = run('topsis', {
      'alternatives': 2,
      'matrix': [1, 9, 9, 1],
      'weights': [1, 1],
      'directions': [-1, 1],
    });
    expect(
      series(reverse, 'scores'),
      orderedEquals([1, 0].map((v) => closeTo(v, 1e-12))),
    );
  });
  test(
    'TOPSIS symmetric golden tradeoff, positive column scaling invariant',
    () {
      final o = run('topsis');
      for (var i = 0; i < 3; i++) {
        expect(series(o, 'scores')[i], closeTo([0.6, 0.5, 0.4][i], 1e-14));
      }
      final scaled = run('topsis', {
        'matrix': [3e200, 1e-200, 2e200, 2e-200, 1e200, 3e-200],
      });
      for (var i = 0; i < 3; i++) {
        expect(
          series(scaled, 'scores')[i],
          closeTo(series(o, 'scores')[i], 1e-13),
        );
      }
    },
  );
  test(
    'TOPSIS no arbitrary closeness for identical effective alternatives',
    () {
      fails('topsis', {
        'matrix': [1, 2, 1, 2, 1, 2],
      }, 'undefined_closeness');
      fails('topsis', {
        'matrix': [0, 0, 0, 0, 0, 0],
      }, 'undefined_closeness');
      fails('topsis', {
        'matrix': [1, 2, 2, 2, 3, 2],
        'weights': [0, 1],
      }, 'undefined_closeness');
      fails('topsis', {
        'matrix': [-1, 2, 2, 2, 3, 2],
      }, 'invalid_matrix_value');
    },
  );
  test('TOPSIS zero columns/rows and overflowing raw norm remain handled', () {
    final o = run('topsis', {
      'matrix': [0, 0, 0, 1, 0, 2],
    });
    expect(
      series(o, 'scores'),
      orderedEquals([0, 0.5, 1].map((v) => closeTo(v, 1e-12))),
    );
    final huge = run('topsis', {
      'alternatives': 4,
      'matrix': [1e308, 1, 1e308, 2, 1e308, 3, 1e308, 4],
    });
    expect(primary(huge), 1);
    expect(series(huge, 'scores').first, 0);
  });
  test(
    'Weighted scoring does not silently normalize incomparable raw scales',
    () {
      final o = run('weighted_scoring');
      for (var i = 0; i < 3; i++) {
        expect(series(o, 'scores')[i], closeTo([7.2, 7.8, 7.4][i], 1e-14));
      }
      final signed = run('weighted_scoring', {
        'alternatives': 2,
        'matrix': [-2, -2, -1, -1],
      });
      expect(
        series(signed, 'scores'),
        orderedEquals([-2, -1].map((v) => closeTo(v, 1e-12))),
      );
      expect(primary(signed), -1);
    },
  );
  test('Zero weights disable finite values without contaminating active-scale arithmetic', () {
    final o = run('weighted_scoring', {
      'alternatives': 2,
      'matrix': [1, 1e308, 2, 1e-308],
      'weights': [1, 0],
    });
    expect(
      series(o, 'scores'),
      orderedEquals([1, 2].map((v) => closeTo(v, 1e-12))),
    );
  });
  test(
    'Two through twenty options and one through twenty criteria are dynamic',
    () {
      for (final id in ['decision_matrix', 'topsis', 'weighted_scoring']) {
        for (final (n, m) in [(2, 1), (20, 20)]) {
          final o = run(id, {
            'alternatives': n,
            'criteria': m,
            'matrix': [
              for (var i = 0; i < n; i++)
                for (var j = 0; j < m; j++) i + 0.0,
            ],
            'weights': List.filled(m, 1.0),
            if (id != 'weighted_scoring') 'directions': List.filled(m, 1.0),
          });
          expect(series(o, 'scores'), hasLength(n));
          expect(
            series(o, 'top_options'),
            orderedEquals([n.toDouble()].map((v) => closeTo(v, 1e-12))),
          );
          expect(primary(o), id == 'weighted_scoring' ? n - 1.0 : 1.0);
        }
      }
    },
  );
  test('Rank groups use anchored relative tolerance, stable ordering, no absolute floor', () {
    expect(competitionRanks([1, 1 - 0.75e-10, 1 - 1.5e-10]), [1, 1, 3]);
    expect(descendingOrder([2, 2, 1]), [0, 1, 2]);
    expect(competitionRanks([1e-300, 2e-300]), [2, 1]);
    expect(competitionRanks([0, 0, 0]), [1, 1, 1]);
  });
  test('Sensitivity sampled endpoints/ties and baseline are independently hand-checkable', () {
    final o = run('weight_sensitivity');
    expect(
      series(o, 'scores'),
      orderedEquals([0.6, 0.5, 0.4].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'scenario_1_scores'),
      orderedEquals([0, 0.5, 1].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'scenario_1_top'),
      orderedEquals([3].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'scenario_2_scores'),
      orderedEquals([0.5, 0.5, 0.5].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'scenario_2_top'),
      orderedEquals([1, 2, 3].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'scenario_3_scores'),
      orderedEquals([1, 0.5, 0].map((v) => closeTo(v, 1e-12))),
    );
    expect(
      series(o, 'scenario_3_top'),
      orderedEquals([1].map((v) => closeTo(v, 1e-12))),
    );
  });
  test('Sensitivity rejects missing redistribution base, bad selection and samples', () {
    fails('weight_sensitivity', {
      'weights': [1, 0],
    }, 'undefined_redistribution');
    for (final j in [0, 3, 1.5]) {
      fails('weight_sensitivity', {'selected_criterion': j});
    }
    for (final s in [
      <double>[],
      List.filled(22, 0.5),
      [-0.1],
      [1.1],
      [double.nan],
      [double.infinity],
    ]) {
      fails('weight_sensitivity', {'sweep_weights': s}, 'invalid_sweep');
    }
  });
  test('Matrix and sweep input snapshots immutable', () {
    final values = [1.0, 2.0], weights = [1.0], directions = [1.0];
    final t = DecisionTable(
      alternatives: 2,
      criteria: 1,
      values: values,
      weights: weights,
      directions: directions,
    );
    values.clear();
    weights.clear();
    directions.clear();
    expect(t.values, [1, 2]);
    expect(() => t.values.clear(), throwsUnsupportedError);
    expect(() => t.weights.clear(), throwsUnsupportedError);
    final sweep = [0.0, 1.0];
    final p = WeightSensitivityParameters(
      table: t,
      selectedCriterion: 1,
      sweepWeights: sweep,
    );
    sweep.clear();
    expect(p.sweepWeights, [0, 1]);
    expect(() => p.sweepWeights.clear(), throwsUnsupportedError);
  });
}
