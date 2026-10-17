import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/domain/engines/finance/irr_engine.dart';

import 'helpers.dart';

void main() {
  const engine = IrrEngine();
  test('IRR known unique multi-period root', () {
    expect(
      number(engine.calculate(IrrParameters([-1000, 600, 600]))),
      closeTo(0.1306623862918075, 1e-10),
    );
  });
  test('IRR positive negative zero and reversed financing flow signs', () {
    for (final (flows, expected) in <(List<double>, double)>[
      ([-100, 110], 0.1),
      ([-100, 90], -0.1),
      ([-1000, 500, 500], 0),
      ([100, -110], 0.1),
      ([-100, 0, 121], 0.1),
    ]) {
      expect(
        number(engine.calculate(IrrParameters(flows))),
        closeTo(expected, 1e-10),
      );
    }
  });
  test('IRR exactly balanced cash flows have zero rate', () {
    expect(number(engine.calculate(IrrParameters([-1000, 500, 500]))), 0);
    expect(number(engine.calculate(IrrParameters([-100, 100]))), 0);
  });
  test('IRR scale invariance at tiny and huge values', () {
    for (final scale in [1e-300, 1.0, 1e300]) {
      expect(
        number(engine.calculate(IrrParameters([-scale, 1.1 * scale]))),
        closeTo(0.1, 1e-10),
      );
    }
  });
  test('IRR no sign change is genuinely no root', () {
    for (final flows in <List<double>>[
      [100, 50],
      [-100, -50],
      [100, 0, 50],
    ]) {
      failure(engine.calculate(IrrParameters(flows)), 'no_irr');
    }
  });
  test('IRR zero flows and leading zero are not fabricated answers', () {
    failure(engine.calculate(IrrParameters([0, 0])), 'indeterminate_irr');
    failure(
      engine.calculate(IrrParameters([0, -100, 110])),
      'zero_initial_flow',
    );
  });
  test('IRR ambiguous cash flows do not silently select one root', () {
    // Two known roots 10% and 20%; also a nonconventional series with no real root.
    for (final flows in <List<double>>[
      [-100, 230, -132],
      [-100, 50, -100],
    ]) {
      failure(engine.calculate(IrrParameters(flows)), 'nonconventional_flows');
    }
  });
  test('IRR iteration budget exhaustion yields failure, not last iterate', () {
    for (final count in [0, 1]) {
      failure(
        IrrEngine(maxIterations: count)
            .calculate(IrrParameters([-1000, 600, 600])),
        'no_convergence',
      );
    }
  });
  test('IRR numerical bounds are not mislabeled as no mathematical root', () {
    failure(engine.calculate(IrrParameters([-1, 1e301])), 'root_out_of_range');
    failure(engine.calculate(IrrParameters([-1e300, 1])), 'root_out_of_range');
  });
  test('IRR invalid length and NaN Infinity are rejected directly', () {
    for (final flows in <List<double>>[
      [],
      [-100],
      List.filled(1001, 1),
      [-100, double.nan],
      [-100, double.infinity],
    ]) {
      expect(engine.calculate(IrrParameters(flows)), isA<CalculationFailure>());
    }
  });
  test('IRR immutable parameters and typed binding', () {
    final flows = <double>[-100, 110];
    final p = IrrParameters(flows);
    flows[0] = 0;
    expect(p.cashFlows.first, -100);
    expect(() => p.cashFlows.clear(), throwsUnsupportedError);
    final bound = engine.bind(
      CalculatorInput({
        'cash_flows': NumberListInputValue([-100, 110]),
      }),
    );
    expect(bound, isA<BoundInput<IrrParameters>>());
    expect(
      engine.bind(
        CalculatorInput({
          'cash_flows': NumberListInputValue([0, 0]),
        }),
      ),
      isA<RejectedInput<IrrParameters>>(),
    );
  });
  test('IRR near-minus-one precision failures are explicit when necessary', () {
    final outcome = engine.calculate(IrrParameters([-1, 1e-15]));
    expect(
      outcome,
      isA<CalculationFailure>(),
    ); // A representable rate cannot meet the residual criterion.
    expect(
      (outcome as CalculationFailure).issues.single.code,
      isIn(['insufficient_precision', 'no_convergence']),
    );
  });
  test('IRR 1000-flow horizon retains timing and tiny rates', () {
    final flows = <double>[
      -1000,
      ...List.filled(998, 0),
      1000 * math.pow(1.01, 999).toDouble(),
    ];
    expect(
      number(engine.calculate(IrrParameters(flows))),
      closeTo(0.01, 1e-10),
    );
    expect(
      number(engine.calculate(IrrParameters([-1, 1e200]))) / 1e200,
      closeTo(1, 1e-9),
    );
  });
  test('IRR independent Decimal-derived multi-period roots', () {
    final rows = references('irr');
    expect(rows, hasLength(20));
    for (final row in rows) {
      final flows = (row['inputs']['cash_flows'] as List<dynamic>).map(
        (v) => double.parse(v as String),
      );
      final outcome = engine.calculate(IrrParameters(flows));
      expect(
        number(outcome),
        closeTo(double.parse(row['expected'] as String), 1e-10),
        reason: row.toString(),
      );
      final result = (outcome as CalculationSuccess).result;
      expect(
        (result.details[1].value as NumericResultValue).value,
        lessThanOrEqualTo(1e-10),
      );
    }
  });
}
