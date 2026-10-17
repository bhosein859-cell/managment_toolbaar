import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  test('ahp: hand-checkable typed example and conditional interpretation', () {
    final o = run('ahp');
    expect(primary(o), closeTo(0.4, 1e-10 + (0.4).abs() * 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'conditional_decision'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test('ahp.alternatives: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('ahp', {'alternatives': v}), isA<CalculationFailure>());
    }
  });
  test('ahp.alternatives: lower bound and fractional count reject', () {
    expect(run('ahp', {'alternatives': -1}), isA<CalculationFailure>());
    expect(run('ahp', {'alternatives': 2.5}), isA<CalculationFailure>());
  });
  test('ahp.criteria: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('ahp', {'criteria': v}), isA<CalculationFailure>());
    }
  });
  test('ahp.criteria: lower bound and fractional count reject', () {
    expect(run('ahp', {'criteria': -1}), isA<CalculationFailure>());
    expect(run('ahp', {'criteria': 2.5}), isA<CalculationFailure>());
  });
  test(
    'topsis: hand-checkable typed example and conditional interpretation',
    () {
      final o = run('topsis');
      expect(primary(o), closeTo(0.6, 1e-10 + (0.6).abs() * 1e-10));
      expect(
        success(o).warnings.any((w) => w.code == 'conditional_decision'),
        isTrue,
      );
      expect(success(o).interpretation, isNotEmpty);
    },
  );
  test('topsis.alternatives: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('topsis', {'alternatives': v}), isA<CalculationFailure>());
    }
  });
  test('topsis.alternatives: lower bound and fractional count reject', () {
    expect(run('topsis', {'alternatives': -1}), isA<CalculationFailure>());
    expect(run('topsis', {'alternatives': 2.5}), isA<CalculationFailure>());
  });
  test('topsis.criteria: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('topsis', {'criteria': v}), isA<CalculationFailure>());
    }
  });
  test('topsis.criteria: lower bound and fractional count reject', () {
    expect(run('topsis', {'criteria': -1}), isA<CalculationFailure>());
    expect(run('topsis', {'criteria': 2.5}), isA<CalculationFailure>());
  });
  test('decision_matrix: hand-checkable typed example and conditional interpretation', () {
    final o = run('decision_matrix');
    expect(primary(o), closeTo(0.6, 1e-10 + (0.6).abs() * 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'conditional_decision'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test('decision_matrix.alternatives: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('decision_matrix', {'alternatives': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'decision_matrix.alternatives: lower bound and fractional count reject',
    () {
      expect(
        run('decision_matrix', {'alternatives': -1}),
        isA<CalculationFailure>(),
      );
      expect(
        run('decision_matrix', {'alternatives': 2.5}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('decision_matrix.criteria: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('decision_matrix', {'criteria': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('decision_matrix.criteria: lower bound and fractional count reject', () {
    expect(run('decision_matrix', {'criteria': -1}), isA<CalculationFailure>());
    expect(
      run('decision_matrix', {'criteria': 2.5}),
      isA<CalculationFailure>(),
    );
  });
  test('expected_value_tree: hand-checkable typed example and conditional interpretation', () {
    final o = run('expected_value_tree');
    expect(primary(o), closeTo(52, 1e-10 + (52).abs() * 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'conditional_decision'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test('expected_value_tree.root_id: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('expected_value_tree', {'root_id': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'expected_value_tree.root_id: lower bound and fractional count reject',
    () {
      expect(
        run('expected_value_tree', {'root_id': -1}),
        isA<CalculationFailure>(),
      );
      expect(
        run('expected_value_tree', {'root_id': 2.5}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('weight_sensitivity: hand-checkable typed example and conditional interpretation', () {
    final o = run('weight_sensitivity');
    expect(primary(o), closeTo(0.6, 1e-10 + (0.6).abs() * 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'conditional_decision'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test('weight_sensitivity.alternatives: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('weight_sensitivity', {'alternatives': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'weight_sensitivity.alternatives: lower bound and fractional count reject',
    () {
      expect(
        run('weight_sensitivity', {'alternatives': -1}),
        isA<CalculationFailure>(),
      );
      expect(
        run('weight_sensitivity', {'alternatives': 2.5}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('weight_sensitivity.criteria: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('weight_sensitivity', {'criteria': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'weight_sensitivity.criteria: lower bound and fractional count reject',
    () {
      expect(
        run('weight_sensitivity', {'criteria': -1}),
        isA<CalculationFailure>(),
      );
      expect(
        run('weight_sensitivity', {'criteria': 2.5}),
        isA<CalculationFailure>(),
      );
    },
  );
  test(
    'weight_sensitivity.selected_criterion: nonfinite input rejects directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('weight_sensitivity', {'selected_criterion': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('weight_sensitivity.selected_criterion: lower bound and fractional count reject', () {
    expect(
      run('weight_sensitivity', {'selected_criterion': -1}),
      isA<CalculationFailure>(),
    );
    expect(
      run('weight_sensitivity', {'selected_criterion': 2.5}),
      isA<CalculationFailure>(),
    );
  });
  test('weighted_scoring: hand-checkable typed example and conditional interpretation', () {
    final o = run('weighted_scoring');
    expect(primary(o), closeTo(7.8, 1e-10 + (7.8).abs() * 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'conditional_decision'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test('weighted_scoring.alternatives: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('weighted_scoring', {'alternatives': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'weighted_scoring.alternatives: lower bound and fractional count reject',
    () {
      expect(
        run('weighted_scoring', {'alternatives': -1}),
        isA<CalculationFailure>(),
      );
      expect(
        run('weighted_scoring', {'alternatives': 2.5}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('weighted_scoring.criteria: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('weighted_scoring', {'criteria': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'weighted_scoring.criteria: lower bound and fractional count reject',
    () {
      expect(
        run('weighted_scoring', {'criteria': -1}),
        isA<CalculationFailure>(),
      );
      expect(
        run('weighted_scoring', {'criteria': 2.5}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('cost_benefit_comparison: hand-checkable typed example and conditional interpretation', () {
    final o = run('cost_benefit_comparison');
    expect(primary(o), closeTo(30, 1e-10 + (30).abs() * 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'conditional_decision'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test('cost_benefit_comparison.cost_a: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('cost_benefit_comparison', {'cost_a': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'cost_benefit_comparison.cost_a: lower bound and fractional count reject',
    () {
      expect(
        run('cost_benefit_comparison', {'cost_a': -1}),
        isA<CalculationFailure>(),
      );
    },
  );
  test(
    'cost_benefit_comparison.benefit_a: nonfinite input rejects directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('cost_benefit_comparison', {'benefit_a': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('cost_benefit_comparison.benefit_a: lower bound and fractional count reject', () {
    expect(
      run('cost_benefit_comparison', {'benefit_a': -1}),
      isA<CalculationFailure>(),
    );
  });
  test('cost_benefit_comparison.cost_b: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('cost_benefit_comparison', {'cost_b': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'cost_benefit_comparison.cost_b: lower bound and fractional count reject',
    () {
      expect(
        run('cost_benefit_comparison', {'cost_b': -1}),
        isA<CalculationFailure>(),
      );
    },
  );
  test(
    'cost_benefit_comparison.benefit_b: nonfinite input rejects directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('cost_benefit_comparison', {'benefit_b': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('cost_benefit_comparison.benefit_b: lower bound and fractional count reject', () {
    expect(
      run('cost_benefit_comparison', {'benefit_b': -1}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'cost_benefit_comparison.period_days: nonfinite input rejects directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('cost_benefit_comparison', {'period_days': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('cost_benefit_comparison.period_days: lower bound and fractional count reject', () {
    expect(
      run('cost_benefit_comparison', {'period_days': -1}),
      isA<CalculationFailure>(),
    );
  });
  test('two_option_break_even: hand-checkable typed example and conditional interpretation', () {
    final o = run('two_option_break_even');
    expect(primary(o), closeTo(50, 1e-10 + (50).abs() * 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'conditional_decision'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test('two_option_break_even.fixed_a: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('two_option_break_even', {'fixed_a': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'two_option_break_even.fixed_a: lower bound and fractional count reject',
    () {
      expect(
        run('two_option_break_even', {'fixed_a': -1}),
        isA<CalculationFailure>(),
      );
    },
  );
  test(
    'two_option_break_even.variable_a: nonfinite input rejects directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('two_option_break_even', {'variable_a': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'two_option_break_even.variable_a: lower bound and fractional count reject',
    () {
      expect(
        run('two_option_break_even', {'variable_a': -1}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('two_option_break_even.fixed_b: nonfinite input rejects directly', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('two_option_break_even', {'fixed_b': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'two_option_break_even.fixed_b: lower bound and fractional count reject',
    () {
      expect(
        run('two_option_break_even', {'fixed_b': -1}),
        isA<CalculationFailure>(),
      );
    },
  );
  test(
    'two_option_break_even.variable_b: nonfinite input rejects directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('two_option_break_even', {'variable_b': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'two_option_break_even.variable_b: lower bound and fractional count reject',
    () {
      expect(
        run('two_option_break_even', {'variable_b': -1}),
        isA<CalculationFailure>(),
      );
    },
  );
  test(
    'two_option_break_even.period_days: nonfinite input rejects directly',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('two_option_break_even', {'period_days': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('two_option_break_even.period_days: lower bound and fractional count reject', () {
    expect(
      run('two_option_break_even', {'period_days': -1}),
      isA<CalculationFailure>(),
    );
  });
  final refs = jsonDecode(
    File('test/fixtures/decision_reference.json').readAsStringSync(),
  ) as List<dynamic>;
  for (final id in defaults.keys) {
    test(
      '$id: independent Decimal, AHP closed-form or enumerated-policy oracle',
      () {
        final rows = refs
            .cast<Map<String, dynamic>>()
            .where((r) => r['id'] == id)
            .toList();
        expect(rows, hasLength(id == 'ahp' ? 40 : 20));
        for (final r in rows) {
          final o = typed(
                id,
                Map<String, Object?>.from(r['inputs'] as Map<String, dynamic>),
              ),
              expected = double.parse(r['expected'] as String);
          expect(primary(o), closeTo(expected, expected.abs() * 1e-9 + 1e-10));
          for (final e in (r['details'] as Map<String, dynamic>).entries) {
            if (e.value is List) {
              final actual = series(o, e.key),
                  expected = (e.value as List<dynamic>)
                      .map((v) => double.parse(v as String))
                      .toList();
              expect(actual.length, expected.length);
              for (var i = 0; i < actual.length; i++) {
                expect(
                  actual[i],
                  closeTo(expected[i], expected[i].abs() * 1e-9 + 1e-10),
                );
              }
            } else {
              final expected = double.parse(e.value as String);
              expect(
                metricValue(o, e.key),
                closeTo(expected, expected.abs() * 1e-9 + 1e-10),
              );
            }
          }
        }
      },
    );
  }
}
