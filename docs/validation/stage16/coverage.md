# پوشش خط مرحلهٔ ۱۶

از اجرای واقعی `flutter test --coverage` روی `test/features/history` و دو آزمون session به‌روزشده. فایل خام `storage-lcov.info` کنار این گزارش است. جدول زیر فقط ذخیره‌سازی، مدل snapshot و کنترل‌گر متصل را می‌شمارد، نه کل رابط.

| فایل | خطوط پوشیده/کل |
|---|---:|
| `lib/features/history/data/drift_tool_repository.dart` | 57/57 |
| `lib/features/history/domain/tool_repository.dart` | 4/5 |
| `lib/features/home/presentation/controllers/tool_session_controller.dart` | 48/48 |
| `lib/core/storage/toolbox_database.dart` | 26/28 |
| `lib/features/history/data/calculation_snapshot_codec.dart` | 65/65 |
| `lib/features/history/domain/recent_calculation.dart` | 1/1 |
| `lib/core/storage/open_local_database.dart` | 7/7 |

**جمع: 208/211 = 98.58%**. Repository و codec و کنترل‌گر در این اجرای متمرکز پوشش خط کامل دارند؛ این به معنی پوشش شاخه یا اثبات صحت تمام حالت‌های هم‌زمان/خرابی سخت‌افزار نیست. خطوط خارج از پوشش شامل متن toString خطای دامنه، metadata جدول‌های generated استفاده‌نشده و نگهبان دفاعی قبل از بازکردن نسخهٔ جدیدتر است؛ مسیر عمومی رد نسخهٔ جدیدتر در migration آزموده شده است.
