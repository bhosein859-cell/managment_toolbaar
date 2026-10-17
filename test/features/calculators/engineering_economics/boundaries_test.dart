import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

const factors = [
  'future_present_factor',
  'present_future_factor',
  'future_annuity_factor',
  'annuity_future_factor',
  'present_annuity_factor',
  'annuity_present_factor',
];
void main() {
  for (final id in ['time_value_money', ...factors, 'inflation_adjustment']) {
    test('$id: rate at/below minus 100 percent is impossible', () {
      for (final rate in [-1, -1.01, -100]) {
        fails(id, {'rate': rate}, 'invalid_number');
      }
    });
    test(
      '$id: negative rates above minus one, zero amounts and zero rate are supported',
      () {
        expect(run(id, {'rate': -0.5}), isA<CalculationSuccess>());
        expect(run(id, {'amount': 0}), isA<CalculationSuccess>());
        expect(run(id, {'rate': 0}), isA<CalculationSuccess>());
      },
    );
  }
  test('All six zero-rate factor limits are explicit', () {
    for (final n in [1, 2, 30, 10000]) {
      for (final id in factors) {
        final expected =
            id == 'future_present_factor' || id == 'present_future_factor'
            ? 1.0
            : id == 'future_annuity_factor' || id == 'present_annuity_factor'
            ? n.toDouble()
            : 1 / n;
        expect(
          primary(run(id, {'periods': n, 'rate': 0})),
          closeTo(expected, expected * 1e-12),
        );
      }
    }
  });
  test('Zero periods: same-time single sums, empty annuities, undefined inverse annuities', () {
    for (final id in ['time_value_money', 'inflation_adjustment']) {
      expect(primary(run(id, {'periods': 0})), 1000);
    }
    for (final id in ['future_present_factor', 'present_future_factor']) {
      expect(primary(run(id, {'periods': 0})), 1);
    }
    for (final id in ['future_annuity_factor', 'present_annuity_factor']) {
      final o = run(id, {'periods': 0});
      expect(primary(o), 0);
      expect(metricValue(o, 'converted_amount'), 0);
    }
    for (final id in ['annuity_future_factor', 'annuity_present_factor']) {
      fails(id, {'periods': 0}, 'undefined_zero_period');
      fails(id, {'periods': 0, 'amount': 0}, 'undefined_zero_period');
    }
  });
  test('Known end-of-period payments agree with explicit sums and reciprocal identities', () {
    for (final rate in [0.0, 1e-20, 1e-12, -1e-12, 0.1, -0.1, -0.99]) {
      for (final n in [1, 2, 3, 25]) {
        double value(String id) =>
            primary(run(id, {'rate': rate, 'periods': n}));
        expect(
          value('future_present_factor') * value('present_future_factor'),
          closeTo(1, 1e-12),
        );
        expect(
          value('future_annuity_factor') * value('annuity_future_factor'),
          closeTo(1, 1e-12),
        );
        expect(
          value('present_annuity_factor') * value('annuity_present_factor'),
          closeTo(1, 1e-12),
        );
        expect(
          value('future_annuity_factor') * value('present_future_factor'),
          closeTo(
            value('present_annuity_factor'),
            value('present_annuity_factor') * 1e-12,
          ),
        );
      }
    }
  });
  test('One end-period payment is not an annuity-due shifted payment', () {
    expect(
      primary(run('future_annuity_factor', {'periods': 1})),
      closeTo(1, 1e-15),
    );
    expect(
      primary(run('present_annuity_factor', {'periods': 1})),
      closeTo(1 / 1.1, 1e-15),
    );
    expect(
      primary(run('annuity_present_factor', {'periods': 1})),
      closeTo(1.1, 1e-15),
    );
  });
  test('Near-zero rates do not divide by a cancellation-rounded zero', () {
    for (final id in factors) {
      final small = primary(run(id, {'rate': 1e-20, 'periods': 30})),
          zero = primary(run(id, {'rate': 0, 'periods': 30}));
      expect(small, closeTo(zero, zero * 1e-12));
    }
    final o = run('time_value_money', {
      'amount': 1e308,
      'rate': 1e-20,
      'periods': 1,
    });
    expect(metricValue(o, 'interest'), closeTo(1e288, 1e276));
  });
  test('Stable reciprocal formulas avoid intermediate overflow', () {
    expect(
      primary(run('present_annuity_factor', {'rate': 0.1, 'periods': 10000})),
      closeTo(10, 1e-10),
    );
    expect(
      primary(run('annuity_present_factor', {'rate': 0.1, 'periods': 10000})),
      closeTo(0.1, 1e-12),
    );
    expect(
      primary(run('future_annuity_factor', {'rate': -0.5, 'periods': 10000})),
      closeTo(2, 1e-12),
    );
    expect(
      primary(run('annuity_future_factor', {'rate': -0.5, 'periods': 10000})),
      closeTo(0.5, 1e-12),
    );
  });
  test('Unrepresentable factors, amounts and nonzero underflow reject', () {
    for (final id in [
      'time_value_money',
      'future_present_factor',
      'future_annuity_factor',
    ]) {
      fails(id, {'rate': 0.1, 'periods': 10000}, 'numeric_range');
    }
    fails('present_future_factor', {
      'rate': 0.1,
      'periods': 10000,
    }, 'numeric_range');
    fails('annuity_future_factor', {
      'rate': 0.1,
      'periods': 10000,
    }, 'numeric_range');
    fails('time_value_money', {
      'amount': 1e308,
      'rate': 1,
      'periods': 10,
    }, 'numeric_range');
    fails('inflation_adjustment', {
      'amount': 1e-308,
      'rate': 1,
      'periods': 100,
    }, 'numeric_range');
  });
  test('Inflation adjustment is purchasing-power deflation, not nominal interest subtraction', () {
    expect(
      primary(
        run('inflation_adjustment', {
          'amount': 1210,
          'rate': 0.1,
          'periods': 2,
        }),
      ),
      closeTo(1000, 1e-10),
    );
    expect(
      primary(
        run('inflation_adjustment', {
          'amount': 1000,
          'rate': -0.5,
          'periods': 1,
        }),
      ),
      closeTo(2000, 1e-10),
    );
    expect(primary(run('inflation_adjustment', {'rate': 0})), 1000);
    expect(primary(run('inflation_adjustment', {'amount': 0})), 0);
  });
  for (final id in [
    'straight_line_depreciation',
    'declining_balance_depreciation',
  ]) {
    test(
      '$id: salvage cannot exceed cost and year cannot exceed useful life',
      () {
        fails(id, {'salvage': 1001}, 'salvage_exceeds_cost');
        fails(id, {'year': 6}, 'year_exceeds_life');
        fails(id, {'life': 0}, 'invalid_number');
      },
    );
    test(
      '$id: acquisition time and already-at-salvage assets remain valid',
      () {
        final o = run(id, {'year': 0});
        expect(primary(o), 0);
        expect(metricValue(o, 'book_begin'), 1000);
        expect(metricValue(o, 'book_end'), 1000);
        expect(metricValue(o, 'accumulated'), 0);
        for (final c in [0, 1000]) {
          final same = run(id, {'cost': c, 'salvage': c});
          expect(primary(same), 0);
          expect(metricValue(same, 'book_end'), c);
          expect(metricValue(same, 'accumulated'), 0);
        }
      },
    );
  }
  test('Straight line conservation and exact terminal salvage', () {
    for (var y = 1; y <= 5; y++) {
      final o = run('straight_line_depreciation', {'year': y});
      expect(primary(o), 180);
      expect(metricValue(o, 'accumulated'), closeTo(y * 180, 1e-10));
      expect(metricValue(o, 'book_end'), closeTo(1000 - y * 180, 1e-10));
    }
    expect(
      metricValue(run('straight_line_depreciation', {'year': 5}), 'book_end'),
      100,
    );
    fails('straight_line_depreciation', {
      'cost': 1e-320,
      'salvage': 0,
      'life': 10000,
    }, 'numeric_range');
  });
  test(
    'Declining balance clamps expense to salvage without negative depreciation',
    () {
      final first = run('declining_balance_depreciation', {
            'salvage': 700,
            'year': 1,
          }),
          second = run('declining_balance_depreciation', {
            'salvage': 700,
            'year': 2,
          }),
          third = run('declining_balance_depreciation', {
            'salvage': 700,
            'year': 3,
          });
      expect(primary(first), 200);
      expect(primary(second), closeTo(100, 1e-10));
      expect(metricValue(second, 'book_end'), 700);
      expect(primary(third), 0);
    },
  );
  test(
    'Declining balance zero and 100 percent boundaries, invalid percentages',
    () {
      final zero = run('declining_balance_depreciation', {
        'depreciation_rate': 0,
        'year': 5,
      });
      expect(primary(zero), 0);
      expect(metricValue(zero, 'book_end'), 1000);
      expect(
        success(zero).warnings.any((w) => w.code == 'residual_above_salvage'),
        isTrue,
      );
      expect(
        primary(
          run('declining_balance_depreciation', {
            'depreciation_rate': 1,
            'year': 1,
          }),
        ),
        900,
      );
      expect(
        primary(
          run('declining_balance_depreciation', {
            'depreciation_rate': 1,
            'year': 2,
          }),
        ),
        0,
      );
      fails('declining_balance_depreciation', {
        'depreciation_rate': 1.01,
      }, 'invalid_number');
    },
  );
  test('Declining balance never silently switches method or clears remaining book at life', () {
    final o = run('declining_balance_depreciation', {'year': 5});
    expect(metricValue(o, 'book_end'), closeTo(327.68, 1e-10));
    expect(primary(o), closeTo(81.92, 1e-10));
    expect(
      success(o).warnings.any((w) => w.code == 'residual_above_salvage'),
      isTrue,
    );
  });
  test('Declining book avoids factor underflow when the book itself is representable', () {
    final o = run('declining_balance_depreciation', {
      'cost': 1e308,
      'salvage': 0,
      'depreciation_rate': 0.5,
      'life': 1100,
      'year': 1100,
    });
    expect(metricValue(o, 'book_end'), greaterThan(0));
    expect(primary(o), greaterThan(0));
    final floor = run('declining_balance_depreciation', {
      'depreciation_rate': 0.9,
      'life': 10000,
      'year': 10000,
    });
    expect(metricValue(floor, 'book_end'), 100);
    fails('declining_balance_depreciation', {
      'salvage': 0,
      'depreciation_rate': 0.9,
      'life': 10000,
      'year': 10000,
    }, 'numeric_range');
  });
}
