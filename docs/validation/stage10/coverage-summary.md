# Stage 10 measured line coverage

Command: `flutter test --coverage`: 482 passed, 10 opt-in captures skipped.
Line coverage is not branch coverage or proof of correctness. Raw generated coverage is excluded from the source delivery.

| File | Hit / measurable lines | Coverage |
|---|---:|---:|
| `lib/app/catalog/finance_calculators.dart` | 148/148 | 100.0% |
| `lib/features/calculators/domain/engines/finance/break_even_engine.dart` | 37/37 | 100.0% |
| `lib/features/calculators/domain/engines/finance/compound_interest_engine.dart` | 39/39 | 100.0% |
| `lib/features/calculators/domain/engines/finance/current_ratio_engine.dart` | 22/22 | 100.0% |
| `lib/features/calculators/domain/engines/finance/finance_support.dart` | 41/41 | 100.0% |
| `lib/features/calculators/domain/engines/finance/irr_engine.dart` | 92/93 | 98.9% |
| `lib/features/calculators/domain/engines/finance/loan_payment_engine.dart` | 44/44 | 100.0% |
| `lib/features/calculators/domain/engines/finance/payback_engine.dart` | 41/41 | 100.0% |
| `lib/features/calculators/domain/engines/finance/quick_ratio_engine.dart` | 35/35 | 100.0% |
| `lib/features/calculators/domain/engines/finance/roi_engine.dart` | 22/22 | 100.0% |
| `lib/features/calculators/domain/engines/finance/wacc_engine.dart` | 46/46 | 100.0% |

**Total: 567/568 measurable lines (99.82%).**

Existing NPV engine is preserved and covered by prior and new timing tests; it is not counted as newly implemented source.
IRR retains a defensive numeric-range guard not reached by this test set. Coverage does not assert that every numerical corner case has been exercised.
