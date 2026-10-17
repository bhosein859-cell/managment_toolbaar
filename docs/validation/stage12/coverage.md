# پوشش خطوط مرحلهٔ ۱۲

از اجرای واقعی `flutter test --coverage` و فایل تولیدی `coverage/lcov.info`؛ فایل خام با دستور فوق قابل بازتولید است و جزو بستهٔ سورس نیست.

| فایل | خطوط پوشیده/کل |
|---|---:|
| `lib/features/calculators/domain/engines/project/cpm_engine.dart` | 16/16 |
| `lib/features/calculators/domain/engines/project/duration_comparison_engine.dart` | 31/31 |
| `lib/features/calculators/domain/engines/project/eac_etc_engine.dart` | 66/66 |
| `lib/features/calculators/domain/engines/project/evm_performance_engine.dart` | 30/30 |
| `lib/features/calculators/domain/engines/project/pert_duration_engine.dart` | 33/33 |
| `lib/features/calculators/domain/engines/project/project_float_engine.dart` | 16/16 |
| `lib/features/calculators/domain/engines/project/sv_cv_engine.dart` | 23/23 |
| `lib/features/calculators/domain/engines/project/three_point_engine.dart` | 41/41 |
| `lib/features/calculators/domain/project/network_metrics.dart` | 28/28 |
| `lib/features/calculators/domain/project/project_network.dart` | 189/191 |
| `lib/features/calculators/domain/project/estimate_moments.dart` | 15/15 |

**جمع: 488/490 = 99.59%**. پوشش خط است، نه پوشش شاخه یا اثبات صحت تمام ورودی‌ها. دو خط بدون پوشش باقی‌اند: بازگشت ردِ اعتبارسنجی مدل از bindNetwork و مسیر دفاعی تشخیص ناسازگاری عددی شناوری. این گزارش ادعای پوشش صددرصدی ندارد.
