import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/decision_calculators.dart';
import 'package:management_toolbox/app/catalog/engineering_economics_calculators.dart';
import 'package:management_toolbox/app/catalog/finance_calculators.dart';
import 'package:management_toolbox/app/catalog/hr_calculators.dart';
import 'package:management_toolbox/app/catalog/inventory_calculators.dart';
import 'package:management_toolbox/app/catalog/production_calculators.dart';
import 'package:management_toolbox/app/catalog/project_calculators.dart';
import 'package:management_toolbox/app/catalog/quality_calculators.dart';
import 'package:management_toolbox/app/catalog/utility_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/data/calculation_snapshot_codec.dart';

void main() {
  final runners = <CalculatorRunner<CalculatorParameters>>[
    ...ProductionCalculators.runners,
    ...FinanceCalculators.runners,
    ...QualityCalculators.runners,
    ...InventoryCalculators.runners,
    ...ProjectCalculators.runners,
    ...HrCalculators.runners,
    ...DecisionCalculators.runners,
    ...EngineeringEconomicsCalculators.runners,
    ...UtilityCalculators.runners,
  ];
  for (final r in runners) {
    test(
      '${r.definition.id}: raw input and complete result/warnings round trip losslessly',
      () {
        final input = r.definition.examples.single.inputs,
            result = (r.run(input) as CalculationSuccess).result;
        final raw = CalculationSnapshotCodec.encodeInputs(input),
            output = CalculationSnapshotCodec.encodeResult(result);
        final decoded = CalculationSnapshotCodec.decodeInputs(raw);
        expect(CalculationSnapshotCodec.encodeInputs(decoded), raw);
        expect(r.run(decoded), isA<CalculationSuccess>());
        expect(
          CalculationSnapshotCodec.encodeResult(
            CalculationSnapshotCodec.decodeResult(output),
          ),
          output,
        );
      },
    );
  }
  test('codec preserves Persian/Arabic digits, whitespace, choices, missing and empty fields', () {
    final original = RawCalculatorInput({
      'number': const RawTextInput('  −۱۲٫۵  '),
      'choice': const RawTextInput('future'),
      'list': RawNumberListInput(['۱', '٢', ' 3 ']),
      'empty': RawNumberListInput([]),
    });
    final decoded = CalculationSnapshotCodec.decodeInputs(
      CalculationSnapshotCodec.encodeInputs(original),
    );
    expect((decoded.values['number'] as RawTextInput).text, '  −۱۲٫۵  ');
    expect((decoded.values['list'] as RawNumberListInput).items, [
      '۱',
      '٢',
      ' 3 ',
    ]);
    expect((decoded.values['empty'] as RawNumberListInput).items, isEmpty);
    expect(decoded.values.containsKey('omitted'), isFalse);
    expect(() => decoded.values.clear(), throwsUnsupportedError);
    expect(
      () => (decoded.values['list'] as RawNumberListInput).items.clear(),
      throwsUnsupportedError,
    );
  });
  test('all result variants, units, displays and warning severity survive', () {
    final r = CalculationResult(
      primary: ResultMetric(
        id: 'primary',
        label: 'درصد',
        value: NumericResultValue(
          -0.125,
          unit: 'درصد',
          display: NumberDisplay.percentage,
        ),
      ),
      details: [
        ResultMetric(
          id: 'text',
          label: 'توضیح',
          value: TextResultValue('نسبت تعریف نمی‌شود'),
        ),
        ResultMetric(
          id: 'list',
          label: 'بردار',
          value: NumberListResultValue([0, -2, 1e-300, 1e300], unit: 'ریال'),
        ),
        ResultMetric(
          id: 'empty',
          label: 'فهرست خالی',
          value: NumberListResultValue([]),
        ),
      ],
      warnings: [
        CalculationWarning(
          code: 'info',
          message: 'اطلاع',
          severity: WarningSeverity.information,
        ),
        CalculationWarning(code: 'caution', message: 'هشدار'),
      ],
      interpretation: 'خط اول\nخط دوم',
    );
    final encoded = CalculationSnapshotCodec.encodeResult(r);
    expect(
      CalculationSnapshotCodec.encodeResult(
        CalculationSnapshotCodec.decodeResult(encoded),
      ),
      encoded,
    );
  });
  for (final json in [
    'null',
    '[]',
    'true',
    '{broken',
    '{"a":{"type":"future"}}',
    '{"a":{"type":"text","text":2}}',
    '{"a":{"type":"list","items":["1",null]}}',
  ]) {
    test('invalid input payload rejects: $json', () {
      expect(
        () => CalculationSnapshotCodec.decodeInputs(json),
        throwsA(isA<FormatException>()),
      );
    });
  }
  test('unknown display/severity, nonfinite values and wrong unit types never get defaults', () {
    final base = {
      'primary': {
        'id': 'p',
        'label': 'نتیجه',
        'value': {
          'type': 'number',
          'value': 1,
          'unit': null,
          'display': 'decimal',
        },
      },
      'details': <Object?>[],
      'warnings': <Object?>[],
      'interpretation': '',
    };
    for (final v in [
      {'type': 'number', 'value': 1, 'display': 'future', 'unit': null},
      {'type': 'number', 'value': 'NaN', 'display': 'decimal', 'unit': null},
      {'type': 'number', 'value': 1, 'display': 'decimal', 'unit': 4},
      {'type': 'future', 'value': 1},
    ]) {
      final o = {
        ...base,
        'primary': {'id': 'p', 'label': 'نتیجه', 'value': v},
      };
      expect(
        () => CalculationSnapshotCodec.decodeResult(jsonEncode(o)),
        throwsA(isA<FormatException>()),
      );
    }
    final bad = {
      ...base,
      'warnings': [
        {'code': 'a', 'message': 'هشدار', 'severity': 'future'},
      ],
    };
    expect(
      () => CalculationSnapshotCodec.decodeResult(jsonEncode(bad)),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => CalculationSnapshotCodec.decodeResult('[]'),
      throwsA(isA<FormatException>()),
    );
  });
}
