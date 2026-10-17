-- Historical schema contract for migration tests (not a previously released DB).
CREATE TABLE favorites (
  calculator_id TEXT NOT NULL PRIMARY KEY CHECK(length(calculator_id) > 0),
  created_at_micros INTEGER NOT NULL
);
CREATE TABLE calculation_history (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  calculator_id TEXT NOT NULL CHECK(length(calculator_id) > 0),
  inputs_json TEXT NOT NULL,
  result_json TEXT NOT NULL,
  created_at_micros INTEGER NOT NULL
);
PRAGMA user_version = 1;
