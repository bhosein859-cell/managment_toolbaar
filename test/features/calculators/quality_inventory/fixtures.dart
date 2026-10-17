import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/abc_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/days_inventory_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/eoq_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/inventory_holding_cost_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/inventory_turnover_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/reorder_interval_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/rop_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/inventory/safety_stock_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/coq_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/cpk_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/dpmo_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/pp_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/ppk_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/sigma_level_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/quality/xbar_control_engine.dart';

double number(Map<String, Object?> v, String id) {
  final x = v[id]!;
  return x is num ? x.toDouble() : double.parse(x as String);
}

List<double> numbers(Map<String, Object?> v, String id) =>
    (v[id] as List<Object?>)
        .map((x) => x is num ? x.toDouble() : double.parse(x as String))
        .toList();
CalculationOutcome typed(String id, Map<String, Object?> v) => switch (id) {
  'cpk' => const CpkEngine().calculate(
    CpkParameters(
      usl: number(v, 'usl'),
      lsl: number(v, 'lsl'),
      mean: number(v, 'mean'),
      sigma: number(v, 'sigma'),
    ),
  ),
  'pp' => const PpEngine().calculate(
    PpParameters(
      usl: number(v, 'usl'),
      lsl: number(v, 'lsl'),
      sigma: number(v, 'sigma'),
    ),
  ),
  'ppk' => const PpkEngine().calculate(
    PpkParameters(
      usl: number(v, 'usl'),
      lsl: number(v, 'lsl'),
      mean: number(v, 'mean'),
      sigma: number(v, 'sigma'),
    ),
  ),
  'dpmo' => const DpmoEngine().calculate(
    DpmoParameters(
      defects: number(v, 'defects'),
      units: number(v, 'units'),
      opportunities: number(v, 'opportunities'),
    ),
  ),
  'sigma_level' => const SigmaLevelEngine().calculate(
    SigmaLevelParameters(
      dpmo: number(v, 'dpmo'),
      shift: v['shift'] == 'none' ? SigmaShift.none : SigmaShift.convention15,
    ),
  ),
  'xbar_control' => const XbarControlEngine().calculate(
    XbarControlParameters(
      subgroupSize: number(v, 'subgroup_size'),
      observations: numbers(v, 'observations'),
    ),
  ),
  'coq' => const CoqEngine().calculate(
    CoqParameters(
      prevention: number(v, 'prevention'),
      appraisal: number(v, 'appraisal'),
      internalFailure: number(v, 'internal_failure'),
      externalFailure: number(v, 'external_failure'),
    ),
  ),
  'eoq' => const EoqEngine().calculate(
    EoqParameters(
      annualDemand: number(v, 'annual_demand'),
      orderCost: number(v, 'order_cost'),
      holdingCost: number(v, 'holding_cost'),
    ),
  ),
  'rop' => const RopEngine().calculate(
    RopParameters(
      dailyDemand: number(v, 'daily_demand'),
      leadTime: number(v, 'lead_time'),
      safetyStock: number(v, 'safety_stock'),
    ),
  ),
  'safety_stock' => const SafetyStockEngine().calculate(
    SafetyStockParameters(
      meanDemand: number(v, 'mean_demand'),
      demandSd: number(v, 'demand_sd'),
      meanLead: number(v, 'mean_lead'),
      leadSd: number(v, 'lead_sd'),
      serviceLevel: number(v, 'service_level'),
    ),
  ),
  'abc' => const AbcEngine().calculate(
    AbcParameters(
      annualQuantities: numbers(v, 'annual_quantities'),
      unitCosts: numbers(v, 'unit_costs'),
      aThreshold: number(v, 'a_threshold'),
      bThreshold: number(v, 'b_threshold'),
    ),
  ),
  'inventory_turnover' => const InventoryTurnoverEngine().calculate(
    InventoryTurnoverParameters(
      cogs: number(v, 'cogs'),
      averageInventory: number(v, 'average_inventory'),
    ),
  ),
  'days_inventory' => const DaysInventoryEngine().calculate(
    DaysInventoryParameters(
      averageInventory: number(v, 'average_inventory'),
      cogs: number(v, 'cogs'),
      periodDays: number(v, 'period_days'),
    ),
  ),
  'inventory_holding_cost' => const InventoryHoldingCostEngine().calculate(
    InventoryHoldingCostParameters(
      averageValue: number(v, 'average_value'),
      annualRate: number(v, 'annual_rate'),
      periodDays: number(v, 'period_days'),
      yearDays: number(v, 'year_days'),
    ),
  ),
  'reorder_interval' => const ReorderIntervalEngine().calculate(
    ReorderIntervalParameters(
      orderQuantity: number(v, 'order_quantity'),
      annualDemand: number(v, 'annual_demand'),
      yearDays: number(v, 'year_days'),
    ),
  ),
  _ => throw ArgumentError(id),
};
final defaults = <String, Map<String, Object?>>{
  'cpk': {'usl': 10, 'lsl': 4, 'mean': 7, 'sigma': 1},
  'pp': {'usl': 10, 'lsl': 4, 'sigma': 2},
  'ppk': {'usl': 10, 'lsl': 4, 'mean': 8, 'sigma': 2},
  'dpmo': {'defects': 10, 'units': 1000, 'opportunities': 10},
  'sigma_level': {'dpmo': 1000, 'shift': 'none'},
  'xbar_control': {
    'subgroup_size': 5,
    'observations': [8, 9, 10, 11, 12, 9, 10, 11, 12, 13, 10, 11, 12, 13, 14],
  },
  'coq': {
    'prevention': 100,
    'appraisal': 200,
    'internal_failure': 300,
    'external_failure': 400,
  },
  'eoq': {'annual_demand': 10000, 'order_cost': 100, 'holding_cost': 2},
  'rop': {'daily_demand': 40, 'lead_time': 5, 'safety_stock': 50},
  'safety_stock': {
    'mean_demand': 40,
    'demand_sd': 10,
    'mean_lead': 4,
    'lead_sd': 0,
    'service_level': 0.95,
  },
  'abc': {
    'annual_quantities': [100, 100, 100, 100, 100],
    'unit_costs': [70, 15, 8, 5, 2],
    'a_threshold': 0.8,
    'b_threshold': 0.95,
  },
  'inventory_turnover': {'cogs': 1200000, 'average_inventory': 300000},
  'days_inventory': {
    'average_inventory': 300000,
    'cogs': 1200000,
    'period_days': 365,
  },
  'inventory_holding_cost': {
    'average_value': 1000000,
    'annual_rate': 0.2,
    'period_days': 90,
    'year_days': 360,
  },
  'reorder_interval': {
    'order_quantity': 1000,
    'annual_demand': 12000,
    'year_days': 360,
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
CalculationOutcome run(
  String id, [
  Map<String, Object?> overrides = const {},
]) => typed(id, {...defaults[id]!, ...overrides});
