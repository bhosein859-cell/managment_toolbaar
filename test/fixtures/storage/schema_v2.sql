-- Current schema contract, independently loaded for introspection tests.
CREATE TABLE favorites (
  calculator_id TEXT NOT NULL PRIMARY KEY CHECK(length(calculator_id) > 0),
  created_at_micros INTEGER NOT NULL
);
CREATE TABLE calculation_history (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  calculator_id TEXT NOT NULL CHECK(length(calculator_id) > 0),
  inputs_json TEXT NOT NULL,
  result_json TEXT NOT NULL,
  created_at_micros INTEGER NOT NULL,
  payload_version INTEGER NOT NULL DEFAULT 1 CHECK(payload_version > 0)
);
CREATE TRIGGER history_keep_ten AFTER INSERT ON calculation_history BEGIN
  DELETE FROM calculation_history WHERE id NOT IN
    (SELECT id FROM calculation_history ORDER BY id DESC LIMIT 10);
END;
PRAGMA user_version = 2;
