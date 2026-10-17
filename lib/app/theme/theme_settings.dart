import 'package:flutter/material.dart';

class ThemeSettings extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  bool _reduceMotion = false;
  bool get reduceMotion => _reduceMotion;
  void setReduceMotion(bool value) {
    if (value == _reduceMotion) return;
    _reduceMotion = value;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}

class ThemeScope extends InheritedNotifier<ThemeSettings> {
  const ThemeScope({
    super.key,
    required ThemeSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static ThemeSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope is required above this widget');
    return scope!.notifier!;
  }
}
