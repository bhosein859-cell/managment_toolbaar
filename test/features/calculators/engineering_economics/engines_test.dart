import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  test('time_value_money: known typed example and explicit method', () {
    final o = run('time_value_money');
    expect(primary(o), closeTo(1331, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'educational_economics'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test(
    'time_value_money.amount: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('time_value_money', {'amount': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('time_value_money.amount: negative financial input rejects', () {
    expect(
      run('time_value_money', {'amount': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test('time_value_money.rate: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(run('time_value_money', {'rate': v}), isA<CalculationFailure>());
    }
  });
  test(
    'time_value_money.periods: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('time_value_money', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'time_value_money.periods: fractional, negative and too large reject',
    () {
      for (final v in [-1, 0.5, 10001]) {
        expect(
          run('time_value_money', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('future_present_factor: known typed example and explicit method', () {
    final o = run('future_present_factor');
    expect(primary(o), closeTo(1.331, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'educational_economics'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test(
    'future_present_factor.amount: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('future_present_factor', {'amount': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('future_present_factor.amount: negative financial input rejects', () {
    expect(
      run('future_present_factor', {'amount': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'future_present_factor.rate: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('future_present_factor', {'rate': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'future_present_factor.periods: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('future_present_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'future_present_factor.periods: fractional, negative and too large reject',
    () {
      for (final v in [-1, 0.5, 10001]) {
        expect(
          run('future_present_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('present_future_factor: known typed example and explicit method', () {
    final o = run('present_future_factor');
    expect(primary(o), closeTo(0.7513148009015778, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'educational_economics'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test(
    'present_future_factor.amount: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('present_future_factor', {'amount': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('present_future_factor.amount: negative financial input rejects', () {
    expect(
      run('present_future_factor', {'amount': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'present_future_factor.rate: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('present_future_factor', {'rate': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'present_future_factor.periods: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('present_future_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'present_future_factor.periods: fractional, negative and too large reject',
    () {
      for (final v in [-1, 0.5, 10001]) {
        expect(
          run('present_future_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('future_annuity_factor: known typed example and explicit method', () {
    final o = run('future_annuity_factor');
    expect(primary(o), closeTo(3.31, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'educational_economics'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test(
    'future_annuity_factor.amount: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('future_annuity_factor', {'amount': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('future_annuity_factor.amount: negative financial input rejects', () {
    expect(
      run('future_annuity_factor', {'amount': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'future_annuity_factor.rate: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('future_annuity_factor', {'rate': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'future_annuity_factor.periods: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('future_annuity_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'future_annuity_factor.periods: fractional, negative and too large reject',
    () {
      for (final v in [-1, 0.5, 10001]) {
        expect(
          run('future_annuity_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('annuity_future_factor: known typed example and explicit method', () {
    final o = run('annuity_future_factor');
    expect(primary(o), closeTo(0.3021148036253776, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'educational_economics'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test(
    'annuity_future_factor.amount: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('annuity_future_factor', {'amount': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('annuity_future_factor.amount: negative financial input rejects', () {
    expect(
      run('annuity_future_factor', {'amount': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'annuity_future_factor.rate: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('annuity_future_factor', {'rate': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'annuity_future_factor.periods: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('annuity_future_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'annuity_future_factor.periods: fractional, negative and too large reject',
    () {
      for (final v in [-1, 0.5, 10001]) {
        expect(
          run('annuity_future_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('present_annuity_factor: known typed example and explicit method', () {
    final o = run('present_annuity_factor');
    expect(primary(o), closeTo(2.4868519909842224, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'educational_economics'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test(
    'present_annuity_factor.amount: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('present_annuity_factor', {'amount': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('present_annuity_factor.amount: negative financial input rejects', () {
    expect(
      run('present_annuity_factor', {'amount': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'present_annuity_factor.rate: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('present_annuity_factor', {'rate': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'present_annuity_factor.periods: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('present_annuity_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'present_annuity_factor.periods: fractional, negative and too large reject',
    () {
      for (final v in [-1, 0.5, 10001]) {
        expect(
          run('present_annuity_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('annuity_present_factor: known typed example and explicit method', () {
    final o = run('annuity_present_factor');
    expect(primary(o), closeTo(0.4021148036253776, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'educational_economics'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test(
    'annuity_present_factor.amount: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('annuity_present_factor', {'amount': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('annuity_present_factor.amount: negative financial input rejects', () {
    expect(
      run('annuity_present_factor', {'amount': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'annuity_present_factor.rate: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('annuity_present_factor', {'rate': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'annuity_present_factor.periods: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('annuity_present_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'annuity_present_factor.periods: fractional, negative and too large reject',
    () {
      for (final v in [-1, 0.5, 10001]) {
        expect(
          run('annuity_present_factor', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'straight_line_depreciation: known typed example and explicit method',
    () {
      final o = run('straight_line_depreciation');
      expect(primary(o), closeTo(180, 1e-10));
      expect(
        success(o).warnings.any((w) => w.code == 'educational_economics'),
        isTrue,
      );
      expect(success(o).interpretation, isNotEmpty);
    },
  );
  test('straight_line_depreciation.cost: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('straight_line_depreciation', {'cost': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('straight_line_depreciation.cost: negative financial input rejects', () {
    expect(
      run('straight_line_depreciation', {'cost': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test('straight_line_depreciation.salvage: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('straight_line_depreciation', {'salvage': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'straight_line_depreciation.salvage: negative financial input rejects',
    () {
      expect(
        run('straight_line_depreciation', {'salvage': -0.01}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('straight_line_depreciation.life: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('straight_line_depreciation', {'life': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('straight_line_depreciation.life: fractional, negative and too large reject', () {
    for (final v in [-1, 0.5, 10001]) {
      expect(
        run('straight_line_depreciation', {'life': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('straight_line_depreciation.year: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('straight_line_depreciation', {'year': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('straight_line_depreciation.year: fractional, negative and too large reject', () {
    for (final v in [-1, 0.5, 10001]) {
      expect(
        run('straight_line_depreciation', {'year': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'declining_balance_depreciation: known typed example and explicit method',
    () {
      final o = run('declining_balance_depreciation');
      expect(primary(o), closeTo(160, 1e-10));
      expect(
        success(o).warnings.any((w) => w.code == 'educational_economics'),
        isTrue,
      );
      expect(success(o).interpretation, isNotEmpty);
    },
  );
  test('declining_balance_depreciation.cost: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('declining_balance_depreciation', {'cost': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'declining_balance_depreciation.cost: negative financial input rejects',
    () {
      expect(
        run('declining_balance_depreciation', {'cost': -0.01}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('declining_balance_depreciation.salvage: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('declining_balance_depreciation', {'salvage': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test(
    'declining_balance_depreciation.salvage: negative financial input rejects',
    () {
      expect(
        run('declining_balance_depreciation', {'salvage': -0.01}),
        isA<CalculationFailure>(),
      );
    },
  );
  test('declining_balance_depreciation.depreciation_rate: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('declining_balance_depreciation', {'depreciation_rate': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('declining_balance_depreciation.depreciation_rate: negative financial input rejects', () {
    expect(
      run('declining_balance_depreciation', {'depreciation_rate': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test('declining_balance_depreciation.life: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('declining_balance_depreciation', {'life': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('declining_balance_depreciation.life: fractional, negative and too large reject', () {
    for (final v in [-1, 0.5, 10001]) {
      expect(
        run('declining_balance_depreciation', {'life': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('declining_balance_depreciation.year: NaN and infinity reject at typed boundary', () {
    for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
      expect(
        run('declining_balance_depreciation', {'year': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('declining_balance_depreciation.year: fractional, negative and too large reject', () {
    for (final v in [-1, 0.5, 10001]) {
      expect(
        run('declining_balance_depreciation', {'year': v}),
        isA<CalculationFailure>(),
      );
    }
  });
  test('inflation_adjustment: known typed example and explicit method', () {
    final o = run('inflation_adjustment');
    expect(primary(o), closeTo(751.3148009015778, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'educational_economics'),
      isTrue,
    );
    expect(success(o).interpretation, isNotEmpty);
  });
  test(
    'inflation_adjustment.amount: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('inflation_adjustment', {'amount': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test('inflation_adjustment.amount: negative financial input rejects', () {
    expect(
      run('inflation_adjustment', {'amount': -0.01}),
      isA<CalculationFailure>(),
    );
  });
  test(
    'inflation_adjustment.rate: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('inflation_adjustment', {'rate': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'inflation_adjustment.periods: NaN and infinity reject at typed boundary',
    () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        expect(
          run('inflation_adjustment', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  test(
    'inflation_adjustment.periods: fractional, negative and too large reject',
    () {
      for (final v in [-1, 0.5, 10001]) {
        expect(
          run('inflation_adjustment', {'periods': v}),
          isA<CalculationFailure>(),
        );
      }
    },
  );
  final refs = jsonDecode(
    File('test/fixtures/engineering_economics_reference.json')
        .readAsStringSync(),
  ) as List<dynamic>;
  for (final id in defaults.keys) {
    test('$id: forty independent Decimal sums or ledger references', () {
      final rows = refs
          .cast<Map<String, dynamic>>()
          .where((v) => v['id'] == id)
          .toList();
      expect(rows, hasLength(40));
      for (final r in rows) {
        final o = typed(
              id,
              Map<String, Object?>.from(r['inputs'] as Map<String, dynamic>),
            ),
            expected = double.parse(r['expected'] as String);
        expect(primary(o), closeTo(expected, expected.abs() * 1e-10 + 1e-100));
        for (final e in (r['details'] as Map<String, dynamic>).entries) {
          final expected = double.parse(e.value as String);
          expect(
            metricValue(o, e.key),
            closeTo(expected, expected.abs() * 1e-10 + 1e-100),
          );
        }
      }
    });
  }
}
