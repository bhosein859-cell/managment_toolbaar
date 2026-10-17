# شواهد QA مرحلهٔ ۱۹

ادامهٔ سورس تحویلی مرحلهٔ ۱۸، بدون تغییر منطق برنامه یا وابستگی‌های اجرایی. این فایل نتایج همین اجرا را از گزارش تاریخی مرحلهٔ ۱۸ جدا می‌کند.

## نتایج قطعی آزمون‌های نهایی

| بررسی اجراشده | نتیجه | شاهد |
|---|---|---|
| Flutter 3.47.7 stable / Dart 3.13.5 | همان نسخهٔ stable پروژه | `sdk.txt` |
| flutter analyze --no-pub، پس از آخرین تغییر تست | **No issues found؛ exit 0** | `analyze.txt` |
| dart format lib test tool | **۲۶۳ فایل، ۰ تغییر در check نهایی؛ exit 0** | `format.txt` |
| کل Flutter suite، یک فایل در هر فرایند، concurrency=1 | **۱۷۱۶ موفق، ۱۴ skip اختیاری؛ ۸۶/۸۶ فایل؛ همهٔ batchها exit 0** | `shards/summary.json`، `shard-run.txt` و ۸۶ لاگ |
| سه تست جدید آفلاین با guard قابل‌اثباتِ zonal HTTP | **۳ موفق**؛ داخل شمارندهٔ ۱۷۱۶، نه علاوه بر آن | `shards/batch-86.txt`، `offline-smoke-final.txt` |
| Python Windows packager، fixture مصنوعی | **۸ موفق، ۰ skip**؛ اجرای Windows نیست | `package-tests.txt` |
| flutter pub get --offline --enforce-lockfile | **exit 0** با cache آماده؛ دانلود اولیه قبلاً انجام شده | `pub-get-offline.txt` |
| ماندگاری SQLite در سه فرایند مستقل | **write / read-remove / verify-removed: PASS، هر سه exit 0**؛ SQLite 3.54.0 | `persistence-cli.txt` |
| ساختار workflow دستی | parse YAML و سه job/read-only/manual trigger بررسی شد؛ **CI اجرا نشده** | `workflow-structure.txt` |

گزارش کامل اجرای واحدها/ویجت‌ها در هر batch محفوظ است؛ هیچ فایل تستی از کشف/اجرا حذف نشده است. `files_discovered = files_run = 86` و `all_batches_succeeded = true`. ۱۴ skip فقط captureهای بصری opt-in در ۱۰ فایل‌اند: accessibility (۱)، finance (۱)، HR (۱)، calculator (۲)، production (۱)، project (۱)، prototypes (۳)، quality/inventory (۱)، home (۱)، localization (۲). تصاویر مرحلهٔ ۱۸ محفوظ‌اند، ولی در این اجرای عادی دوباره capture نشده‌اند. skipها pass شمرده نشده‌اند.

## نگاشت معیارهای پذیرش به آزمون اجراشده

- **RTL و فارسی:** `test/accessibility/layout_contrast_test.dart`، `interaction_test.dart`، تست‌های localization و تست جدید فرم آفلاین؛ راست‌به‌چپ واقعیِ Directionality در فرم بررسی می‌شود.
- **ارقام فارسی/لاتین/عربی:** `250`، `۲۵۰` و `٢٥٠` در همان فرم واقعی و نتیجهٔ `۵۰`؛ formatter/normalizer و تست‌های قدیمی نیز دوباره اجرا شدند.
- **اعتبارسنجی و مرزها:** صفر معتبر، مقدار منفی، `NaN`، `Infinity` و overflow `1e309` در فرم جدید؛ موتورهای مستقل و مرزهای هر دسته در کل suite. هیچ NaN/Infinity به‌عنوان نتیجهٔ معتبر فرم پذیرفته نشد.
- **۷۳ ابزار:** مثال واقعی هر ۷۳ runner با قطع HTTP در isolate تست اجرا و موفقیتشان بررسی شد؛ آزمون‌های عددی/نامعتبر موجود نیز در suite کامل‌اند. این تست smoke به‌تنهایی ادعای اثبات ریاضی همهٔ ورودی‌های ممکن ندارد.
- **تاریخچهٔ حداکثر ۱۰:** ۱۱ ثبت → ۱۰ رکورد با sequenceهای ۱۱ تا ۲، بازگشایی فایل؛ suite موجود و CLI مستقل هم سیاست را بررسی کردند.
- **علاقه‌مندی و snapshot:** بازگشایی دیتابیس، ماندگاری افزوده‌شدن و حذف favorite بین سه فرایند، ورودی OEE با availability=50 و نتیجهٔ 0.4655؛ شاهد `persistence-cli.txt`.
- **آفلاین:** `HttpOverrides.runWithHttpOverrides` در zone تست؛ ابتدا ساخت عمدی `HttpClient()` باید با خطا رد شود و counter=1 گردد، سپس counter صفر و طی محاسبه/واژه‌نامه/فرم/ذخیره‌سازی هیچ تلاش HTTP نباشد. probe عمدی جزو درخواست‌های برنامه نیست. manifest اصلی سورس بدون INTERNET و فایل محلی فونت/لوگو نیز بررسی شد.

**محدودیت آفلاین:** HTTP guard فقط Dart HttpClient در zone/isolate پوشش‌داده‌شده را منع می‌کند؛ Socket، ترافیک native یا isolate دیگر و شبکهٔ واقعی OS را به‌صورت جامع قطع نمی‌کند. `pub get --offline` نیز فقط حل وابستگی با cache آماده است، نه تضمین اینکه نخستین build بدون اینترنت انجام می‌شود. حالت پرواز/فایروال و نصب بومی هنوز به دستگاه نیاز دارند.

## وضعیت build بومی

| بررسی واقعی | نتیجه | شاهد |
|---|---|---|
| APK Release فقط arm64 | **موفق، exit 0**؛ 32.0s تلاش نهایی؛ 22,426,726 bytes؛ **unsigned** | `android-apk-arm64-release-final.txt` |
| AAB Release فقط arm64 | **موفق، exit 0**؛ 18.6s تلاش نهایی؛ 22,028,241 bytes؛ **unsigned** | `android-aab-arm64-release-final.txt` |
| محتوای واقعی هر دو artifact | CRC کامل، libapp/libflutter/libsqlite3 فقط arm64، لوگو/فونت/OFL محلی: PASS | `android-artifact-inspection.json` |
| manifest باینری APK با aapt2 | **minSdk 26، targetSdk 36، بدون INTERNET** | `android-apk-badging.txt`، `android-apk-permissions.txt` |
| نبود امضای APK/AAB | APK: `DOES NOT VERIFY` و exit 1 **موردانتظار**؛ AAB: `jar is unsigned` با exit 0. این‌ها امضای موفق نیستند. | `android-apk-unsigned-check.txt`، `android-aab-unsigned-check.txt` |
| Windows Release | فرمان اجرا شد؛ **exit 1 / میزبان Linux پشتیبانی نمی‌شود** | `windows-release.txt` |
| امضای واقعی، نصب Android، اجرای app روی دستگاه، اجرای Windows، آزمون OS آفلاین | **اجرا نشده**؛ checklist باز است | `docs/stage19_release.md` |

تلاش‌های نهایی پس از افزودن **۲ GB swap موقت** و افزایش metaspace محلی Gradle از ۲۵۶ MB به **۱ GB**، بدون خاموش‌کردن lint و بدون تغییر dependency، موفق شدند. heap محلی Gradle ۷۶۸ MB، worker=1؛ تنظیم override در `gradle-local-resource-override.txt`. SDK/cache و swap همراه سورس توزیع نمی‌شوند. workflow ارائه‌شده اجرا نشده است؛ موفقیت این buildهای محلی به‌معنی موفقیت CI یا Windows نیست.

آرشیو جداگانهٔ `management_toolbox_stage_19_android_arm64_UNSIGNED.zip` شامل همین APK/AAB، هش و هشدار عدم نصب/انتشار مستقیم است. **فقط arm64** تأیید شده؛ universal، armv7 و x86_64 موفقیت تأییدشده ندارند. artifactها برای بررسی کامپایل‌اند، نه نسخهٔ امضاشدهٔ آمادهٔ نصب. APK حتی اگر در مسیر Flutter نام `app-release.apk` دارد همچنان unsigned است.

## شکست‌ها و تکرارهای آشکار

- نخستین APK عمومی: daemon با OOM کرنل کشته شد؛ `android-apk-release.txt` و `resource-limit.txt`.
- تکرار arm64 بدون swap: فشار حافظه و توقف دستی، exit 143؛ `android-apk-arm64-retry.txt`.
- AAB اولیه arm64: timeout صدثانیه‌ای و SIGKILL/exit 137؛ `android-aab-release.txt`. 137 به‌تنهایی دلیل OOM نیست.
- یک اجرای analyzer در فشار حافظه با exit -9 قطع شد؛ `analyze-interrupted.txt`. اجرای نهایی `analyze.txt` موفق است.
- یک smoke اولیه با heap محدود ۷۶۸ MB کامپایلر شکست؛ `offline-smoke-heap768-failed.txt`. heap ابزار SDK-cache برای compiler به ۱۰۲۴ MB تغییر کرد و اجرای نهایی کل suite موفق شد. `offline-smoke.txt` اجرای میانی است؛ **شاهد نهایی، `offline-smoke-final.txt`/batch-86** با guard zonal و مرزهای اضافه است.
- swap موقت ۲ GB سپس فراهم شد. نخستین تلاش با swap از Flutter compilation عبور کرد اما `lintVitalAnalyzeRelease` پلاگین path_provider_android با **Metaspace** در سقف ۲۵۶ MB شکست خورد؛ `android-apk-arm64-swap.txt`. lint خاموش یا dependency پین‌شده عوض نشد؛ سقف حافظهٔ محلی Gradle اصلاح شد.
- overrideهای heap/GC Flutter SDK و منابع Gradle فقط زیر cache میزبان بوده‌اند و داخل سورس/SDK توزیعی پروژه نیستند. تنظیم پیش‌فرض سورس Gradle از ۸ GB heap/۴ GB metaspace به ۲ GB/۱ GB تعدیل شد. تست‌ها و buildها ترتیبی اجرا شدند. cache/SDK/swap کلید یا خروجی قابل انتشار برنامه نیستند.

## حفظ کدبیس و تحویل

مقایسه با ZIP مرحلهٔ ۱۸ انجام شد: **۱۳۰ فایل افزوده، ۳ فایل تغییرکرده، ۰ فایل حذف‌شده**. فهرست قطعی تغییرها و hash فایل‌های حفظ‌شده در `changed-files.json` و `preservation.json` همراه بسته ثبت شده‌اند. سه فایل قبلیِ تغییرکرده فقط README، پیکربندی امضای Android و بودجهٔ منابع Gradle هستند. `lib/`، دارایی‌های `assets/` و هر دو `pubspec.yaml`/`pubspec.lock` از نظر بایت با مرحلهٔ ۱۸ یکسان‌اند (۱۸۳ فایل). منطق محاسبات، storage/schema، branding و حالت PDF دست‌نخورده‌اند.

راهنمای build، امضای بیرون repository، minSdk 26، DLLها، ZIP کامل Windows، رفع اشکال و دروازهٔ باز دستگاه: [`../../stage19_release.md`](../../stage19_release.md). بدون اجرای Windows/دستگاه و امضای مجاز، تحویل را «انتشار نهاییِ آزموده‌شده و امضاشده» معرفی نکنید.
