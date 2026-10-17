import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

double number(CalculationOutcome o) =>
    ((o as CalculationSuccess).result.primary.value as NumericResultValue)
        .value;
void failsAt(CalculationOutcome o, String field) {
  expect(o, isA<CalculationFailure>());
  expect(
    (o as CalculationFailure).issues.any((i) => i.fieldId == field),
    isTrue,
  );
}

void failure(CalculationOutcome o, String code) {
  expect(o, isA<CalculationFailure>());
  expect((o as CalculationFailure).issues.any((i) => i.code == code), isTrue);
}

List<Map<String, dynamic>> references(String id) =>
    (jsonDecode(File('test/fixtures/finance_reference.json').readAsStringSync())
            as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((r) => r['id'] == id)
        .toList();
