void requireText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'نباید خالی باشد');
  }
}

void requireId(String value) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value)) {
    throw ArgumentError.value(value, 'id', 'شناسه باید لاتین و پایدار باشد');
  }
}

void requireFinite(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'باید متناهی باشد');
  }
}

void requireUnique(Iterable<String> ids) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw ArgumentError.value(id, 'id', 'شناسه تکراری است');
  }
}
