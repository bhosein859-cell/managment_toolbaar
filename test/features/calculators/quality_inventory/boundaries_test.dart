import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/abc_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/sigma_level_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/xbar_control_engine.dart';
import 'package:management_toolbox/features/calculators/domain/statistics/normal_quantile.dart';
import 'package:management_toolbox/features/calculators/domain/statistics/tool_numeric.dart';

import 'fixtures.dart';

void fails(String id, Map<String, Object?> overrides, [String? code]) {
  final o = run(id, overrides);
  expect(o, isA<CalculationFailure>());
  if (code != null) {
    expect((o as CalculationFailure).issues.any((i) => i.code == code), isTrue);
  }
}

void main() {
  for (final id in ['cpk', 'pp', 'ppk']) {
    test('$id: inverted/equal specs and zero sigma', () {
      for (final v in [4, 3]) {
        fails(id, {'usl': v, 'lsl': 4}, 'invalid_limits');
      }
      fails(id, {'sigma': 0});
    });
    test('$id: avoids overflowing width/denominator; refuses underflow', () {
      expect(
        primary(
          run(id, {
            'usl': 1e308,
            'lsl': -1e308,
            'sigma': 1e308,
            if (id != 'pp') 'mean': 0,
          }),
        ),
        closeTo(1 / 3, 1e-15),
      );
      fails(id, {
        'usl': 1e-300,
        'lsl': 0,
        'sigma': 1e308,
        if (id != 'pp') 'mean': 5e-301,
      }, 'numeric_range');
    });
  }
  for (final id in ['cpk', 'ppk']) {
    test('$id: negative outside specs, zero on spec, not clipped', () {
      expect(primary(run(id, {'mean': 13, 'sigma': 1})), closeTo(-1, 1e-15));
      expect(primary(run(id, {'mean': 10, 'sigma': 1})), 0);
    });
  }
  test('DPMO: endpoints and binary opportunities and exact integer cap', () {
    expect(primary(run('dpmo', {'defects': 0})), 0);
    expect(primary(run('dpmo', {'defects': 10000})), 1000000);
    fails('dpmo', {'defects': 10001}, 'too_many_defects');
    fails('dpmo', {
      'units': 9007199254740991,
      'opportunities': 2,
    }, 'opportunity_range');
    fails('dpmo', {'units': 9007199254740992});
  });
  test('Sigma: no fabricated endpoints, rare tail, selectable convention, negative Z', () {
    for (final d in [0, 1000000]) {
      fails('sigma_level', {'dpmo': d}, 'unbounded_sigma');
    }
    fails('sigma_level', {'dpmo': 1e-320}, 'numeric_range');
    expect(primary(run('sigma_level', {'dpmo': 500000})), 0);
    expect(
      primary(run('sigma_level', {'dpmo': 3.4, 'shift': 'convention_1_5'})),
      closeTo(5.9998544700, 5e-8),
    );
    expect(primary(run('sigma_level', {'dpmo': 900000})), lessThan(0));
    expect(primary(run('sigma_level', {'dpmo': 1e-200})).isFinite, isTrue);
  });
  test('Sigma bind rejects unknown shift without inventing enum', () {
    final o = const SigmaLevelEngine().bind(
      CalculatorInput({
        'dpmo': NumberInputValue(1000),
        'shift': ChoiceInputValue('bogus'),
      }),
    );
    expect(o, isA<RejectedInput<SigmaLevelParameters>>());
  });
  test(
    'Normal quantile: independent tabulated tails and center, errors < 5e-8',
    () {
      final expected = {
        1e-300: -37.0470962993612,
        1e-10: -6.361340902404056,
        0.001: -3.090232306167813,
        0.025: -1.959963984540054,
        0.5: 0.0,
        0.95: 1.6448536269514722,
        0.975: 1.959963984540054,
        0.999: 3.090232306167813,
      };
      for (final e in expected.entries) {
        expect(normalQuantile(e.key), closeTo(e.value, 5e-8));
      }
      for (final p in [0.0, 1.0, -1.0, double.nan, double.infinity]) {
        expect(() => normalQuantile(p), throwsArgumentError);
      }
    },
  );
  test('Normal quantile: monotonicity and symmetric central probabilities', () {
    var prior = double.negativeInfinity;
    for (var i = 1; i < 1000; i++) {
      final p = i / 1000, z = normalQuantile(p);
      expect(z, greaterThan(prior));
      expect(z + normalQuantile(1 - p), closeTo(0, 1e-12));
      prior = z;
    }
  });
  test(
    'Xbar: exact subgroup means/ranges, d2 method, allowed negative LCL',
    () {
      final o = run('xbar_control', {
        'subgroup_size': 2,
        'observations': [-1, 1, -2, 2],
      });
      expect(primary(o), 0);
      expect((detail(o, 'subgroup_means') as NumberListResultValue).values, [
        0,
        0,
      ]);
      expect((detail(o, 'subgroup_ranges') as NumberListResultValue).values, [
        2,
        4,
      ]);
      expect(metricValue(o, 'sigma_within'), closeTo(3 / 1.128, 1e-14));
      expect(metricValue(o, 'lcl'), lessThan(0));
      expect(metricValue(o, 'signal_count'), 0);
    },
  );
  test(
    'Xbar: one-point signal indices are chronological, no stability verdict',
    () {
      final data = [
        for (var i = 0; i < 99; i++) ...[0.0, 2.0],
        100.0,
        102.0,
      ];
      final o = run('xbar_control', {'subgroup_size': 2, 'observations': data});
      expect(metricValue(o, 'signal_count'), 1);
      expect((detail(o, 'outside_subgroups') as NumberListResultValue).values, [
        100,
      ]);
      expect(success(o).interpretation, contains('اثبات'));
    },
  );
  test('Xbar: incomplete/single/empty/oversized groups and constant range', () {
    for (final data in [
      <double>[],
      [1.0, 2.0],
      [1.0, 2.0, 3.0, 4.0, 5.0],
      List.filled(1002, 1.0),
    ]) {
      fails('xbar_control', {'subgroup_size': 2, 'observations': data});
    }
    fails('xbar_control', {
      'subgroup_size': 2,
      'observations': [1, 1, 1, 1],
    }, 'zero_range');
  });
  test(
    'Xbar: nonfinite, overflowing ranges and lost scaled observations reject',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        fails('xbar_control', {
          'subgroup_size': 2,
          'observations': [v, 1, 2, 3],
        });
      }
      fails('xbar_control', {
        'subgroup_size': 2,
        'observations': [-1e308, 1e308, 0, 1],
      }, 'numeric_range');
      fails('xbar_control', {
        'subgroup_size': 2,
        'observations': [1e308, 1e-308, 0, 1],
      }, 'numeric_range');
    },
  );
  test('Xbar: copied immutable observations and supported constants', () {
    final data = [1.0, 2.0, 3.0, 4.0];
    final p = XbarControlParameters(subgroupSize: 2, observations: data);
    data[0] = 99;
    expect(p.observations.first, 1);
    expect(() => p.observations.clear(), throwsUnsupportedError);
    expect(XbarControlEngine.d2.keys.toSet(), {2, 3, 4, 5, 6, 7, 8, 9, 10});
  });
  test(
    'COQ: PAF/COPQ identity, zero total gives undefined share not division',
    () {
      final o = run('coq');
      expect(metricValue(o, 'copq'), 700);
      expect(metricValue(o, 'conformity'), 300);
      fails('coq', {
        'prevention': 1e308,
        'appraisal': 0,
        'internal_failure': 1e-300,
        'external_failure': 0,
      }, 'numeric_range');
      final z = run('coq', {
        'prevention': 0,
        'appraisal': 0,
        'internal_failure': 0,
        'external_failure': 0,
      });
      expect(primary(z), 0);
      expect(success(z).details.any((m) => m.value is TextResultValue), isTrue);
      fails('coq', {'prevention': 1e308, 'appraisal': 1e308}, 'numeric_range');
    },
  );
  test('EOQ: continuous optimum and annual ordering/holding balance', () {
    final o = run('eoq');
    expect(metricValue(o, 'ordering_cost'), closeTo(1000, 1e-9));
    expect(metricValue(o, 'holding_cost'), closeTo(1000, 1e-9));
    expect(metricValue(o, 'relevant_cost'), closeTo(2000, 1e-9));
    expect(
      primary(run('eoq', {'annual_demand': 40000})),
      closeTo(2 * primary(o), 1e-9),
    );
    expect(
      primary(
        run('eoq', {
          'annual_demand': 1e308,
          'order_cost': 1e-308,
          'holding_cost': 1,
        }),
      ),
      closeTo(math.sqrt(2), 1e-12),
    );
    fails('eoq', {
      'annual_demand': 1e308,
      'order_cost': 1e308,
      'holding_cost': 1e-308,
    }, 'numeric_range');
  });
  test(
    'ROP: zero and inventory-position buffer, overflow and underflow guarded',
    () {
      expect(
        primary(
          run('rop', {'daily_demand': 0, 'lead_time': 0, 'safety_stock': 0}),
        ),
        0,
      );
      expect(primary(run('rop', {'safety_stock': 60})), 260);
      fails('rop', {'daily_demand': 1e308, 'lead_time': 10}, 'numeric_range');
      fails('rop', {
        'daily_demand': 1e-300,
        'lead_time': 1e-300,
      }, 'numeric_range');
    },
  );
  test('SS: deterministic lead time, service 50 percent, no variation and independent terms', () {
    expect(
      primary(run('safety_stock')),
      closeTo(20 * 1.6448536269514722, 5e-8),
    );
    expect(primary(run('safety_stock', {'service_level': 0.5})), 0);
    expect(primary(run('safety_stock', {'demand_sd': 0, 'lead_sd': 0})), 0);
    expect(
      primary(run('safety_stock', {'demand_sd': 0, 'lead_sd': 2})),
      closeTo(80 * 1.6448536269514722, 2e-7),
    );
  });
  test(
    'SS: nonnegative zero mean cannot have positive SD, correct field errors',
    () {
      for (final (input, field) in [
        ({'mean_demand': 0}, 'demand_sd'),
        ({'mean_lead': 0, 'lead_sd': 1}, 'lead_sd'),
      ]) {
        final o = run('safety_stock', input) as CalculationFailure;
        expect(o.issues.single.fieldId, field);
      }
      fails('safety_stock', {
        'mean_lead': 1e308,
        'demand_sd': 1e308,
      }, 'numeric_range');
    },
  );
  test('ABC: crossing-item policy, exact boundary and zero-value C', () {
    final o = run('abc');
    expect(
      [
        for (var i = 1; i <= 5; i++)
          (detail(o, 'sku_${i}_class') as TextResultValue).value,
      ],
      ['A', 'A', 'B', 'B', 'C'],
    );
    final exact = run('abc', {
      'annual_quantities': [1, 1, 1, 1],
      'unit_costs': [80, 15, 5, 0],
    });
    expect(
      [
        for (var i = 1; i <= 4; i++)
          (detail(exact, 'sku_${i}_class') as TextResultValue).value,
      ],
      ['A', 'B', 'C', 'C'],
    );
    expect(metricValue(exact, 'sku_4_share'), 0);
  });
  test('ABC: stable ties follow original SKU row; shares sum to one', () {
    final o = run('abc', {
      'annual_quantities': [1, 1, 1, 1],
      'unit_costs': [10, 20, 20, 0],
    });
    expect(
      success(o).details.where((m) => m.id.endsWith('_class')).map((m) => m.id),
      ['sku_2_class', 'sku_3_class', 'sku_1_class', 'sku_4_class'],
    );
    expect(
      [for (var i = 1; i <= 4; i++) metricValue(o, 'sku_${i}_share')]
          .reduce((a, b) => a + b),
      closeTo(1, 1e-15),
    );
  });
  test('ABC: list lengths, empty, negatives, nonfinite, zero total, unordered thresholds', () {
    fails('abc', {
      'unit_costs': [1],
    });
    fails('abc', {'annual_quantities': <double>[], 'unit_costs': <double>[]});
    fails('abc', {
      'unit_costs': List.filled(101, 1),
      'annual_quantities': List.filled(101, 1),
    });
    for (final v in [-1.0, double.nan, double.infinity]) {
      fails('abc', {
        'unit_costs': [v, 1, 1, 1, 1],
      });
      fails('abc', {
        'annual_quantities': [v, 1, 1, 1, 1],
      });
    }
    fails('abc', {
      'unit_costs': [0, 0, 0, 0, 0],
    }, 'zero_total_value');
    fails('abc', {
      'a_threshold': 0.95,
      'b_threshold': 0.8,
    }, 'invalid_thresholds');
    fails('abc', {'b_threshold': 0.8}, 'invalid_thresholds');
  });
  test('ABC: multiplication/sum range and immutable paired lists', () {
    fails('abc', {
      'annual_quantities': [1e308],
      'unit_costs': [2],
    }, 'numeric_range');
    fails('abc', {
      'annual_quantities': [1e-300],
      'unit_costs': [1e-300],
    }, 'numeric_range');
    fails('abc', {
      'annual_quantities': [1, 1],
      'unit_costs': [1e308, 1e308],
    }, 'numeric_range');
    final q = [1.0];
    final p = AbcParameters(annualQuantities: q, unitCosts: q);
    q.clear();
    expect(p.annualQuantities, [1]);
    expect(() => p.unitCosts.clear(), throwsUnsupportedError);
  });
  test('Turnover/DIO: period reciprocity, zero COGS/stock conventions', () {
    expect(
      primary(run('inventory_turnover')) * primary(run('days_inventory')),
      closeTo(365, 1e-12),
    );
    expect(primary(run('inventory_turnover', {'cogs': 0})), 0);
    expect(primary(run('days_inventory', {'average_inventory': 0})), 0);
    fails('days_inventory', {'cogs': 0});
  });
  test('Holding cost: linear horizon, explicit year and permitted zeros', () {
    expect(
      primary(run('inventory_holding_cost', {'period_days': 180})),
      closeTo(100000, 1e-7),
    );
    for (final key in ['average_value', 'annual_rate', 'period_days']) {
      expect(primary(run('inventory_holding_cost', {key: 0})), 0);
    }
    fails('inventory_holding_cost', {
      'average_value': 1e308,
      'annual_rate': 1e308,
    }, 'numeric_range');
  });
  test(
    'Reorder interval: explicitly chosen year, inverse demand and continuous Q',
    () {
      expect(
        primary(run('reorder_interval', {'annual_demand': 24000})),
        closeTo(15, 1e-10),
      );
      expect(
        primary(run('reorder_interval', {'year_days': 365})),
        closeTo(365 / 12, 1e-10),
      );
      fails('reorder_interval', {
        'order_quantity': 1e308,
        'annual_demand': 1e-308,
      }, 'numeric_range');
    },
  );
  test('Numeric helpers: compensation, safe hypot and division fallback', () {
    expect(compensatedSum([1e16, 1, -1e16]), 1);
    expect(scaledMean([0, 0]), 0);
    expect(scaledMean([5e-324, 0]).isNaN, isTrue);
    expect(scaledMean([1e308, 1e308]), 1e308);
    expect(scaledMean([1e308, 1e-308]).isNaN, isTrue);
    expect(stableHypot(0, 0), 0);
    expect(stableHypot(3e200, 4e200), closeTo(5e200, 1e186));
    expect(differenceRatio(1, 0, 1e-308, 6), closeTo(1e308 / 6, 1e293));
    expect(differenceRatio(10, 0, 1e-308, 6), closeTo(1e308 * (10 / 6), 1e294));
  });
}
