import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void fails(String id, Map<String, Object?> v, [String? code]) {
  final o = run(id, v);
  expect(o, isA<CalculationFailure>());
  if (code != null) {
    expect((o as CalculationFailure).issues.any((i) => i.code == code), isTrue);
  }
}

void main() {
  for (final id in ['pert_duration', 'three_point']) {
    test('$id: ordered inputs required, never sorted silently', () {
      fails(id, {'optimistic': 5, 'most_likely': 4}, 'unordered_estimates');
      fails(id, {'most_likely': 9}, 'unordered_estimates');
    });
    test('$id: all zero or all equal is deterministic, zero variance', () {
      for (final v in [0.0, 5.0, 1e308, 1e-300]) {
        final o = run(id, {
          'optimistic': v,
          'most_likely': v,
          'pessimistic': v,
        });
        expect(primary(o), v);
        expect(metricValue(o, 'variance'), 0);
        expect(metricValue(o, 'standard_deviation'), 0);
      }
    });
    test('$id: variance overflow/underflow gives numeric failure', () {
      fails(id, {
        'optimistic': 0,
        'most_likely': 1e307,
        'pessimistic': 1e308,
      }, 'numeric_range');
      fails(id, {
        'optimistic': 0,
        'most_likely': 1e-300,
        'pessimistic': 2e-300,
      }, 'numeric_range');
    });
  }
  test(
    'PERT golden mean, SD and variance; translation and scale properties',
    () {
      final o = run('pert_duration');
      expect(primary(o), closeTo(26 / 6, 1e-14));
      expect(metricValue(o, 'standard_deviation'), 1);
      expect(metricValue(o, 'variance'), 1);
      final shifted = run('pert_duration', {
        'optimistic': 12,
        'most_likely': 14,
        'pessimistic': 18,
      });
      expect(primary(shifted) - primary(o), closeTo(10, 1e-14));
      expect(metricValue(shifted, 'variance'), 1);
      final scaled = run('pert_duration', {
        'optimistic': 4,
        'most_likely': 8,
        'pessimistic': 16,
      });
      expect(primary(scaled), closeTo(2 * primary(o), 1e-14));
      expect(metricValue(scaled, 'variance'), 4);
    },
  );
  test('Three-point distinguishes triangular and PERT methods', () {
    final tri = run('three_point'),
        pert = run('three_point', {'method': 'pert'});
    expect(primary(tri), closeTo(14 / 3, 1e-14));
    expect(metricValue(tri, 'variance'), closeTo(14 / 9, 1e-14));
    expect(primary(pert), closeTo(26 / 6, 1e-14));
    expect(metricValue(pert, 'variance'), 1);
    fails('three_point', {'method': 'bogus'}, 'invalid_method');
  });
  test('Triangular endpoint mode and symmetric distributions', () {
    for (final mode in [0, 3, 6]) {
      final o = run('three_point', {
        'optimistic': 0,
        'most_likely': mode,
        'pessimistic': 6,
      });
      expect(primary(o), closeTo((mode + 6) / 3, 1e-14));
      expect(metricValue(o, 'variance'), greaterThan(0));
    }
  });
  test('EVM accepts zero EV and ahead-of-plan, efficient values above one', () {
    final z = run('evm_performance', {'ev': 0});
    expect(primary(z), 0);
    expect(metricValue(z, 'cpi'), 0);
    final o = run('evm_performance', {'ev': 150, 'pv': 100, 'ac': 75});
    expect(primary(o), 1.5);
    expect(metricValue(o, 'cpi'), 2);
  });
  test(
    'EVM rejects zero denominators and numerical ratio overflow/underflow',
    () {
      for (final field in ['pv', 'ac']) {
        fails('evm_performance', {field: 0}, 'undefined_index');
      }
      fails('evm_performance', {'ev': 1e308, 'pv': 1e-308}, 'numeric_range');
      fails('evm_performance', {'ev': 1e-308, 'ac': 1e308}, 'numeric_range');
    },
  );
  test('SV/CV zeros, signs, identity, no EV <= PV or AC restriction', () {
    final z = run('sv_cv', {'pv': 0, 'ev': 0, 'ac': 0});
    expect(primary(z), 0);
    expect(metricValue(z, 'cv'), 0);
    final o = run('sv_cv', {'pv': 100, 'ev': 150, 'ac': 200});
    expect(primary(o), 50);
    expect(metricValue(o, 'cv'), -50);
    expect(primary(o) - metricValue(o, 'cv'), 100);
  });
  test('Four EAC/ETC methods have independently checked outcomes', () {
    for (final (method, eac, etc) in [
      ('cpi', 1250.0, 1150.0),
      ('budget', 1020.0, 920.0),
      ('cpi_spi', 1537.5, 1437.5),
      ('bottom_up', 350.0, 250.0),
    ]) {
      final o = run('eac_etc', {'method': method});
      expect(primary(o), closeTo(eac, 1e-9));
      expect(metricValue(o, 'etc'), closeTo(etc, 1e-9));
      expect(metricValue(o, 'vac'), closeTo(1000 - eac, 1e-9));
      expect(primary(o) - metricValue(o, 'etc'), closeTo(100, 1e-9));
    }
  });
  test('EAC validates BAC and fixed-scope PV/EV bounds, actual costs can exceed BAC', () {
    fails('eac_etc', {'bac': 0});
    fails('eac_etc', {'ev': 1001}, 'above_bac');
    fails('eac_etc', {'pv': 1001}, 'above_bac');
    fails('eac_etc', {'method': 'bogus'}, 'invalid_method');
    expect(
      run('eac_etc', {'ac': 1500, 'method': 'budget'}),
      isA<CalculationSuccess>(),
    );
  });
  test('EAC method-specific undefined ratios do not fabricate forecast', () {
    for (final method in ['cpi', 'cpi_spi']) {
      for (final field in ['ev', 'ac']) {
        fails('eac_etc', {'method': method, field: 0}, 'undefined_forecast');
      }
    }
    fails('eac_etc', {'method': 'cpi_spi', 'pv': 0}, 'undefined_forecast');
    expect(
      run('eac_etc', {'method': 'cpi', 'pv': 0}),
      isA<CalculationSuccess>(),
    );
  });
  test('EAC budget and bottom-up allow start-of-project zeros', () {
    for (final (method, value) in [('budget', 1000), ('bottom_up', 250)]) {
      final o = run('eac_etc', {'method': method, 'pv': 0, 'ev': 0, 'ac': 0});
      expect(primary(o), value);
      expect(metricValue(o, 'etc'), value);
    }
  });
  test('Completed EV=BAC needs no undefined indices except explicit bottom-up estimate', () {
    for (final method in ['cpi', 'budget', 'cpi_spi']) {
      final o = run('eac_etc', {
        'ev': 1000,
        'pv': 0,
        'ac': 0,
        'method': method,
      });
      expect(primary(o), 0);
      expect(metricValue(o, 'etc'), 0);
    }
    final b = run('eac_etc', {
      'ev': 1000,
      'ac': 1200,
      'method': 'bottom_up',
      'new_etc': 200,
    });
    expect(primary(b), 1400);
    expect(metricValue(b, 'etc'), 200);
  });
  test('Unused new ETC cannot change other forecast methods', () {
    for (final method in ['cpi', 'budget', 'cpi_spi']) {
      expect(
        primary(run('eac_etc', {'method': method, 'new_etc': 999999})),
        primary(run('eac_etc', {'method': method, 'new_etc': 0})),
      );
    }
  });
  test('EAC rejects unrepresentable ETC or lost positive costs', () {
    fails('eac_etc', {
      'bac': 1e308,
      'ev': 1,
      'pv': 1,
      'ac': 1e308,
    }, 'numeric_range');
    fails('eac_etc', {
      'bac': 1,
      'pv': 0.5,
      'ev': 0.9999999999999999,
      'ac': 1e-320,
    }, 'numeric_range');
    fails('eac_etc', {
      'method': 'bottom_up',
      'new_etc': 1e-300,
      'ac': 1e308,
    }, 'numeric_range');
  });
  test('Duration comparison early, equal, late and zero actual', () {
    for (final (actual, delta, ratio, percentage) in [
      (8, -2, 0.8, -0.2),
      (10, 0, 1.0, 0.0),
      (12, 2, 1.2, 0.2),
      (0, -10, 0.0, -1.0),
    ]) {
      final o = run('duration_comparison', {'actual_duration': actual});
      expect(primary(o), delta);
      expect(metricValue(o, 'duration_ratio'), ratio);
      expect(metricValue(o, 'overrun'), percentage);
    }
  });
  test(
    'Zero planned duration keeps difference but declares ratios undefined',
    () {
      for (final actual in [0, 12]) {
        final o = run('duration_comparison', {
          'planned_duration': 0,
          'actual_duration': actual,
        });
        expect(primary(o), actual);
        expect(detail(o, 'undefined_ratio'), isA<TextResultValue>());
        expect(success(o).details.any((m) => m.id == 'overrun'), isFalse);
      }
    },
  );
  test('Duration ratios avoid nonfinite and spurious zero', () {
    fails('duration_comparison', {
      'planned_duration': 1e-308,
      'actual_duration': 1e308,
    }, 'numeric_range');
    fails('duration_comparison', {
      'planned_duration': 1e308,
      'actual_duration': 1e-308,
    }, 'numeric_range');
  });
}
