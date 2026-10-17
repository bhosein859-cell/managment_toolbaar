import 'dart:async';

import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';
import 'package:management_toolbox/features/history/domain/tool_repository.dart';

final class ControlledRepository implements ToolRepository {
  final inner = DriftToolRepository.memory();
  bool failRead = false, failWrite = false, closed = false;
  Completer<void>? gate;
  @override
  Future<StoredTools> load() async {
    if (failRead) throw StateError('injected read failure');
    return inner.load();
  }

  @override
  Future<StoredTools> toggleFavorite(String id, DateTime time) async {
    await gate?.future;
    if (failWrite) throw StateError('injected write failure');
    return inner.toggleFavorite(id, time);
  }

  @override
  Future<StoredTools> record(
    String id,
    RawCalculatorInput i,
    CalculationResult r,
    DateTime t,
  ) async {
    await gate?.future;
    if (failWrite) throw StateError('injected write failure');
    return inner.record(id, i, r, t);
  }

  @override
  Future<void> close() async {
    closed = true;
    await inner.close();
  }
}
