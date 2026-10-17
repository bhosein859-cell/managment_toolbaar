# پوشش خط مرحلهٔ ۱۴

از اجرای واقعی آزمون‌های تصمیم‌گیری با `--coverage`؛ فایل خام `decision-lcov.info` کنار این گزارش است. فقط هشت موتور جدید و چهار helper دامنه شمرده شده‌اند.

| فایل | خطوط پوشیده/کل |
|---|---:|
| `lib/features/calculators/domain/decision/decision_table.dart` | 66/66 |
| `lib/features/calculators/domain/decision/decision_tree.dart` | 146/147 |
| `lib/features/calculators/domain/engines/decision/ahp_engine.dart` | 71/71 |
| `lib/features/calculators/domain/engines/decision/cost_benefit_comparison_engine.dart` | 45/45 |
| `lib/features/calculators/domain/engines/decision/decision_matrix_engine.dart` | 29/29 |
| `lib/features/calculators/domain/engines/decision/expected_value_tree_engine.dart` | 31/31 |
| `lib/features/calculators/domain/engines/decision/topsis_engine.dart` | 63/63 |
| `lib/features/calculators/domain/engines/decision/two_option_break_even_engine.dart` | 48/48 |
| `lib/features/calculators/domain/engines/decision/weight_sensitivity_engine.dart` | 69/69 |
| `lib/features/calculators/domain/engines/decision/weighted_scoring_engine.dart` | 28/28 |
| `lib/features/calculators/domain/decision/ahp_solver.dart` | 46/46 |
| `lib/features/calculators/domain/decision/decision_math.dart` | 85/85 |

**جمع: 727/728 = 99.86%**. پوشش خط است، نه پوشش شاخه یا اثبات صحت همهٔ ورودی‌ها. شاخهٔ دفاعی خطای نوع دادهٔ داخلی در `bindTree` خارج از قرارداد ورودی نرمال‌شده پوشیده نشده است.
