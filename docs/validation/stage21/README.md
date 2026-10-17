# تحویل ۱.۱.۱ — بیلد واقعی Android (امضاشده) و بستهٔ کامل Windows

این مرحله کدبیس مرحلهٔ ۲۰ را تغییر نمی‌دهد؛ تنها `version: 0.1.0+1` در `pubspec.yaml` به
**`1.1.1+11101`** رسید تا `versionName=1.1.1` و `versionCode=11101` (و `13101` برای split
arm64 طبق قانون `1000 × ABI` در Flutter) ساخته شود. هیچ فایل دیگری زیر `lib/`، `assets/`
یا `android/` تغییر نکرد؛ جدول ۷۳ ماشین‌حساب، فونت، لوگو و `pubspec.lock` دست‌نخورده‌اند.

میزبان build این بار **GitHub Actions** بود (runnerهای `ubuntu-latest` و `windows-latest`)،
زیرا محیط کاری که امضا در آن انجام شد دسترسی شبکه به Flutter/Android SDK/Maven نداشت و
`flutter build windows` روی Linux پشتیبانی نمی‌شود. workflow: `build-final-artifacts.yml`.

## ۱. آنچه واقعاً اجرا و سبز شد

| run | head | نتیجه |
|---|---|---|
| `39029028069` | `e063f5a9ea` | QA + Android + Windows، هر سه job موفق — مبدأ خروجی‌های تحویلی |
| `39029588357` | `1a45bcad4c` | همان سه job دوباره موفق (تغییر فقط `.github/`) |
| `39030108632` | `21127cf5a7` | job راستی‌آزمایی با `apksigner`/`aapt2` رسمی + ضمیمه‌کردن assetها |

`docs/validation/stage21/ci-runs.txt` خروجی ساختاریافتهٔ همین runها (job/step conclusion) است.
QA شامل `flutter analyze`، کل `flutter test --concurrency=1`، `dart format --set-exit-if-changed`،
بررسی جدول کاتالوگ و `generate_branding.py --check` است. لاگ خام runner از این محیط قابل
دریافت نبود (storage لاگ مسدود بود)، لذا نتیجهٔ هر step به‌صورت API ثبت شده، نه کپی متن لاگ.

## ۲. فایل‌های تحویلی و امضا

خروجی CI عمداً **unsigned** است (سیاست مخزن: هیچ keystore/رمزی در repository یا CI نیست).
امضا روی میزبان کاری، بیرون از مخزن و با کلید self-signed تازه انجام شد:

- کلید: RSA-2048، گواهی خودامضا تا ۲۰۵۶، SHA-256 fingerprint
  `881E25FC40112CAE315B4C74973965882C4289D8CB5F2C522387514A4C4CBD8F`.
- طرح‌ها: JAR v1 + APK Signature Scheme **v2 و v3** با `SHA256-RSA PKCS#1 v1.5` (id `0x0103`).
- ابزار امضا `apk_sign_ts 1.0.1`؛ ابزار راستی‌آزمایی **یک پیاده‌سازی مستقل** (`apksigtool 0.1.0`
  / `apksigcopier 1.1.1`) و سپس `apksigner` رسمی Android SDK روی runner. هر چهار APK در هر دو
  `VERIFIED` شدند (`android-signature-checks.txt`).
- پس از امضا، محتوای برنامه با بیلد مقایسه شد: ۶۶ ورودی (universal) و ۶۰ ورودی (هر split)
  بدون حتی یک تغییر CRC/size؛ تنها `META-INF` تازه، padding هم‌ترازی و APK Signing Block افزوده
  شد. `resources.arsc` و `lib/*/*.so` stored و هم‌تراز (۴ و ۴۰۹۶ بایت) هستند.
- `aapt2 dump badging`/parsing محلی AXML روی همان فایل‌های تحویلی: package
  `com.managementtoolbox.management_toolbox`، `minSdkVersion=26`، `targetSdkVersion=36`،
  `extractNativeLibs=0`، بدون `INTERNET` (`android-manifest-axml.txt`).
- **AAB unsigned ماند.** برای Google Play کلید upload خود ناشر لازم است؛ همان چهار
  متغیر `TOOLBOX_ANDROID_*` در `android/app/build.gradle.kts` این را پشتیبانی می‌کنند.
  `build-apks` از همین bundle با کلید خودتان جایگزین سالمی است.

## ۳. Windows

`flutter build windows --release` روی `windows-latest` و سپس `python tool/package_windows.py`
(بدون تغییر در ابزار). بسته: **۳۹ فایل** با کل درخت `Release` و `bundle-manifest.json`.
بررسی محلی روی همان zip (`windows-bundle-checks.txt`): هر ۱۱ فایل ضروری `REQUIRED` موجود،
DLLها از جمله `sqlite3.dll` (تولید native-assets) سر جایشان، صفر فایل خالی، CRC همهٔ ورودی‌ها
سالم، و هدر `management_toolbox.exe` یک PE با `machine=0x8664` (AMD64) است.
installer/MSIX ساخته نشد و امضای Authenticode ندارد (تصمیم ناشر، نه کمبود ابزار).

## ۴. انتشار و تطبیق هش‌ها

Release ‏`v1.1.1` با ۸ asset روی همین مخزن منتشر شد و به کامیت `e063f5a9ea` (همان کامیت
بیلد) اشاره می‌کند؛ جدول هش‌ها در `artifacts-sha256.txt`. `release-assets-digest.txt` نشان می‌دهد
digest محاسبه‌شده توسط GitHub برای هر asset **بایت‌به‌بایت** با فایل امضاشدهٔ محلی برابر است
(۸/۸)؛ یعنی آنچه دانلود می‌شود همان چیزی است که امضا و راستی‌آزمایی شد.

ضمیمه‌کردن assetها در یک job موقت CI انجام شد، چون آپلود مستقیم از محیط کاری ممکن نبود
(میزبان assetها در دسترس آن sandbox نبود)؛ آن workflow پس از تحویل حذف شده است. برای رساندن فایل‌ها از CI به میزبان امضا، خروجی‌ها موقتاً روی شاخهٔ
`arena/artifacts-inbox` (حدود ۱۴۰ مگابایت شیء گیت) گذاشته شدند و **پس از امضا آن شاخه حذف شد**؛
در نتیجه باینری در تاریخچهٔ شاخهٔ اصلی یا `main` باقی نمانده است.

## ۵. مرز پذیرش

- **نصب روی گوشی فیزیکی و اجرای EXE روی ویندوز انجام نشده است**؛ نه دستگاه/امولاتور در دسترس بود
  نه اجازهٔ نصب. تست‌های Flutter، بررسی بایتی بسته و `apksigner verify` جای آزمون native را نمی‌گیرند.
- امضای self-signed فقط سالم‌بودن و هویت ثابت بسته را برای نصب sideload تأمین می‌کند؛ هویت ناشر
  را اثبات نمی‌کند و جلوی SmartScreen را نمی‌گیرد.
- اگر keystore گم شود، نسخهٔ بعدی با همان applicationId فقط پس از uninstall نصب می‌شود و
  دادهٔ SQLite کاربر (`management_toolbox.sqlite`) از دست می‌رود.
- PDF همچنان غیرفعال است (محدودیت ثبت‌شدهٔ مرحلهٔ ۱۷) و در این مرحله دوباره فعال نشد.
- دو workflow هم‌اکنون `workflow_dispatch` هستند؛ `release-validation.yml` مال مرحلهٔ ۲۰ است و
  دست‌نخورده باقی مانده؛ `build-final-artifacts.yml` همان خروجی‌ها را staged و hash‌شده می‌سازد.
