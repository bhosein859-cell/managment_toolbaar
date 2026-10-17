import 'dart:convert';

import '../../calculators/domain/calculator_domain.dart';

/// Version 1 retains original text, including Persian digits, whitespace,
/// list order, empty optional lists and omitted fields. No formula evaluation.
abstract final class CalculationSnapshotCodec {
  static const version = 1;
  static String encodeInputs(RawCalculatorInput input) => jsonEncode({
    for (final e in input.values.entries)
      e.key: switch (e.value) {
        RawTextInput(:final text) => {'type': 'text', 'text': text},
        RawNumberListInput(:final items) => {'type': 'list', 'items': items},
      },
  });
  static RawCalculatorInput decodeInputs(String json) {
    final object = _object(jsonDecode(json));
    return RawCalculatorInput({
      for (final e in object.entries) e.key: _raw(_object(e.value)),
    });
  }

  static RawFieldInput _raw(Map<String, dynamic> object) =>
      switch (object['type']) {
        'text' => RawTextInput(_string(object['text'])),
        'list' => RawNumberListInput(_list(object['items']).map(_string)),
        _ => throw const FormatException('نوع ورودی ذخیره‌شده ناشناخته است'),
      };
  static String encodeResult(CalculationResult result) => jsonEncode({
    'primary': _encodeMetric(result.primary),
    'details': result.details.map(_encodeMetric).toList(),
    'interpretation': result.interpretation,
    'warnings': [
      for (final w in result.warnings)
        {'code': w.code, 'message': w.message, 'severity': w.severity.name},
    ],
  });
  static Map<String, Object?> _encodeMetric(ResultMetric m) => {
    'id': m.id,
    'label': m.label,
    'value': switch (m.value) {
      NumericResultValue(:final value, :final unit, :final display) => {
        'type': 'number',
        'value': value,
        'unit': unit,
        'display': display.name,
      },
      TextResultValue(:final value) => {'type': 'text', 'value': value},
      NumberListResultValue(:final values, :final unit) => {
        'type': 'list',
        'values': values,
        'unit': unit,
      },
    },
  };
  static CalculationResult decodeResult(String json) {
    final o = _object(jsonDecode(json));
    return CalculationResult(
      primary: _decodeMetric(o['primary']),
      details: _list(o['details']).map(_decodeMetric),
      interpretation: _string(o['interpretation']),
      warnings: [for (final v in _list(o['warnings'])) _warning(_object(v))],
    );
  }

  static ResultMetric _decodeMetric(Object? value) {
    final m = _object(value), v = _object(m['value']);
    final result = switch (v['type']) {
      'number' => NumericResultValue(
        _number(v['value']),
        unit: _unit(v['unit']),
        display: _enum(NumberDisplay.values, v['display']),
      ),
      'text' => TextResultValue(_string(v['value'])),
      'list' => NumberListResultValue(
        _list(v['values']).map(_number),
        unit: _unit(v['unit']),
      ),
      _ => throw const FormatException('نوع نتیجهٔ ذخیره‌شده ناشناخته است'),
    };
    return ResultMetric(
      id: _string(m['id']),
      label: _string(m['label']),
      value: result,
    );
  }

  static CalculationWarning _warning(Map<String, dynamic> v) =>
      CalculationWarning(
        code: _string(v['code']),
        message: _string(v['message']),
        severity: _enum(WarningSeverity.values, v['severity']),
      );
  static T _enum<T extends Enum>(List<T> values, Object? value) =>
      values.firstWhere(
        (v) => v.name == value,
        orElse: () =>
            throw const FormatException('نسخهٔ داده پشتیبانی نمی‌شود'),
      );
  static Map<String, dynamic> _object(Object? x) => x is Map<String, dynamic>
      ? x
      : throw const FormatException('ساختار ذخیره‌شده معتبر نیست');
  static List<dynamic> _list(Object? x) => x is List<dynamic>
      ? x
      : throw const FormatException('فهرست ذخیره‌شده معتبر نیست');
  static String _string(Object? x) =>
      x is String ? x : throw const FormatException('متن ذخیره‌شده معتبر نیست');
  static String? _unit(Object? x) => x == null ? null : _string(x);
  static double _number(Object? x) => x is num && x.isFinite
      ? x.toDouble()
      : throw const FormatException('عدد ذخیره‌شده معتبر نیست');
}
