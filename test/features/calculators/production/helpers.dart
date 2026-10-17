import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

double number(CalculationOutcome outcome) =>
    ((outcome as CalculationSuccess).result.primary.value as NumericResultValue)
        .value;
void failsAt(CalculationOutcome outcome, String field) {
  expect(outcome, isA<CalculationFailure>());
  expect(
    (outcome as CalculationFailure).issues.any(
      (issue) => issue.fieldId == field,
    ),
    isTrue,
  );
}

void rangeFailure(CalculationOutcome outcome) {
  expect(outcome, isA<CalculationFailure>());
  expect((outcome as CalculationFailure).issues.single.code, 'numeric_range');
}

List<Map<String, dynamic>> referenceCases(String id) =>
    (jsonDecode(
          File('test/fixtures/production_reference.json').readAsStringSync(),
        ) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((item) => item['id'] == id)
        .toList();
