# پوشش خط مرحلهٔ ۱۵

از اجرای واقعی آزمون‌های اقتصاد مهندسی با `--coverage`؛ فایل خام `economics-lcov.info` کنار این گزارش است. فقط ۱۰ موتور جدید و helper مشترک دامنه شمرده شده‌اند.

| فایل | خطوط پوشیده/کل |
|---|---:|
| `lib/features/calculators/domain/engines/engineering_economics/annuity_future_factor_engine.dart` | 14/14 |
| `lib/features/calculators/domain/engines/engineering_economics/annuity_present_factor_engine.dart` | 14/14 |
| `lib/features/calculators/domain/engines/engineering_economics/declining_balance_depreciation_engine.dart` | 57/57 |
| `lib/features/calculators/domain/engines/engineering_economics/future_annuity_factor_engine.dart` | 14/14 |
| `lib/features/calculators/domain/engines/engineering_economics/future_present_factor_engine.dart` | 14/14 |
| `lib/features/calculators/domain/engines/engineering_economics/inflation_adjustment_engine.dart` | 29/29 |
| `lib/features/calculators/domain/engines/engineering_economics/present_annuity_factor_engine.dart` | 14/14 |
| `lib/features/calculators/domain/engines/engineering_economics/present_future_factor_engine.dart` | 14/14 |
| `lib/features/calculators/domain/engines/engineering_economics/straight_line_depreciation_engine.dart` | 48/48 |
| `lib/features/calculators/domain/engines/engineering_economics/time_value_money_engine.dart` | 32/32 |
| `lib/features/calculators/domain/engineering_economics/engineering_math.dart` | 88/90 |

**جمع: 338/340 = 99.41%**. پوشش خط است، نه پوشش شاخه یا اثبات صحت همهٔ ورودی‌ها. دو خط پوشیده‌نشده در helper، نگهبان داخلی لگاریتم عامل با دورهٔ صفر و شاخهٔ دفاعی حالت ازقبل پردازش‌شده‌اند؛ مسیرهای عمومی صفر دوره جداگانه آزموده شده‌اند.
