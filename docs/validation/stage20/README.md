# QA و تحویل نهایی مرحلهٔ ۲۰

این مرحله ادامهٔ ZIP مرحلهٔ ۱۹ با SHA256 `86dc0637334a89d263a23b169ba5f2a3d5cc696837a5075c5dae1afc49f29058` است؛ گزارش قبلی بازبرچسب‌گذاری نشده و سورس/خروجی‌های قبلی حذف نشده‌اند.

## تغییرهای واقعی

- آیکون‌های Android در پنج density، adaptive API26، splash API26–30 و Android12+، روشن/تاریک؛ تمام تصویرها از لوگوی محلی موجود تولید شده‌اند.
- ICO چنداندازهٔ Windows، اطلاعات محصول/سازنده در Runner.rc و startup widget مشترک Flutter هنگام بازکردن repository. startup ویندوز **از first frame** است، نه splash Win32 مستقل پیش از engine؛ تأخیر مصنوعی ندارد. خطای storage و retry حفظ شده‌اند.
- README کوتاه و عملیاتی با تمام **۷۳ ابزار واقعی**: ۶۸ تخصصی + ۵ عمومی. جدول با ابزار Dart از AppCatalog تولید و با تست عدم drift بررسی می‌شود. README تاریخی به docs/history منتقل شده است.
- TECHNICAL_DOCS.md: جریان Domain/Data/UI، مدل‌های typed، schema2/payload1، retention، migration و روند توسعهٔ ماشین‌حساب جدید.
- پاک‌سازی XML/کامنت‌های template مرده و جایگزینی TODO عمومی با توضیح انتشار؛ کامنت‌های invariants و گزارش خطای واقعی حفظ شده‌اند. `lib/` هیچ print/debugPrint ندارد؛ CLIهای QA عمداً گزارش خروجی دارند. تست‌های خودکار حذف نشده‌اند.
- workflow دستی با actionهای pin‌شده به SHAهای واقعی tag، بررسی جدول/برندینگ؛ هیچ CI آنلاین یا Push انجام نشده است.
- تحویل Git مستقل از metadata ناقص قبلی؛ import baseline و commitهای محلی تفکیک‌شده. اصل `.git` ناقص دست‌نخورده است.

## بررسی‌های اجراشده و وضعیت ثبت

- `flutter analyze --no-pub`: پس از افزودن import لازم، **No issues found**؛ لاگ `analyze.txt`.
- تست متمرکز `final_delivery_test.dart` + `offline_smoke_test.dart`: **۹ موفق**؛ ۶ تست تازه و ۳ تست آفلاین قبلی. startup روی theme/platform اندروید و ویندوز، خروج از loading، خطای load/retry، viewport 360px و متن بزرگ و جدول واقعی بررسی شدند. این‌ها تست Flutter هستند، نه اجرای native Windows.
- Python: **۱۳ موفق** شامل ۸ تست بسته‌بندی قبلی و ۵ تست resource/هدر PNG/ICO/XML، اتصال manifest و نبود print در lib؛ `python-tests.txt`.
- `python tool/generate_branding.py --check`: موفق؛ Pillow فقط ابزار توسعه است، dependency اجرایی Flutter اضافه نشده است.
- کل suite دوباره اجرا شد: **۱۷۲۲ موفق، ۱۴ skip opt-in، ۸۷/۸۷ فایل**، همهٔ batchها exit 0؛ `shards/summary.json` و `shard-run.txt`. ۶ تست تازه داخل این شمارنده‌اند، نه علاوه بر آن. captureهای اختیاری در این اجرا دوباره تولید نشدند.
- format نهایی: **۲۶۶ فایل، صفر تغییر**، exit 0؛ `format.txt`.
- ابزار تولید جدول `--check`: exit 0؛ `catalog-check.txt`.
- YAML workflow با سه job و SHAهای immutable چهل‌حرفی بررسی شد؛ `workflow-check.txt`. این بررسی به‌معنی run آنلاین نیست.

## buildهای واقعی و خروجی‌های مرحلهٔ ۲۰

| بررسی | نتیجه | شاهد |
|---|---|---|
| APK Release arm64 | **موفق، exit 0**؛ 304.7s؛ 22,685,854 bytes | `android-apk-release.txt` |
| AAB Release arm64 | **موفق، exit 0**؛ 26.5s؛ 22,219,985 bytes | `android-aab-release.txt` |
| APK کامپایل‌شده | minSdk=26، targetSdk=36، بدون INTERNET | `android-apk-badging.txt`، `android-apk-permissions.txt` |
| منابع برندینگ کامپایل‌شده | launcher/adaptive foreground/legacy splash و LaunchTheme روز/شب/v31 در APK موجودند؛ attrهای framework در dump عددی‌اند | `android-resources.txt` |
| ZIP داخلی APK/AAB و فایل‌های لازم | CRC، libapp/libflutter/libsqlite3 فقط arm64 و لوگو/فونت/OFL: PASS | `android-artifact-inspection.json` |
| امضا | **عمداً unsigned**؛ APK apksigner exit 1 با DOES NOT VERIFY، AAB jarsigner exit 0 ولی jar is unsigned؛ این‌ها امضای موفق نیستند | `android-*-unsigned-check.txt` |
| Windows Release | واقعاً تلاش شد؛ **exit 1، فقط روی Windows پشتیبانی می‌شود** | `windows-release.txt` |
| Push/CI آنلاین، امضای ناشر، نصب/اجرای دستگاه | **انجام نشده** | محدودیت صریح تحویل |

این دو خروجی تازه‌اند و از مرحلهٔ ۱۹ کپی نشده‌اند. بستهٔ جداگانهٔ `management_toolbox_stage_20_android_arm64_UNSIGNED.zip` شامل هر دو، هش‌ها و هشدار نصب/انتشار است. universal/armv7/x86_64 در این مرحله موفقیت تأییدشده ندارند.

میزبان Linux، ۲ GB RAM + swap موقت ۲ GB؛ JDK17 و SDK/NDK بیرون repository نصب شدند؛ Gradle محلی heap=768 MB/metaspace=1 GB/workers=1 و lint روشن. compiler Flutter در SDK cache با heap محدود برای این میزبان اجرا شد؛ تغییر API/runtime یا dependency پروژه نبود. swap و cacheهای داخلی پروژه بعد از ساخت پاک می‌شوند و در سورس نیستند. منابع پیش‌فرض Gradle سورس همان مرحلهٔ ۱۹ است.

## شکست‌های اولیه و اصلاح

۱. analyzer دو خطای import متغیر تست platform داشت؛ import foundation اضافه و تحلیل مجدد موفق شد (`analyze-initial.txt`).
۲. دو تست platform ابتدا override را در tearDown دیر reset می‌کردند و invariant خود Flutter test شکست؛ reset به try/finally داخل callback منتقل شد، اجرای ۹ تست موفق است (`focused-tests-initial.txt` و `focused-tests.txt`). خطای محصول یا failure مخفی‌شده نبود.
۳. میزبان فقط Java11 داشت؛ تنظیم اولیهٔ مسیر فرضی JDK17 معتبر نبود. JDK17 جداگانه خارج مخزن نصب و SDK دوباره آماده شد. این شکست setup با موفقیت build برابر نیست.

## مرز پذیرش نهایی

تست asset/Widget معادل تست launcher، DPI، cold-start سیستم‌عامل یا امضای دیجیتال نیست. secret، keystore، PFX، دیتابیس کاربر، SDK، cache و swap در بستهٔ سورس/Git قرار نمی‌گیرند. APK/AAB مرحلهٔ ۱۹ branding تازهٔ مرحلهٔ ۲۰ ندارند. Windows باید روی Windows ساخته و با **تمام DLL/data/native-assets** توزیع شود؛ EXE تنها کافی نیست. امضای ناشر، نصب/اجرای دستگاه، حالت پرواز و Push آنلاین بدون شاهد موفقیت ادعا نمی‌شوند.

## حفظ کد و ساختار تحویل

مقایسه با مرحلهٔ ۱۹: **۱۳۸ فایل افزوده، ۱۶ فایل تغییرکرده، صفر حذف؛ ۱۰۰۶ فایل سورس/شواهد**. ۱۸۲ فایل قبلیِ lib/assets/dependency به‌جز composition root اپ بایت‌به‌بایت حفظ شده‌اند؛ منطق موتور، schema/storage، کاتالوگ ۷۳تایی، لوگوی مرجع، فونت و lockfile تغییر نکرده‌اند. تغییر runtime فقط اتصال startup جدید است؛ تغییرهای host منابع برندینگ‌اند. جزئیات در changed-files.json و preservation.json است.

Git bundle شامل import مستند مرحلهٔ ۱۹ و سه commit تفکیک‌شدهٔ branding، documentation/CI و QA است؛ شناسه‌های واقعی و نتیجهٔ clone/patch/whitespace در فایل بیرونی management_toolbox_stage_20_git_log.txt ثبت می‌شوند تا self-reference به commit خودش داخل سورس ایجاد نشود. Push آنلاین انجام نشده است.

لاگ‌های متنی تازه فقط از نظر پایان خط CR/LF و whitespace انتهای خطوط برای خوانایی نرمال شده‌اند؛ شمارنده‌ها، exitها و محتوا تغییر نکرده‌اند.
