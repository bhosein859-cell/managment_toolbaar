import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  test('Cost benefit signs, equal alternatives and zero cost have explicit meaning', () {
    expect(primary(run('cost_benefit_comparison')), 30);
    expect(
      primary(
        run('cost_benefit_comparison', {
          'cost_a': 120,
          'benefit_a': 210,
          'cost_b': 100,
          'benefit_b': 160,
        }),
      ),
      -30,
    );
    expect(
      primary(
        run('cost_benefit_comparison', {
          'cost_a': 100,
          'benefit_a': 160,
          'cost_b': 100,
          'benefit_b': 160,
        }),
      ),
      0,
    );
    final z = run('cost_benefit_comparison', {
      'cost_a': 0,
      'benefit_a': 0,
      'cost_b': 0,
      'benefit_b': 0,
    });
    expect(primary(z), 0);
    expect(detail(z, 'bcr_a'), isA<TextResultValue>());
    expect(detail(z, 'bcr_b'), isA<TextResultValue>());
    expect(metricValue(run('cost_benefit_comparison'), 'bcr_a'), 1.6);
  });
  test(
    'Common period is context only, never hidden annualization or discounting',
    () {
      for (final id in ['cost_benefit_comparison', 'two_option_break_even']) {
        expect(primary(run(id, {'period_days': 30})), primary(run(id)));
        fails(id, {'period_days': 0});
      }
    },
  );
  test(
    'Break even symmetric alternatives and zero crossing remain defined',
    () {
      final o = run('two_option_break_even');
      expect(primary(o), 50);
      expect(metricValue(o, 'cost_a'), 350);
      expect(metricValue(o, 'cost_b'), 350);
      expect(
        primary(
          run('two_option_break_even', {
            'fixed_a': 200,
            'variable_a': 3,
            'fixed_b': 100,
            'variable_b': 5,
          }),
        ),
        50,
      );
      expect(
        primary(run('two_option_break_even', {'fixed_a': 100, 'fixed_b': 100})),
        0,
      );
    },
  );
  test('Identical, parallel and negative crossings have distinct errors', () {
    fails('two_option_break_even', {
      'variable_a': 3,
      'variable_b': 3,
      'fixed_a': 100,
      'fixed_b': 100,
    }, 'identical_costs');
    fails('two_option_break_even', {
      'variable_a': 3,
      'variable_b': 3,
    }, 'parallel_costs');
    fails('two_option_break_even', {
      'variable_a': 2,
      'variable_b': 3,
    }, 'no_nonnegative_crossing');
  });
  test('Overflow and nonzero underflow reject instead of manufacturing a finite result', () {
    fails('two_option_break_even', {
      'fixed_a': 0,
      'fixed_b': 1e308,
      'variable_a': 1e-308,
      'variable_b': 0,
    }, 'numeric_range');
    fails('two_option_break_even', {
      'fixed_a': 0,
      'fixed_b': 1e-308,
      'variable_a': 1e308,
      'variable_b': 0,
    }, 'numeric_range');
    fails('cost_benefit_comparison', {
      'cost_a': 1e308,
      'benefit_a': 0,
      'cost_b': 0,
      'benefit_b': 1e308,
    }, 'numeric_range');
    fails('cost_benefit_comparison', {
      'cost_a': 1e-308,
      'benefit_a': 1e308,
    }, 'numeric_range');
  });
}
