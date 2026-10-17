# Stage 09 measured line coverage

Command: `flutter test --coverage` — 347 passed, 9 opt-in captures skipped.
Line coverage is not branch coverage or proof of correctness. Generated raw coverage is excluded from the source archive.

| File | Hit / measurable lines | Coverage |
|---|---:|---:|
| `lib/app/catalog/production_calculators.dart` | 153/153 | 100.0% |
| `lib/features/calculators/domain/engines/production/capacity_utilization_engine.dart` | 25/25 | 100.0% |
| `lib/features/calculators/domain/engines/production/cycle_time_engine.dart` | 21/21 | 100.0% |
| `lib/features/calculators/domain/engines/production/labor_productivity_engine.dart` | 22/22 | 100.0% |
| `lib/features/calculators/domain/engines/production/production_capacity_engine.dart` | 25/25 | 100.0% |
| `lib/features/calculators/domain/engines/production/production_support.dart` | 28/28 | 100.0% |
| `lib/features/calculators/domain/engines/production/smed_engine.dart` | 28/28 | 100.0% |
| `lib/features/calculators/domain/engines/production/takt_time_engine.dart` | 21/21 | 100.0% |
| `lib/features/calculators/domain/engines/production/throughput_engine.dart` | 22/22 | 100.0% |
| `lib/features/calculators/domain/engines/production/unit_production_cost_engine.dart` | 22/22 | 100.0% |
| `lib/features/calculators/domain/engines/production/wip_engine.dart` | 22/22 | 100.0% |

**Total: 389/389 measurable lines (100.0%).**

Existing OEE engine and its regression tests are preserved; they are not counted as newly implemented source here.
