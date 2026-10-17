import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Drift's native executor bundles SQLite through sqlite3's build hook.
/// SQL is deliberately explicit: no generated ORM or build_runner is needed.
final class ToolboxDatabase extends GeneratedDatabase {
  ToolboxDatabase(super.executor);
  factory ToolboxDatabase.memory() => ToolboxDatabase(NativeDatabase.memory());
  factory ToolboxDatabase.file(File file, {bool background = true}) =>
      ToolboxDatabase(
        background
            ? NativeDatabase.createInBackground(file)
            : NativeDatabase(file),
      );

  @override
  int get schemaVersion => 2;
  // All queries and schema DDL are custom SQL; no generated table metadata.
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  static const favoritesSql = '''CREATE TABLE favorites (
    calculator_id TEXT NOT NULL PRIMARY KEY CHECK(length(calculator_id) > 0),
    created_at_micros INTEGER NOT NULL
  )''';
  static const historyV2Sql = '''CREATE TABLE calculation_history (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    calculator_id TEXT NOT NULL CHECK(length(calculator_id) > 0),
    inputs_json TEXT NOT NULL,
    result_json TEXT NOT NULL,
    created_at_micros INTEGER NOT NULL,
    payload_version INTEGER NOT NULL DEFAULT 1 CHECK(payload_version > 0)
  )''';
  static const retentionSql = '''DELETE FROM calculation_history WHERE id NOT IN
    (SELECT id FROM calculation_history ORDER BY id DESC LIMIT 10)''';
  static const retentionTriggerSql = '''CREATE TRIGGER history_keep_ten
    AFTER INSERT ON calculation_history BEGIN
    DELETE FROM calculation_history WHERE id NOT IN
      (SELECT id FROM calculation_history ORDER BY id DESC LIMIT 10);
    END''';

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => transaction(() async {
      await customStatement(favoritesSql);
      await customStatement(historyV2Sql);
      await customStatement(retentionTriggerSql);
    }),
    onUpgrade: (_, from, to) => transaction(() async {
      if (from != 1 || to != 2) {
        throw UnsupportedError(
          'نسخهٔ پایگاه داده پشتیبانی نمی‌شود؛ داده حذف نشد.',
        );
      }
      await customStatement(
        'ALTER TABLE calculation_history ADD COLUMN payload_version INTEGER NOT NULL DEFAULT 1 CHECK(payload_version > 0)',
      );
      await customStatement(retentionSql);
      await customStatement(retentionTriggerSql);
    }),
    beforeOpen: (details) async {
      if ((details.versionBefore ?? 0) > schemaVersion) {
        throw UnsupportedError(
          'پایگاه داده متعلق به نسخهٔ جدیدتر برنامه است؛ بازنویسی نشد.',
        );
      }
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA temp_store = MEMORY');
      await customStatement('PRAGMA busy_timeout = 5000');
      await customStatement('PRAGMA journal_mode = WAL');
      await customStatement('PRAGMA synchronous = FULL');
    },
  );
}
