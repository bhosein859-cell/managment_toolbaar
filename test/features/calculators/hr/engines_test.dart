import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  test('cost_per_hire: typed golden example, context and no definitive performance label', () {
    final o = run('cost_per_hire');
    expect(primary(o), closeTo(10000000, 1e-10 + (10000000).abs() * 1e-10));
    expect(success(o).interpretation, contains('معیار قطعی'));
    expect(
      success(o).warnings.any((w) => w.code == 'descriptive_hr_only'),
      isTrue,
    );
    expect(metricValue(o, 'period_days'), 90);
  });
  test('cost_per_hire.internal_cost: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('cost_per_hire', {'internal_cost': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'internal_cost'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('cost_per_hire.external_cost: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('cost_per_hire', {'external_cost': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'external_cost'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('cost_per_hire.hires: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('cost_per_hire', {'hires': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'hires'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('cost_per_hire.hires: zero explicitly rejected', () {
    final o = run('cost_per_hire', {'hires': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'hires',
      ),
      isTrue,
    );
  });
  test('cost_per_hire.hires: fractional and excessive counts reject', () {
    for (final v in [0.5, 1000000001.0]) {
      expect(run('cost_per_hire', {'hires': v}), isA<CalculationFailure>());
    }
  });
  test('cost_per_hire.period_days: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('cost_per_hire', {'period_days': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'period_days'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('cost_per_hire.period_days: zero explicitly rejected', () {
    final o = run('cost_per_hire', {'period_days': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'period_days',
      ),
      isTrue,
    );
  });
  test('employee_turnover: typed golden example, context and no definitive performance label', () {
    final o = run('employee_turnover');
    expect(primary(o), closeTo(0.05, 1e-10 + (0.05).abs() * 1e-10));
    expect(success(o).interpretation, contains('معیار قطعی'));
    expect(
      success(o).warnings.any((w) => w.code == 'descriptive_hr_only'),
      isTrue,
    );
    expect(metricValue(o, 'period_days'), 90);
  });
  test('employee_turnover.separations: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('employee_turnover', {'separations': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'separations'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test(
    'employee_turnover.separations: fractional and excessive counts reject',
    () {
      for (final v in [0.5, 1000000001.0]) {
        expect(
          run('employee_turnover', {'separations': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('employee_turnover.opening_headcount: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('employee_turnover', {'opening_headcount': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'opening_headcount'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('employee_turnover.opening_headcount: fractional and excessive counts reject', () {
    for (final v in [0.5, 1000000001.0]) {
      expect(
        run('employee_turnover', {'opening_headcount': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('employee_turnover.closing_headcount: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('employee_turnover', {'closing_headcount': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'closing_headcount'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('employee_turnover.closing_headcount: fractional and excessive counts reject', () {
    for (final v in [0.5, 1000000001.0]) {
      expect(
        run('employee_turnover', {'closing_headcount': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('employee_turnover.period_days: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('employee_turnover', {'period_days': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'period_days'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('employee_turnover.period_days: zero explicitly rejected', () {
    final o =
        run('employee_turnover', {'period_days': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'period_days',
      ),
      isTrue,
    );
  });
  test('employee_productivity: typed golden example, context and no definitive performance label', () {
    final o = run('employee_productivity');
    expect(primary(o), closeTo(5, 1e-10 + (5).abs() * 1e-10));
    expect(success(o).interpretation, contains('معیار قطعی'));
    expect(
      success(o).warnings.any((w) => w.code == 'descriptive_hr_only'),
      isTrue,
    );
    expect(metricValue(o, 'period_days'), 90);
  });
  test('employee_productivity.output: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('employee_productivity', {'output': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'output'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('employee_productivity.worked_hours: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('employee_productivity', {'worked_hours': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'worked_hours'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('employee_productivity.worked_hours: zero explicitly rejected', () {
    final o =
        run('employee_productivity', {'worked_hours': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'worked_hours',
      ),
      isTrue,
    );
  });
  test('employee_productivity.period_days: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('employee_productivity', {'period_days': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'period_days'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('employee_productivity.period_days: zero explicitly rejected', () {
    final o =
        run('employee_productivity', {'period_days': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'period_days',
      ),
      isTrue,
    );
  });
  test('training_roi: typed golden example, context and no definitive performance label', () {
    final o = run('training_roi');
    expect(primary(o), closeTo(1, 1e-10 + (1).abs() * 1e-10));
    expect(success(o).interpretation, contains('معیار قطعی'));
    expect(
      success(o).warnings.any((w) => w.code == 'descriptive_hr_only'),
      isTrue,
    );
    expect(metricValue(o, 'period_days'), 90);
  });
  test('training_roi.gross_benefits: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('training_roi', {'gross_benefits': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'gross_benefits'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('training_roi.attribution_rate: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('training_roi', {'attribution_rate': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'attribution_rate'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('training_roi.training_cost: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('training_roi', {'training_cost': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'training_cost'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('training_roi.training_cost: zero explicitly rejected', () {
    final o = run('training_roi', {'training_cost': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'training_cost',
      ),
      isTrue,
    );
  });
  test('training_roi.period_days: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('training_roi', {'period_days': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'period_days'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('training_roi.period_days: zero explicitly rejected', () {
    final o = run('training_roi', {'period_days': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'period_days',
      ),
      isTrue,
    );
  });
  test('replacement_time: typed golden example, context and no definitive performance label', () {
    final o = run('replacement_time');
    expect(primary(o), closeTo(30, 1e-10 + (30).abs() * 1e-10));
    expect(success(o).interpretation, contains('معیار قطعی'));
    expect(
      success(o).warnings.any((w) => w.code == 'descriptive_hr_only'),
      isTrue,
    );
    expect(metricValue(o, 'period_days'), 90);
  });
  test('replacement_time.period_days: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('replacement_time', {'period_days': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'period_days'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('replacement_time.period_days: zero explicitly rejected', () {
    final o = run('replacement_time', {'period_days': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'period_days',
      ),
      isTrue,
    );
  });
  test('absence_cost: typed golden example, context and no definitive performance label', () {
    final o = run('absence_cost');
    expect(primary(o), closeTo(22000000, 1e-10 + (22000000).abs() * 1e-10));
    expect(success(o).interpretation, contains('معیار قطعی'));
    expect(
      success(o).warnings.any((w) => w.code == 'descriptive_hr_only'),
      isTrue,
    );
    expect(metricValue(o, 'period_days'), 90);
  });
  test('absence_cost.paid_absent_hours: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('absence_cost', {'paid_absent_hours': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'paid_absent_hours'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('absence_cost.loaded_hourly_cost: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('absence_cost', {'loaded_hourly_cost': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'loaded_hourly_cost'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('absence_cost.loaded_hourly_cost: zero explicitly rejected', () {
    final o =
        run('absence_cost', {'loaded_hourly_cost': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) =>
            i.code == 'positive_required' && i.fieldId == 'loaded_hourly_cost',
      ),
      isTrue,
    );
  });
  test('absence_cost.incremental_cover_cost: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('absence_cost', {'incremental_cover_cost': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'incremental_cover_cost'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('absence_cost.period_days: negative and nonfinite direct inputs give Persian field errors', () {
    for (final v in [
      -1.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final o = run('absence_cost', {'period_days': v});
      expect(o, isA<CalculationFailure>());
      final issues = (o as CalculationFailure).issues;
      expect(issues.any((i) => i.fieldId == 'period_days'), isTrue);
      expect(issues.every((i) => RegExp('[آ-ی]').hasMatch(i.message)), isTrue);
    }
  });
  test('absence_cost.period_days: zero explicitly rejected', () {
    final o = run('absence_cost', {'period_days': 0}) as CalculationFailure;
    expect(
      o.issues.any(
        (i) => i.code == 'positive_required' && i.fieldId == 'period_days',
      ),
      isTrue,
    );
  });
  final references = jsonDecode(
    File('test/fixtures/hr_reference.json').readAsStringSync(),
  ) as List<dynamic>;
  for (final id in defaults.keys) {
    test('$id: 20 independent Decimal references and all supplied details', () {
      final rows = references
          .cast<Map<String, dynamic>>()
          .where((r) => r['id'] == id)
          .toList();
      expect(rows, hasLength(20));
      for (final r in rows) {
        final o = typed(
          id,
          Map<String, Object?>.from(r['inputs'] as Map<String, dynamic>),
        );
        final expected = double.parse(r['expected'] as String);
        expect(primary(o), closeTo(expected, expected.abs() * 1e-10 + 1e-10));
        for (final e in (r['details'] as Map<String, dynamic>).entries) {
          final expected = double.parse(e.value as String);
          expect(
            metricValue(o, e.key),
            closeTo(expected, expected.abs() * 1e-10 + 1e-10),
          );
        }
      }
    });
  }
}
