import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../calculators/domain/calculator_domain.dart';
import '../../../history/domain/recent_calculation.dart';
import '../../../history/domain/tool_repository.dart';
import '../../domain/tool_catalog.dart';

/// Observable committed SQLite snapshots. The repository is owned here.
final class ToolSessionController extends ChangeNotifier {
  ToolSessionController({
    required this.catalog,
    required this._repository,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;
  final ToolCatalog catalog;
  final ToolRepository _repository;
  final DateTime Function() _now;
  Set<String> _favorites = const {};
  List<RecentCalculation> _recent = const [];
  Future<void> _tail = Future.value();
  Future<void>? _closing;
  var _disposed = false, _ready = false;
  var _pending = 0;
  String? _lastError;
  bool get isReady => _ready;
  bool get isBusy => _pending > 0;
  String? get lastError => _lastError;
  Set<String> get favorites => Set.unmodifiable(_favorites);
  List<RecentCalculation> get recent => List.unmodifiable(_recent);
  bool isFavorite(String id) => _favorites.contains(id);
  Future<bool> initialize() => _enqueue(_repository.load, initializing: true);

  Future<bool> toggleFavorite(String id) {
    _requireTool(id);
    final time = _now();
    return _enqueue(() => _repository.toggleFavorite(id, time));
  }

  Future<bool> record(
    String id,
    RawCalculatorInput inputs,
    CalculationResult result,
  ) {
    _requireTool(id);
    final time = _now();
    return _enqueue(() => _repository.record(id, inputs, result, time));
  }

  void _requireTool(String id) {
    if (_disposed || _closing != null) {
      throw StateError('کنترل‌گر بسته شده است');
    }
    if (!_ready) throw StateError('پایگاه داده هنوز آماده نیست');
    if (catalog.toolById(id) == null) {
      throw ArgumentError('ابزار قابل استفاده در کاتالوگ نیست');
    }
  }

  Future<bool> _enqueue(
    Future<StoredTools> Function() operation, {
    bool initializing = false,
  }) {
    if (_disposed || _closing != null) return Future.value(false);
    _pending++;
    _notify();
    final work = _tail.then((_) async {
      try {
        if (_disposed) return false;
        final snapshot = await operation();
        if (_disposed) return false;
        // Unknown retired tool IDs stay on disk; they cannot crash the UI.
        _favorites = Set.unmodifiable(
          snapshot.favorites.where((id) => catalog.toolById(id) != null),
        );
        _recent = List.unmodifiable(
          snapshot.recent.where(
            (r) => catalog.toolById(r.calculatorId) != null,
          ),
        );
        _ready = true;
        _lastError = null;
        return true;
      } on Object {
        _lastError = initializing
            ? 'خواندن پایگاه داده انجام نشد. داده‌ها حذف نشده‌اند؛ دوباره تلاش کنید.'
            : 'ذخیره‌سازی انجام نشد؛ تغییر تأیید نشده است. فضای دیسک و دسترسی را بررسی و دوباره تلاش کنید.';
        return false;
      } finally {
        _pending--;
        _notify();
      }
    });
    _tail = work.then((_) {});
    return work;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> close() => _closing ??= _tail.then((_) => _repository.close());
  @override
  void dispose() {
    _disposed = true;
    unawaited(close().catchError((Object _) {}));
    super.dispose();
  }
}
