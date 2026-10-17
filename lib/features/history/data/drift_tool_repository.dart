import 'package:drift/drift.dart';

import '../../../core/storage/toolbox_database.dart';
import '../../calculators/domain/calculator_domain.dart';
import '../domain/recent_calculation.dart';
import '../domain/tool_repository.dart';
import 'calculation_snapshot_codec.dart';

/// All mutations and the resulting snapshot share one SQLite transaction.
/// No optimistic UI state is reported as durable before commit completes.
final class DriftToolRepository implements ToolRepository {
  DriftToolRepository(this._database, {this._reopen});
  factory DriftToolRepository.memory() =>
      DriftToolRepository(ToolboxDatabase.memory());
  ToolboxDatabase _database;
  final ToolboxDatabase Function()? _reopen;
  ToolboxDatabase get database => _database;
  var _failedLoad = false;
  Future<void>? _closing;

  void _validateId(String id) {
    if (!RegExp(r'^[a-z][a-z0-9_]{0,127}$').hasMatch(id)) {
      throw ArgumentError('شناسهٔ ابزار معتبر نیست');
    }
  }

  @override
  Future<StoredTools> load() async {
    if (_closing != null) throw StateError('Repository is closed');
    if (_failedLoad && _reopen != null) {
      try {
        await _database.close();
      } on Object {
        /* Failed opener may fail close too. */
      }
      _database = _reopen();
    }
    try {
      final snapshot = await database.transaction(_read);
      _failedLoad = false;
      return snapshot;
    } on Object {
      _failedLoad = true;
      rethrow;
    }
  }

  Future<StoredTools> _read() async {
    final favorites = await database
        .customSelect(
          'SELECT calculator_id FROM favorites ORDER BY calculator_id',
        )
        .get();
    final rows = await database
        .customSelect(
          'SELECT * FROM calculation_history ORDER BY id DESC LIMIT 10',
        )
        .get();
    try {
      return StoredTools(
        favorites: favorites.map((r) => r.read<String>('calculator_id')),
        recent: [for (final row in rows) _decode(row)],
      );
    } on Object {
      throw const StorageReadException();
    }
  }

  RecentCalculation _decode(QueryRow r) {
    if (r.read<int>('payload_version') != CalculationSnapshotCodec.version) {
      throw const StorageReadException();
    }
    final id = r.read<String>('calculator_id');
    _validateId(id);
    return RecentCalculation(
      sequence: r.read<int>('id'),
      calculatorId: id,
      inputs: CalculationSnapshotCodec.decodeInputs(
        r.read<String>('inputs_json'),
      ),
      result: CalculationSnapshotCodec.decodeResult(
        r.read<String>('result_json'),
      ),
      createdAt: DateTime.fromMicrosecondsSinceEpoch(
        r.read<int>('created_at_micros'),
        isUtc: true,
      ),
    );
  }

  @override
  Future<StoredTools> toggleFavorite(String calculatorId, DateTime createdAt) {
    _validateId(calculatorId);
    return database.transaction(() async {
      final removed = await database.customUpdate(
        'DELETE FROM favorites WHERE calculator_id = ?',
        variables: [Variable<String>(calculatorId)],
      );
      if (removed == 0) {
        await database.customStatement(
          'INSERT INTO favorites(calculator_id,created_at_micros) VALUES (?,?)',
          [calculatorId, createdAt.microsecondsSinceEpoch],
        );
      }
      return _read();
    });
  }

  @override
  Future<StoredTools> record(
    String calculatorId,
    RawCalculatorInput inputs,
    CalculationResult result,
    DateTime createdAt,
  ) {
    _validateId(calculatorId);
    final raw = CalculationSnapshotCodec.encodeInputs(inputs),
        output = CalculationSnapshotCodec.encodeResult(result);
    return database.transaction(() async {
      await database.customStatement(
        'INSERT INTO calculation_history(calculator_id,inputs_json,result_json,created_at_micros,payload_version) VALUES (?,?,?,?,?)',
        [
          calculatorId,
          raw,
          output,
          createdAt.microsecondsSinceEpoch,
          CalculationSnapshotCodec.version,
        ],
      );
      // AFTER INSERT trigger removes old rows atomically, including for other
      // SQLite writers; a failed insert/trigger/read rolls back the whole write.
      return _read();
    });
  }

  @override
  Future<void> close() => _closing ??= database.close();
}
