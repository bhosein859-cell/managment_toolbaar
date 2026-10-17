import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/hr_calculators.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/hr/replacement_time_engine.dart';

import 'fixtures.dart';

void fails(String id, Map<String, Object?> values, [String? code]) {
  final o = run(id, values);
  expect(o, isA<CalculationFailure>());
  if (code != null) {
    expect((o as CalculationFailure).issues.any((i) => i.code == code), isTrue);
  }
}

void main() {
  test('CPH zero observed costs is legitimate, zero hires is undefined', () {
    expect(
      primary(run('cost_per_hire', {'internal_cost': 0, 'external_cost': 0})),
      0,
    );
    fails('cost_per_hire', {'hires': 0}, 'positive_required');
    expect(primary(run('cost_per_hire', {'hires': 6})), 5000000);
    fails('cost_per_hire', {
      'internal_cost': 1e308,
      'external_cost': 1e308,
    }, 'numeric_range');
    fails('cost_per_hire', {
      'internal_cost': 5e-324,
      'external_cost': 0,
      'hires': 3,
    }, 'numeric_range');
  });
  test(
    'Turnover endpoints approximation, zero exits and >100 percent not clipped',
    () {
      expect(primary(run('employee_turnover', {'separations': 0})), 0);
      expect(
        primary(
          run('employee_turnover', {
            'opening_headcount': 0,
            'closing_headcount': 10,
            'separations': 10,
          }),
        ),
        2,
      );
      expect(
        primary(
          run('employee_turnover', {
            'opening_headcount': 10,
            'closing_headcount': 0,
            'separations': 10,
          }),
        ),
        2,
      );
      fails('employee_turnover', {
        'opening_headcount': 0,
        'closing_headcount': 0,
      }, 'zero_average_headcount');
      final o = run('employee_turnover', {
        'opening_headcount': 1,
        'closing_headcount': 2,
        'separations': 1,
      });
      expect(metricValue(o, 'average_headcount'), 1.5);
      expect(primary(o), closeTo(2 / 3, 1e-15));
    },
  );
  test('Productivity: fractional standardized output, zero output and positive denominator', () {
    expect(primary(run('employee_productivity', {'output': 0})), 0);
    expect(
      primary(
        run('employee_productivity', {'output': 1.5, 'worked_hours': 0.5}),
      ),
      3,
    );
    fails('employee_productivity', {'worked_hours': 0}, 'positive_required');
    fails('employee_productivity', {
      'output': 1e308,
      'worked_hours': 1e-308,
    }, 'numeric_range');
    fails('employee_productivity', {
      'output': 1e-308,
      'worked_hours': 1e308,
    }, 'numeric_range');
  });
  test('Training ROI: attribution, break-even, loss and no clamping', () {
    final o = run('training_roi');
    expect(primary(o), 1);
    expect(metricValue(o, 'attributed_benefit'), 20000000);
    expect(metricValue(o, 'net_benefit'), 10000000);
    expect(primary(run('training_roi', {'attribution_rate': 1})), 3);
    expect(primary(run('training_roi', {'attribution_rate': 0})), -1);
    expect(primary(run('training_roi', {'gross_benefits': 0})), -1);
    expect(
      primary(
        run('training_roi', {
          'gross_benefits': 10000000,
          'attribution_rate': 1,
        }),
      ),
      0,
    );
    fails('training_roi', {'attribution_rate': 1.01}, 'above_hr_max');
    fails('training_roi', {'training_cost': 0}, 'positive_required');
  });
  test(
    'Training ROI: numerical extremes, percentage display remains fractional',
    () {
      fails('training_roi', {
        'gross_benefits': 1e308,
        'attribution_rate': 1,
        'training_cost': 1e-308,
      }, 'numeric_range');
      fails('training_roi', {
        'gross_benefits': 1e-300,
        'attribution_rate': 1e-300,
      }, 'numeric_range');
      final o = run('training_roi', {
        'gross_benefits': 1e308,
        'attribution_rate': 1,
        'training_cost': 1e308,
      });
      expect(primary(o), 0);
      expect(
        (success(o).primary.value as NumericResultValue).display,
        NumberDisplay.percentage,
      );
    },
  );
  test('Replacement: exact list denominator, same-day zero, subday and old vacancies', () {
    for (final days in [
      [0.0],
      [1.5, 2.5],
      [100.0, 200.0, 300.0],
    ]) {
      final o = run('replacement_time', {
        'elapsed_days': days,
        'period_days': 30,
      });
      expect(primary(o), days.reduce((a, b) => a + b) / days.length);
      expect(metricValue(o, 'completed_replacements'), days.length);
    }
    expect(
      primary(run('replacement_time', {'elapsed_days': List.filled(1000, 1)})),
      1,
    );
  });
  test(
    'Replacement: empty, oversized, negative/nonfinite items reject with row',
    () {
      for (final items in [<double>[], List.filled(1001, 1.0)]) {
        fails('replacement_time', {'elapsed_days': items}, 'replacement_count');
      }
      for (final v in [
        -1.0,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final o = run('replacement_time', {
          'elapsed_days': [1, v],
        }) as CalculationFailure;
        expect(o.issues.single.itemIndex, 1);
        expect(o.issues.single.fieldId, 'elapsed_days');
      }
      fails('replacement_time', {
        'elapsed_days': [1e308, 1e308],
      }, 'numeric_range');
      fails('replacement_time', {
        'elapsed_days': [5e-324, 0, 0],
      }, 'numeric_range');
    },
  );
  test('Replacement list snapshots immutable', () {
    final days = [20.0, 30.0];
    final p = ReplacementTimeParameters(elapsedDays: days, periodDays: 90);
    days.clear();
    expect(p.elapsedDays, [20, 30]);
    expect(() => p.elapsedDays.clear(), throwsUnsupportedError);
  });
  test(
    'Absence direct model identity, zero absence and incompatible cover',
    () {
      final o = run('absence_cost');
      expect(primary(o), 22000000);
      expect(metricValue(o, 'paid_absence_cost'), 20000000);
      expect(metricValue(o, 'additional_cover_cost'), 2000000);
      expect(
        primary(
          run('absence_cost', {
            'paid_absent_hours': 0,
            'incremental_cover_cost': 0,
          }),
        ),
        0,
      );
      fails('absence_cost', {'paid_absent_hours': 0}, 'cover_without_absence');
      fails('absence_cost', {'loaded_hourly_cost': 0}, 'positive_required');
      fails('absence_cost', {
        'paid_absent_hours': 1e308,
        'loaded_hourly_cost': 10,
      }, 'numeric_range');
      fails('absence_cost', {
        'paid_absent_hours': 1e-300,
        'loaded_hourly_cost': 1e-300,
      }, 'numeric_range');
      fails('absence_cost', {
        'paid_absent_hours': 1,
        'loaded_hourly_cost': 1e308,
        'incremental_cover_cost': 1e308,
      }, 'numeric_range');
    },
  );
  test('Observed zero warning is not a definitive good/bad label', () {
    final o = run('employee_productivity', {'output': 0});
    expect(success(o).warnings.any((w) => w.code == 'observed_zero'), isTrue);
    expect(
      success(o).warnings.any((w) => w.code == 'descriptive_hr_only'),
      isTrue,
    );
  });
  test('Strict missing-field policy is opt-in; existing default contract preserved', () {
    expect(
      PrototypeCalculators.oeeRunner.run(RawCalculatorInput({})),
      isA<CalculationSuccess>(),
    );
    expect(
      HrCalculators.costPerHireRunner.run(RawCalculatorInput({})),
      isA<CalculationFailure>(),
    );
    final d = HrCalculators.costPerHire;
    expect(
      const InputNormalizer().normalize(d, RawCalculatorInput({})),
      isA<NormalizedInput>(),
    );
    expect(
      const InputNormalizer(requireExplicitFields: true)
          .normalize(d, RawCalculatorInput({})),
      isA<InvalidInput>(),
    );
  });
}
