import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  test('cpk: independently typed example and assumptions', () {
    final o = run('cpk');
    expect(primary(o), closeTo(1, 5e-8 + (1).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('cpk.usl: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('cpk', {'usl': v}), isA<CalculationFailure>());
    }
  });
  test('cpk.lsl: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('cpk', {'lsl': v}), isA<CalculationFailure>());
    }
  });
  test('cpk.mean: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('cpk', {'mean': v}), isA<CalculationFailure>());
    }
  });
  test('cpk.sigma: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('cpk', {'sigma': v}), isA<CalculationFailure>());
    }
  });
  test('cpk.sigma: rejects lower-bound violation', () {
    expect(run('cpk', {'sigma': 0}), isA<CalculationFailure>());
  });
  test('pp: independently typed example and assumptions', () {
    final o = run('pp');
    expect(primary(o), closeTo(0.5, 5e-8 + (0.5).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('pp.usl: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('pp', {'usl': v}), isA<CalculationFailure>());
    }
  });
  test('pp.lsl: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('pp', {'lsl': v}), isA<CalculationFailure>());
    }
  });
  test('pp.sigma: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('pp', {'sigma': v}), isA<CalculationFailure>());
    }
  });
  test('pp.sigma: rejects lower-bound violation', () {
    expect(run('pp', {'sigma': 0}), isA<CalculationFailure>());
  });
  test('ppk: independently typed example and assumptions', () {
    final o = run('ppk');
    expect(
      primary(o),
      closeTo(0.3333333333333333, 5e-8 + (0.3333333333333333).abs() * 5e-8),
    );
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('ppk.usl: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('ppk', {'usl': v}), isA<CalculationFailure>());
    }
  });
  test('ppk.lsl: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('ppk', {'lsl': v}), isA<CalculationFailure>());
    }
  });
  test('ppk.mean: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('ppk', {'mean': v}), isA<CalculationFailure>());
    }
  });
  test('ppk.sigma: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('ppk', {'sigma': v}), isA<CalculationFailure>());
    }
  });
  test('ppk.sigma: rejects lower-bound violation', () {
    expect(run('ppk', {'sigma': 0}), isA<CalculationFailure>());
  });
  test('dpmo: independently typed example and assumptions', () {
    final o = run('dpmo');
    expect(primary(o), closeTo(1000, 5e-8 + (1000).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('dpmo.defects: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('dpmo', {'defects': v}), isA<CalculationFailure>());
    }
  });
  test('dpmo.defects: rejects lower-bound violation', () {
    expect(run('dpmo', {'defects': -1}), isA<CalculationFailure>());
  });
  test('dpmo.defects: rejects fractional count', () {
    expect(run('dpmo', {'defects': 2.5}), isA<CalculationFailure>());
  });
  test('dpmo.units: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('dpmo', {'units': v}), isA<CalculationFailure>());
    }
  });
  test('dpmo.units: rejects lower-bound violation', () {
    expect(run('dpmo', {'units': 0}), isA<CalculationFailure>());
  });
  test('dpmo.units: rejects fractional count', () {
    expect(run('dpmo', {'units': 2.5}), isA<CalculationFailure>());
  });
  test('dpmo.opportunities: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('dpmo', {'opportunities': v}), isA<CalculationFailure>());
    }
  });
  test('dpmo.opportunities: rejects lower-bound violation', () {
    expect(run('dpmo', {'opportunities': 0}), isA<CalculationFailure>());
  });
  test('dpmo.opportunities: rejects fractional count', () {
    expect(run('dpmo', {'opportunities': 2.5}), isA<CalculationFailure>());
  });
  test('sigma_level: independently typed example and assumptions', () {
    final o = run('sigma_level');
    expect(
      primary(o),
      closeTo(3.090232306167813, 5e-8 + (3.090232306167813).abs() * 5e-8),
    );
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('sigma_level.dpmo: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('sigma_level', {'dpmo': v}), isA<CalculationFailure>());
    }
  });
  test('sigma_level.dpmo: rejects lower-bound violation', () {
    expect(run('sigma_level', {'dpmo': -1}), isA<CalculationFailure>());
  });
  test('sigma_level.dpmo: rejects upper-bound violation', () {
    expect(run('sigma_level', {'dpmo': 1000001}), isA<CalculationFailure>());
  });
  test('xbar_control: independently typed example and assumptions', () {
    final o = run('xbar_control');
    expect(primary(o), closeTo(11, 5e-8 + (11).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test(
    'xbar_control.subgroup_size: rejects NaN and both infinities directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('xbar_control', {'subgroup_size': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('xbar_control.subgroup_size: rejects lower-bound violation', () {
    expect(
      run('xbar_control', {'subgroup_size': 1}),
      isA<CalculationFailure>(),
    );
  });
  test('xbar_control.subgroup_size: rejects upper-bound violation', () {
    expect(
      run('xbar_control', {'subgroup_size': 11}),
      isA<CalculationFailure>(),
    );
  });
  test('xbar_control.subgroup_size: rejects fractional count', () {
    expect(
      run('xbar_control', {'subgroup_size': 2.5}),
      isA<CalculationFailure>(),
    );
  });
  test('coq: independently typed example and assumptions', () {
    final o = run('coq');
    expect(primary(o), closeTo(1000, 5e-8 + (1000).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('coq.prevention: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('coq', {'prevention': v}), isA<CalculationFailure>());
    }
  });
  test('coq.prevention: rejects lower-bound violation', () {
    expect(run('coq', {'prevention': -1}), isA<CalculationFailure>());
  });
  test('coq.appraisal: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('coq', {'appraisal': v}), isA<CalculationFailure>());
    }
  });
  test('coq.appraisal: rejects lower-bound violation', () {
    expect(run('coq', {'appraisal': -1}), isA<CalculationFailure>());
  });
  test('coq.internal_failure: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('coq', {'internal_failure': v}), isA<CalculationFailure>());
    }
  });
  test('coq.internal_failure: rejects lower-bound violation', () {
    expect(run('coq', {'internal_failure': -1}), isA<CalculationFailure>());
  });
  test('coq.external_failure: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('coq', {'external_failure': v}), isA<CalculationFailure>());
    }
  });
  test('coq.external_failure: rejects lower-bound violation', () {
    expect(run('coq', {'external_failure': -1}), isA<CalculationFailure>());
  });
  test('eoq: independently typed example and assumptions', () {
    final o = run('eoq');
    expect(primary(o), closeTo(1000, 5e-8 + (1000).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('eoq.annual_demand: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('eoq', {'annual_demand': v}), isA<CalculationFailure>());
    }
  });
  test('eoq.annual_demand: rejects lower-bound violation', () {
    expect(run('eoq', {'annual_demand': 0}), isA<CalculationFailure>());
  });
  test('eoq.order_cost: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('eoq', {'order_cost': v}), isA<CalculationFailure>());
    }
  });
  test('eoq.order_cost: rejects lower-bound violation', () {
    expect(run('eoq', {'order_cost': 0}), isA<CalculationFailure>());
  });
  test('eoq.holding_cost: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('eoq', {'holding_cost': v}), isA<CalculationFailure>());
    }
  });
  test('eoq.holding_cost: rejects lower-bound violation', () {
    expect(run('eoq', {'holding_cost': 0}), isA<CalculationFailure>());
  });
  test('rop: independently typed example and assumptions', () {
    final o = run('rop');
    expect(primary(o), closeTo(250, 5e-8 + (250).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('rop.daily_demand: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('rop', {'daily_demand': v}), isA<CalculationFailure>());
    }
  });
  test('rop.daily_demand: rejects lower-bound violation', () {
    expect(run('rop', {'daily_demand': -1}), isA<CalculationFailure>());
  });
  test('rop.lead_time: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('rop', {'lead_time': v}), isA<CalculationFailure>());
    }
  });
  test('rop.lead_time: rejects lower-bound violation', () {
    expect(run('rop', {'lead_time': -1}), isA<CalculationFailure>());
  });
  test('rop.safety_stock: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('rop', {'safety_stock': v}), isA<CalculationFailure>());
    }
  });
  test('rop.safety_stock: rejects lower-bound violation', () {
    expect(run('rop', {'safety_stock': -1}), isA<CalculationFailure>());
  });
  test('safety_stock: independently typed example and assumptions', () {
    final o = run('safety_stock');
    expect(
      primary(o),
      closeTo(32.89707253902944, 5e-8 + (32.89707253902944).abs() * 5e-8),
    );
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test(
    'safety_stock.mean_demand: rejects NaN and both infinities directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('safety_stock', {'mean_demand': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('safety_stock.mean_demand: rejects lower-bound violation', () {
    expect(run('safety_stock', {'mean_demand': -1}), isA<CalculationFailure>());
  });
  test('safety_stock.demand_sd: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('safety_stock', {'demand_sd': v}), isA<CalculationFailure>());
    }
  });
  test('safety_stock.demand_sd: rejects lower-bound violation', () {
    expect(run('safety_stock', {'demand_sd': -1}), isA<CalculationFailure>());
  });
  test('safety_stock.mean_lead: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('safety_stock', {'mean_lead': v}), isA<CalculationFailure>());
    }
  });
  test('safety_stock.mean_lead: rejects lower-bound violation', () {
    expect(run('safety_stock', {'mean_lead': -1}), isA<CalculationFailure>());
  });
  test('safety_stock.lead_sd: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('safety_stock', {'lead_sd': v}), isA<CalculationFailure>());
    }
  });
  test('safety_stock.lead_sd: rejects lower-bound violation', () {
    expect(run('safety_stock', {'lead_sd': -1}), isA<CalculationFailure>());
  });
  test(
    'safety_stock.service_level: rejects NaN and both infinities directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('safety_stock', {'service_level': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('safety_stock.service_level: rejects lower-bound violation', () {
    expect(
      run('safety_stock', {'service_level': -0.5}),
      isA<CalculationFailure>(),
    );
  });
  test('safety_stock.service_level: rejects upper-bound violation', () {
    expect(
      run('safety_stock', {'service_level': 1}),
      isA<CalculationFailure>(),
    );
  });
  test('abc: independently typed example and assumptions', () {
    final o = run('abc');
    expect(primary(o), closeTo(10000, 5e-8 + (10000).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('abc.a_threshold: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('abc', {'a_threshold': v}), isA<CalculationFailure>());
    }
  });
  test('abc.a_threshold: rejects lower-bound violation', () {
    expect(run('abc', {'a_threshold': 0}), isA<CalculationFailure>());
  });
  test('abc.a_threshold: rejects upper-bound violation', () {
    expect(run('abc', {'a_threshold': 1}), isA<CalculationFailure>());
  });
  test('abc.b_threshold: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('abc', {'b_threshold': v}), isA<CalculationFailure>());
    }
  });
  test('abc.b_threshold: rejects lower-bound violation', () {
    expect(run('abc', {'b_threshold': 0}), isA<CalculationFailure>());
  });
  test('abc.b_threshold: rejects upper-bound violation', () {
    expect(run('abc', {'b_threshold': 2}), isA<CalculationFailure>());
  });
  test('inventory_turnover: independently typed example and assumptions', () {
    final o = run('inventory_turnover');
    expect(primary(o), closeTo(4, 5e-8 + (4).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('inventory_turnover.cogs: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('inventory_turnover', {'cogs': v}), isA<CalculationFailure>());
    }
  });
  test('inventory_turnover.cogs: rejects lower-bound violation', () {
    expect(run('inventory_turnover', {'cogs': -1}), isA<CalculationFailure>());
  });
  test('inventory_turnover.average_inventory: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('inventory_turnover', {'average_inventory': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'inventory_turnover.average_inventory: rejects lower-bound violation',
    () {
      expect(
        run('inventory_turnover', {'average_inventory': 0}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('days_inventory: independently typed example and assumptions', () {
    final o = run('days_inventory');
    expect(primary(o), closeTo(91.25, 5e-8 + (91.25).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test('days_inventory.average_inventory: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('days_inventory', {'average_inventory': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('days_inventory.average_inventory: rejects lower-bound violation', () {
    expect(
      run('days_inventory', {'average_inventory': -1}),
      isA<CalculationFailure>(),
    );
  });
  test('days_inventory.cogs: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('days_inventory', {'cogs': v}), isA<CalculationFailure>());
    }
  });
  test('days_inventory.cogs: rejects lower-bound violation', () {
    expect(run('days_inventory', {'cogs': 0}), isA<CalculationFailure>());
  });
  test(
    'days_inventory.period_days: rejects NaN and both infinities directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('days_inventory', {'period_days': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('days_inventory.period_days: rejects lower-bound violation', () {
    expect(
      run('days_inventory', {'period_days': 0}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'inventory_holding_cost: independently typed example and assumptions',
    () {
      final o = run('inventory_holding_cost');
      expect(primary(o), closeTo(50000, 5e-8 + (50000).abs() * 5e-8));
      expect(success(o).interpretation, isNotEmpty);
      expect(
        success(o).warnings.any((w) => w.code == 'method_assumptions'),
        isTrue,
      );
    },
  );
  test('inventory_holding_cost.average_value: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('inventory_holding_cost', {'average_value': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'inventory_holding_cost.average_value: rejects lower-bound violation',
    () {
      expect(
        run('inventory_holding_cost', {'average_value': -1}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('inventory_holding_cost.annual_rate: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('inventory_holding_cost', {'annual_rate': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('inventory_holding_cost.annual_rate: rejects lower-bound violation', () {
    expect(
      run('inventory_holding_cost', {'annual_rate': -1}),
      isA<CalculationFailure>(),
    );
  });
  test('inventory_holding_cost.period_days: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('inventory_holding_cost', {'period_days': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('inventory_holding_cost.period_days: rejects lower-bound violation', () {
    expect(
      run('inventory_holding_cost', {'period_days': -1}),
      isA<CalculationFailure>(),
    );
  });
  test('inventory_holding_cost.year_days: rejects NaN and both infinities directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('inventory_holding_cost', {'year_days': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('inventory_holding_cost.year_days: rejects lower-bound violation', () {
    expect(
      run('inventory_holding_cost', {'year_days': 0}),
      isA<CalculationFailure>(),
    );
  });
  test('reorder_interval: independently typed example and assumptions', () {
    final o = run('reorder_interval');
    expect(primary(o), closeTo(30, 5e-8 + (30).abs() * 5e-8));
    expect(success(o).interpretation, isNotEmpty);
    expect(
      success(o).warnings.any((w) => w.code == 'method_assumptions'),
      isTrue,
    );
  });
  test(
    'reorder_interval.order_quantity: rejects NaN and both infinities directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('reorder_interval', {'order_quantity': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('reorder_interval.order_quantity: rejects lower-bound violation', () {
    expect(
      run('reorder_interval', {'order_quantity': 0}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'reorder_interval.annual_demand: rejects NaN and both infinities directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('reorder_interval', {'annual_demand': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('reorder_interval.annual_demand: rejects lower-bound violation', () {
    expect(
      run('reorder_interval', {'annual_demand': 0}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'reorder_interval.year_days: rejects NaN and both infinities directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('reorder_interval', {'year_days': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('reorder_interval.year_days: rejects lower-bound violation', () {
    expect(
      run('reorder_interval', {'year_days': 0}),
      isA<CalculationFailure>(),
    );
  });
  final references = jsonDecode(
    File('test/fixtures/quality_inventory_reference.json').readAsStringSync(),
  ) as List<dynamic>;
  for (final id in defaults.keys) {
    test('$id: 20 independent Python Decimal/statistics references', () {
      final cases = references
          .cast<Map<String, dynamic>>()
          .where((r) => r['id'] == id)
          .toList();
      expect(cases, hasLength(20));
      for (final row in cases) {
        final o = typed(
          id,
          Map<String, Object?>.from(row['inputs'] as Map<String, dynamic>),
        );
        final expected = double.parse(row['expected'] as String);
        expect(primary(o), closeTo(expected, expected.abs() * 5e-8 + 5e-8));
        if (id == 'xbar_control') {
          for (final key in ['lcl', 'ucl']) {
            expect(
              metricValue(o, key),
              closeTo(double.parse(row[key] as String), 1e-10),
            );
          }
          for (final (key, reference) in [
            ('subgroup_means', 'means'),
            ('subgroup_ranges', 'ranges'),
          ]) {
            final actual = (detail(o, key) as NumberListResultValue).values,
                expected = (row[reference] as List<dynamic>)
                    .map((e) => double.parse(e as String))
                    .toList();
            expect(actual.length, expected.length);
            for (var i = 0; i < actual.length; i++) {
              expect(actual[i], closeTo(expected[i], 1e-10));
            }
          }
        }
        if (id == 'abc') {
          final classes = row['classes'] as Map<String, dynamic>;
          for (final entry in classes.entries) {
            expect(
              (detail(o, 'sku_${entry.key}_class') as TextResultValue).value,
              entry.value,
            );
          }
          final sorted = success(o).details
              .where((m) => m.id.endsWith('_class'))
              .map((m) => int.parse(m.id.split('_')[1]));
          expect(sorted, orderedEquals(row['order'] as List<dynamic>));
        }
      }
    });
  }
}
