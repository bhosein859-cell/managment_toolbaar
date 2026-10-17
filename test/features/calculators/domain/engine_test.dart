import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

final class _ScaleParameters implements CalculatorParameters {
  const _ScaleParameters(this.quantity, this.rate);
  final double quantity;
  final double rate;
}

/// Test-only compiled engine, not part of the application's catalog.
final class _ScaleEngine implements CalculatorEngine<_ScaleParameters> {
  _ScaleEngine({
    this.throwOnBind = false,
    this.throwOnCalculate = false,
    this.nonFiniteResult = false,
    this.rejectCalculation = false,
  });
  final bool throwOnBind;
  final bool throwOnCalculate;
  final bool nonFiniteResult;
  final bool rejectCalculation;
  int bindCalls = 0;
  int calculateCalls = 0;

  @override
  String get calculatorId => 'test_calculator';

  @override
  InputBinding<_ScaleParameters> bind(CalculatorInput input) {
    bindCalls++;
    if (throwOnBind) throw StateError('INTERNAL_SECRET');
    final quantity = input.requireNumber('quantity');
    final rate = input.requireNumber('rate');
    if (quantity == 0 && rate == 0) {
      return RejectedInput([
        CalculationIssue(
          code: 'undefined_case',
          message: 'مقدار و نرخ نباید هم‌زمان صفر باشند.',
          fieldId: 'quantity',
        ),
      ]);
    }
    return BoundInput(_ScaleParameters(quantity, rate));
  }

  @override
  CalculationOutcome calculate(_ScaleParameters parameters) {
    calculateCalls++;
    if (throwOnCalculate) throw StateError('INTERNAL_SECRET');
    if (rejectCalculation) {
      return CalculationFailure([
        CalculationIssue(
          code: 'no_solution',
          message: 'برای این ورودی پاسخی وجود ندارد.',
        ),
      ]);
    }
    return CalculationSuccess(
      numericResult(
        nonFiniteResult
            ? double.infinity
            : parameters.quantity * parameters.rate,
      ),
    );
  }
}

CalculatorDefinition _definition({String formula = 'y = quantity × rate'}) =>
    definition(
      formula: formula,
      fields: [
        NumericFieldDefinition(id: 'quantity', label: 'مقدار', min: 0),
        NumericFieldDefinition(
          id: 'rate',
          label: 'نرخ',
          kind: NumericInputKind.percentage,
          min: 0,
          max: 100,
        ),
      ],
    );

void main() {
  test('compiled engine receives typed normalized parameters', () {
    final engine = _ScaleEngine();
    final runner = CalculatorRunner(definition: _definition(), engine: engine);
    final result = runner.run(
      raw({'quantity': '۲۰۰', 'rate': '٢٥'}),
    ) as CalculationSuccess;
    expect((result.result.primary.value as NumericResultValue).value, 50);
    expect(engine.bindCalls, 1);
    expect(engine.calculateCalls, 1);
  });

  test('invalid input never reaches bind or calculate', () {
    final engine = _ScaleEngine();
    final runner = CalculatorRunner(definition: _definition(), engine: engine);
    final result = runner.run(
      raw({'quantity': 'NaN', 'rate': '101'}),
    ) as CalculationFailure;
    expect(result.issues, hasLength(2));
    expect(engine.bindCalls, 0);
    expect(engine.calculateCalls, 0);
  });

  test('cross-field rejection prevents calculation', () {
    final engine = _ScaleEngine();
    final result = CalculatorRunner(
      definition: _definition(),
      engine: engine,
    ).run(raw({'quantity': '۰', 'rate': '٠'})) as CalculationFailure;
    expect(result.issues.single.code, 'undefined_case');
    expect(engine.calculateCalls, 0);
  });

  test('legitimate domain failure is returned without fabricated result', () {
    final engine = _ScaleEngine(rejectCalculation: true);
    final result = CalculatorRunner(
      definition: _definition(),
      engine: engine,
    ).run(raw({'quantity': '10', 'rate': '20'})) as CalculationFailure;
    expect(result.issues.single.code, 'no_solution');
  });

  for (final engine in [
    _ScaleEngine(throwOnBind: true),
    _ScaleEngine(throwOnCalculate: true),
    _ScaleEngine(nonFiniteResult: true),
  ]) {
    test(
      'unexpected error or nonfinite result is safe and diagnosable: ${engine.throwOnBind}/${engine.throwOnCalculate}',
      () {
        Object? reportedError;
        final runner = CalculatorRunner(
          definition: _definition(),
          engine: engine,
          onUnexpectedError: (error, stack) {
            reportedError = error;
          },
        );
        final result = runner.run(
          raw({'quantity': '10', 'rate': '20'}),
        ) as CalculationFailure;
        expect(result.issues.single.code, 'calculation_failed');
        expect(result.issues.single.message, contains('محاسبه انجام نشد'));
        expect(
          result.issues.single.message,
          isNot(contains('INTERNAL_SECRET')),
        );
        expect(reportedError, isNotNull);
      },
    );
  }

  test(
    'diagnostics callback failure does not leak or replace user failure',
    () {
      final runner = CalculatorRunner(
        definition: _definition(),
        engine: _ScaleEngine(throwOnBind: true),
        onUnexpectedError: (_, _) => throw StateError('LOGGING_SECRET'),
      );
      expect(
        runner.run(raw({'quantity': '1', 'rate': '1'})),
        isA<CalculationFailure>(),
      );
    },
  );

  test('different engine identity is rejected before execution', () {
    expect(
      () => CalculatorRunner(
        definition: definition(id: 'different'),
        engine: _ScaleEngine(),
      ),
      throwsArgumentError,
    );
  });

  test('arbitrary formula text is inert; only compiled engine code runs', () {
    final runner = CalculatorRunner(
      definition: _definition(
        formula: 'throw INTERNAL_SECRET; execute(anything)',
      ),
      engine: _ScaleEngine(),
    );
    final result =
        runner.run(raw({'quantity': '10', 'rate': '20'})) as CalculationSuccess;
    expect((result.result.primary.value as NumericResultValue).value, 2);
  });

  test('runner remains usable after invalid input followed by valid input', () {
    final runner = CalculatorRunner(
      definition: _definition(),
      engine: _ScaleEngine(),
    );
    expect(
      runner.run(raw({'quantity': 'bad', 'rate': '2'})),
      isA<CalculationFailure>(),
    );
    expect(
      runner.run(raw({'quantity': '10', 'rate': '2'})),
      isA<CalculationSuccess>(),
    );
  });

  test('typed rejected binding snapshots issues and rejects empty failure', () {
    final issues = [CalculationIssue(code: 'invalid', message: 'نامعتبر است')];
    final binding = RejectedInput<_ScaleParameters>(issues);
    issues.clear();
    expect(binding.issues, hasLength(1));
    expect(() => binding.issues.clear(), throwsUnsupportedError);
    expect(() => RejectedInput<_ScaleParameters>([]), throwsArgumentError);
  });
}
