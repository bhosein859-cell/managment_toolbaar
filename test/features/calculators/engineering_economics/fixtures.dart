import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/annuity_future_factor_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/annuity_present_factor_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/declining_balance_depreciation_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/future_annuity_factor_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/future_present_factor_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/inflation_adjustment_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/present_annuity_factor_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/present_future_factor_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/straight_line_depreciation_engine.dart';
import 'package:management_toolbox/features/calculators/domain/engines/engineering_economics/time_value_money_engine.dart';

double number(Map<String, Object?> v, String id) {
  final x = v[id]!;
  return x is num ? x.toDouble() : double.parse(x as String);
}

CalculationOutcome typed(String id, Map<String, Object?> v) => switch (id) {
  'time_value_money' => const TimeValueMoneyEngine().calculate(
    TimeValueMoneyParameters(
      amount: number(v, 'amount'),
      rate: number(v, 'rate'),
      periods: number(v, 'periods'),
    ),
  ),
  'future_present_factor' => const FuturePresentFactorEngine().calculate(
    FuturePresentFactorParameters(
      amount: number(v, 'amount'),
      rate: number(v, 'rate'),
      periods: number(v, 'periods'),
    ),
  ),
  'present_future_factor' => const PresentFutureFactorEngine().calculate(
    PresentFutureFactorParameters(
      amount: number(v, 'amount'),
      rate: number(v, 'rate'),
      periods: number(v, 'periods'),
    ),
  ),
  'future_annuity_factor' => const FutureAnnuityFactorEngine().calculate(
    FutureAnnuityFactorParameters(
      amount: number(v, 'amount'),
      rate: number(v, 'rate'),
      periods: number(v, 'periods'),
    ),
  ),
  'annuity_future_factor' => const AnnuityFutureFactorEngine().calculate(
    AnnuityFutureFactorParameters(
      amount: number(v, 'amount'),
      rate: number(v, 'rate'),
      periods: number(v, 'periods'),
    ),
  ),
  'present_annuity_factor' => const PresentAnnuityFactorEngine().calculate(
    PresentAnnuityFactorParameters(
      amount: number(v, 'amount'),
      rate: number(v, 'rate'),
      periods: number(v, 'periods'),
    ),
  ),
  'annuity_present_factor' => const AnnuityPresentFactorEngine().calculate(
    AnnuityPresentFactorParameters(
      amount: number(v, 'amount'),
      rate: number(v, 'rate'),
      periods: number(v, 'periods'),
    ),
  ),
  'straight_line_depreciation' =>
    const StraightLineDepreciationEngine().calculate(
      StraightLineDepreciationParameters(
        cost: number(v, 'cost'),
        salvage: number(v, 'salvage'),
        life: number(v, 'life'),
        year: number(v, 'year'),
      ),
    ),
  'declining_balance_depreciation' =>
    const DecliningBalanceDepreciationEngine().calculate(
      DecliningBalanceDepreciationParameters(
        cost: number(v, 'cost'),
        salvage: number(v, 'salvage'),
        depreciationRate: number(v, 'depreciation_rate'),
        life: number(v, 'life'),
        year: number(v, 'year'),
      ),
    ),
  'inflation_adjustment' => const InflationAdjustmentEngine().calculate(
    InflationAdjustmentParameters(
      amount: number(v, 'amount'),
      rate: number(v, 'rate'),
      periods: number(v, 'periods'),
    ),
  ),
  _ => throw ArgumentError(id),
};
final defaults = <String, Map<String, Object?>>{
  'time_value_money': {'amount': 1000, 'rate': 0.1, 'periods': 3},
  'future_present_factor': {'amount': 1000, 'rate': 0.1, 'periods': 3},
  'present_future_factor': {'amount': 1000, 'rate': 0.1, 'periods': 3},
  'future_annuity_factor': {'amount': 1000, 'rate': 0.1, 'periods': 3},
  'annuity_future_factor': {'amount': 1000, 'rate': 0.1, 'periods': 3},
  'present_annuity_factor': {'amount': 1000, 'rate': 0.1, 'periods': 3},
  'annuity_present_factor': {'amount': 1000, 'rate': 0.1, 'periods': 3},
  'straight_line_depreciation': {
    'cost': 1000,
    'salvage': 100,
    'life': 5,
    'year': 2,
  },
  'declining_balance_depreciation': {
    'cost': 1000,
    'salvage': 100,
    'depreciation_rate': 0.2,
    'life': 5,
    'year': 2,
  },
  'inflation_adjustment': {'amount': 1000, 'rate': 0.1, 'periods': 3},
};
CalculationOutcome run(String id, [Map<String, Object?> values = const {}]) =>
    typed(id, {...defaults[id]!, ...values});
CalculationResult success(CalculationOutcome o) =>
    (o as CalculationSuccess).result;
double primary(CalculationOutcome o) =>
    (success(o).primary.value as NumericResultValue).value;
double metricValue(CalculationOutcome o, String id) =>
    (success(o).details.singleWhere((m) => m.id == id).value
            as NumericResultValue)
        .value;
void fails(String id, Map<String, Object?> values, [String? code]) {
  final o = run(id, values);
  if (o is! CalculationFailure) {
    throw StateError('Expected failure: $id $values');
  }
  if (code != null && !o.issues.any((i) => i.code == code)) {
    throw StateError('Expected $code: ${o.issues.map((i) => i.code)}');
  }
}
