# مرحلهٔ ۱۹ — آزمون نهایی و آماده‌سازی فایل‌ها

این مرحله ادامهٔ همان کدبیس مرحلهٔ ۱۸ است؛ بازنویسی برنامه نیست. ۷۳ ابزار، ۹ دسته، واژه‌نامهٔ محلی، SQLite/Drift، RTL، فونت و لوگوی دارای فایل محلی حفظ شده‌اند. PDF طبق نتیجهٔ مرحلهٔ ۱۷ همچنان غیرفعال است. عبارت «سازنده حسین بختیاری» حفظ شده است.

## مرز تحویل و وضعیت ساخت بومی

**این تحویل سورس، شواهد QA و دو خروجی کامپایل Android arm64 بدون امضاست؛ انتشار امضاشده یا نصب/اجرای بومی تأییدشده نیست.** کل suite: **۱۷۱۶ موفق، ۱۴ skip اختیاری، ۸۶/۸۶ فایل**؛ Python packager: **۸ موفق**. نتیجهٔ دقیق آزمون‌ها در `docs/validation/stage19/README.md` ثبت می‌شود. workflow موجود فقط فراهم شده و در این محیط اجرا نشده است.

| اقدام واقعی روی میزبان Linux با ۲ GB RAM (ابتدا بدون swap) | نتیجه |
|---|---|
| نصب Flutter 3.47.7 stable / Dart 3.13.5، JDK 17 و Android SDK | انجام شد |
| APK Release عمومی | Gradle daemon به‌علت OOM توسط کرنل کشته شد؛ موفق نیست |
| APK Release فقط arm64، با heap کمتر و یک worker | پس از توقف ناشی از فشار حافظه قطع شد؛ exit 143؛ موفق نیست |
| AAB Release فقط arm64 | اجرای واقعی `bundleRelease` شروع شد؛ بودجهٔ ۱۰۰ ثانیه تمام و timeout با SIGKILL/exit 137 پایان یافت؛ موفق نیست |
| تلاش نهایی APK Release arm64 با swap موقت ۲ GB و metaspace محلی ۱ GB | **موفق، exit 0**؛ 22,426,726 bytes؛ unsigned |
| تلاش نهایی AAB Release arm64 با همان منابع | **موفق، exit 0**؛ 22,028,241 bytes؛ unsigned |
| Windows Release | فرمان واقعاً اجرا شد و به‌علت میزبان Linux با exit 1 رد شد |
| نصب روی دستگاه، اجرای EXE بومی، امضای دیجیتال، انتشار | انجام نشده است |

لاگ‌ها: `android-apk-release.txt`، `android-apk-arm64-retry.txt`، `android-aab-release.txt`، `resource-limit.txt` و `windows-release.txt`. exit 137 تلاش AAB به‌تنهایی دلیل OOM نیست؛ در این تلاش timeout با escalation نیز اعمال شده بود. OOM تلاش نخست با پیام کرنل تأیید شده است. پس از افزودن swap موقت و اصلاح سقف metaspace، APK و AAB واقعی arm64 با موفقیت ساخته شدند؛ لاگ‌های نهایی `android-apk-arm64-release-final.txt` و `android-aab-arm64-release-final.txt` هستند. خروجی‌های unsigned جداگانه و با برچسب روشن در ZIP `management_toolbox_stage_19_android_arm64_UNSIGNED.zip` تحویل می‌شوند. APK ساخته‌شده با aapt2 بررسی شد: minSdk=26، targetSdk=36 و بدون permission اینترنت. هر دو ZIP داخلی CRC سالم و libapp/libflutter/libsqlite3 arm64 و فونت/لوگو/OFL محلی دارند. apksigner/jarsigner عمداً نبود امضا را تأیید کردند، نه موفقیت امضای انتشار. اجرای اپ روی دستگاه و ساخت/اجرای EXE Windows انجام نشده است.

## ۱. آماده‌سازی و بررسی کل پروژه

Flutter **stable 3.47.7** و Dart **3.13.5** مبنای این کدبیس‌اند. `pubspec.lock` را حفظ کنید؛ ارتقای بدون بررسی وابستگی‌ها بخشی از این مرحله نیست. نصب dependency/SDK و build اول به شبکه نیاز دارند؛ کار عادی برنامه وابسته به شبکه نیست.

```sh
flutter --version
flutter doctor -v
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
dart format --output=none --set-exit-if-changed lib test tool
python -m unittest discover -s tool/tests -v
```

Python 3.10+ برای ابزار بسته‌بندی لازم است؛ بستهٔ اضافی Python نیاز نیست. در Windows اگر launcher نصب است می‌توانید `python` را با `py -3` جایگزین کنید. برای میزبان کم‌حافظه، بدون کنارگذاشتن هیچ فایل تست:

```sh
python tool/run_test_shards.py --flutter /absolute/path/to/flutter --batch-size 1 --timeout 180 --output docs/validation/local/shards
```

نتیجهٔ موفق یعنی `files_run == files_discovered` و `all_batches_succeeded == true` در `summary.json`؛ صرف داشتن شمارندهٔ مثبت کافی نیست. تست‌های بصری اختیاریِ نیازمند flag جدا می‌توانند skip شوند؛ skip را به‌عنوان pass گزارش نکنید. تصاویر ثبت‌شدهٔ مرحلهٔ ۱۸ تست Flutter هستند، نه screenshot نصب بومی.

آزمون جدید `test/release/offline_smoke_test.dart`، مثال‌های هر ۷۳ ابزار، جست‌وجوی واژه‌نامه، ذخیرهٔ ۱۱ محاسبه و نگه‌داری ۱۰ رکورد آخر، بازگشایی دیتابیس و favorite، ورود ارقام لاتین/فارسی/عربی، فرم نامعتبر و دارایی‌های محلی را پوشش می‌دهد. `HttpOverrides`، ساخت Dart HttpClient در isolate اصلی تست را ممنوع می‌کند؛ این تست جای firewall، مهار Socket/native/isolate دیگر یا حالت پرواز دستگاه نیست. سایر تست‌های موجود، مرزها، OEE/NPV/Cp/IRR، RTL، فرم‌ها، تاریخچه و ماندگاری حذف/افزودن favorite را پوشش می‌دهند.

راستی‌آزمایی سه‌فرایندی ماندگاری (مسیر دیتابیس آزمایشی خارج مخزن):

```sh
dart run tool/verify_local_storage.dart write /absolute/scratch/release-check.sqlite
dart run tool/verify_local_storage.dart read-remove /absolute/scratch/release-check.sqlite
dart run tool/verify_local_storage.dart verify-removed /absolute/scratch/release-check.sqlite
```

والد مسیر باید موجود باشد؛ مسیر Windows مانند `$env:TEMP\release-check.sqlite` است. روی دیتابیس کاربر اجرا نکنید: ابزار دادهٔ آزمایشی می‌نویسد/حذف می‌کند. ذخیرهٔ تاریخچه دستی است و سقف ۱۰ در کل برنامه اعمال می‌شود، نه ۱۰ برای هر ابزار. دادهٔ کاربر نباید داخل بسته/لاگ قرار گیرد.

## ۲. Android — API 26+، APK و AAB

- `android/app/build.gradle.kts`: مقدار صریح **`minSdk = 26`** یعنی Android 8.0 به بالا. آن را برای حل خطای نصب پایین نیاورید.
- `compileSdk` و `targetSdk` از Flutter SDK می‌آیند؛ با SDK این مرحله مقدار ۳۶ و NDK `28.2.13676358` درخواست شد. minSdk با compile/target یکی نیست.
- Java/Kotlin target برابر ۱۷ است. JDK 17 و Android command-line tools، platform-tools، platform 36، build-tools 36.0.0 و NDK بالا را آماده و licenseها را بپذیرید. `flutter doctor --android-licenses` سپس `flutter doctor -v`.
- `android/local.properties` مسیر محلی SDK/Flutter است؛ commit یا کپی مسیر این sandbox به دستگاه دیگر ممنوع. `flutter pub get`/Flutter CLI آن را محلی تنظیم می‌کند.
- پیشنهاد عملی میزبان build: حداقل ۸ GB RAM و فضای دیسک کافی. ۲ GB این محیط **بدون swap** کافی نبود؛ در نهایت با ۲ GB swap کمکی و metaspace محلی ۱ GB ساخت arm64 موفق شد. این workaround منابع، نیاز دستگاه اجرای برنامه نیست. Gradle پروژه اکنون heap ۲ GB دارد؛ این تضمین موفقیت build روی هر میزبان نیست. override موقت منابع را در `$GRADLE_USER_HOME/gradle.properties` بیرون مخزن بگذارید.

```sh
flutter pub get --enforce-lockfile
flutter build apk --release --no-pub
flutter build appbundle --release --no-pub
# در صورت نیاز به APKهای جدا برای هر ABI:
flutter build apk --release --no-pub --split-per-abi
```

فرمان‌های نهایی واقعاً موفق در همین محیط (فقط arm64؛ universal/سایر ABIها همچنان در این مرحله موفقیت تأییدشده ندارند):

```sh
flutter build apk --release --no-pub --target-platform android-arm64
flutter build appbundle --release --no-pub --target-platform android-arm64
```

خروجی معمول APK: `build/app/outputs/flutter-apk/`؛ خروجی AAB: `build/app/outputs/bundle/release/app-release.aab`. نام دقیق unsigned APK ممکن است با نسخهٔ ابزار تغییر کند؛ فایل واقعی موجود را بررسی کنید. AAB مستقیماً با `adb install` نصب نمی‌شود؛ برای Play یا تست با bundletool مناسب است. APK arm64 فقط برای CPU سازگار است؛ وجود minSdk 26 به‌معنی سازگاری همهٔ ABIها نیست.

### امضای Android بدون افشای کلید

Fallback امضای debug برای Release حذف شده است. بدون هیچ‌یک از متغیرهای زیر، ساخت صرفاً **unsigned برای اعتبارسنجی کامپایل** است؛ انتشار یا نصب آن به‌عنوان نسخهٔ امضاشده مجاز نیست. پیکربندی ناقص عمداً خطا می‌دهد. مسیر keystore باید یک فایل واقعی با canonical path **خارج کل مخزن** باشد؛ symlink به فایل داخل مخزن نیز این شرط را دور نمی‌زند.

| متغیر محیطی | محتوا |
|---|---|
| `TOOLBOX_ANDROID_KEYSTORE` | مسیر مطلق keystore بیرون checkout/repository |
| `TOOLBOX_ANDROID_STORE_PASSWORD` | رمز مخزن کلید، از secret store |
| `TOOLBOX_ANDROID_KEY_ALIAS` | alias کلید مجاز انتشار |
| `TOOLBOX_ANDROID_KEY_PASSWORD` | رمز کلید، از secret store |

مقدار واقعی هیچ‌کدام را در README، فایل Gradle، workflow، لاگ یا shell history ننویسید. متغیرها را از secret manager به محیط تزریق کنید و همان دو فرمان build را اجرا کنید. `set -x`/echo متغیرها را روشن نکنید. در CI فایل keystore را در پوشهٔ موقت runner **بیرون checkout** بسازید و در cleanup حذف کنید؛ کد workflow عرضه‌شده عمداً به secret/signing دسترسی ندارد. `.gitignore` لایهٔ کمکی است، نه جایگزین بازبینی فایل‌های commit.

اگر هنوز کلید ندارید، روی دستگاه مورداعتماد آن را با prompt تعاملی ایجاد کنید؛ رمز را آرگومان فرمان نگذارید:

```sh
keytool -genkeypair -v -keystore /absolute/private-outside-repo/upload.jks -alias upload -keyalg RSA -keysize 3072 -validity 10000
```

از کلید و رمز خارج مخزن و با نسخهٔ پشتیبان رمزگذاری‌شده نگه‌داری کنید. کلید upload با app-signing key در Play App Signing یکی فرض نشود. مالک برنامه باید شناسهٔ اولیهٔ `com.managementtoolbox.management_toolbox`، نسخه/versionCode، آیکون، کلید و سیاست فعلی فروشگاه را پیش از نخستین انتشار تأیید کند. پس از انتشار شناسه یا کلید را بی‌برنامه عوض نکنید؛ نصب روی نسخهٔ قبلی با امضای متفاوت خطا می‌دهد.

بعد از build امضاشده:

```sh
# apksigner از Android build-tools؛ روی Windows فایل apksigner.bat است.
apksigner verify --verbose --print-certs path/to/the-actual-release.apk
# jarsigner از JDK، برای AAB؛ apksigner برای AAB نیست.
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
adb install -r path/to/the-actual-signed-release.apk
```

Fingerprint گواهی را با کلید موردانتظار صاحب برنامه مقایسه کنید؛ خودامضابودن upload certificate با خراب‌بودن امضای AAB یکی نیست. فایل unsigned تا پیش از امضا/verify قابل نصب به‌عنوان Release نیست. این مراحل امضا و نصب در sandbox انجام نشده‌اند.

## ۳. Windows 10/11 x64 — ساخت و بستهٔ کامل

ساخت روی **Windows** با Flutter stable و Visual Studio دارای workload **Desktop development with C++**، MSVC و Windows SDK سازگار انجام شود. VS Code به‌تنهایی جای toolchain C++ را نمی‌گیرد. Linux قادر به اجرای `flutter build windows` نیست.

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
flutter pub get --enforce-lockfile
flutter run -d windows
flutter build windows --release --no-pub
python tool/package_windows.py
Get-FileHash releases\management_toolbox-windows-x64.zip -Algorithm SHA256
```

ورودی پیش‌فرض ابزار: `build/windows/x64/runner/Release/`. خروجی پیش‌فرض: `releases/management_toolbox-windows-x64.zip` و فایل `.zip.sha256`. برای مسیر سفارشی:

```powershell
python tool/package_windows.py --source path\to\Release --output path\outside\Release\toolbox.zip
```

**EXE به‌تنهایی برنامهٔ کامل نیست.** کل پوشهٔ Release، با همهٔ زیرپوشه‌ها و فایل‌های تولیدشده، باید کنار هم حفظ شود؛ ابزار همهٔ فایل‌ها را آرشیو می‌کند، نه فقط فهرست شناخته‌شدهٔ امروز. حداقل‌های بررسی‌شده:

```text
Release/
  management_toolbox.exe
  flutter_windows.dll
  share_plus_plugin.dll
  url_launcher_windows_plugin.dll
  ... sqlite3*.dll در محل اصلی تولیدشده توسط native-assets hook ...
  data/
    app.so
    icudtl.dat
    flutter_assets/
      AssetManifest.bin
      assets/branding/logo.png
      assets/fonts/Vazirmatn-Regular.ttf
      assets/fonts/Vazirmatn-Bold.ttf
      assets/fonts/OFL.txt
      ... بقیهٔ تمام دارایی‌های build ...
```

محل/نام دقیق DLL SQLite ممکن است تابع نسخهٔ hook باشد؛ آن را جابه‌جا یا فقط از اینترنت دانلود نکنید. تمام native-assets خروجی build لازم‌اند. DLLهای runtime مایکروسافت مانند `VCRUNTIME140.dll`/`VCRUNTIME140_1.dll`/`MSVCP140.dll` باید طبق مجوز و روش رسمی تأمین شوند؛ روی ماشین مقصد، Microsoft Visual C++ Redistributable x64 سازگار را از مایکروسافت نصب کنید. DLLهای تصادفی را از وب یا System32 کپی نکنید. ابزار بسته‌بندی نصب runtime یا صحت ABI، زنجیرهٔ DLLها، اجرای EXE و گواهی را تضمین نمی‌کند.

ZIP شامل پوشهٔ `management_toolbox/` و `bundle-manifest.json` با اندازه/SHA256 تک‌تک فایل‌هاست. checksum ZIP تمامیت انتقال را بررسی می‌کند، **هویت ناشر یا اصالت امنیتی را ثابت نمی‌کند**. آزمون‌های Python فقط fixture مصنوعی دارند و اجرای Windows نیستند. ZIP کامل را روی Windows تمیز استخراج و EXE را از همان پوشه اجرا کنید. database کاربر در Application Support می‌ماند، نه کنار EXE؛ برای ارتقا آن را حذف نکنید. MSIX/installer در این مرحله ساخته نشده است.

### امضای Windows

گواهی معتبر Code Signing/private key یا HSM باید تحت کنترل ناشر و بیرون repository باشد. فایل PFX و رمز را در مخزن/ZIP سورس/فرمان‌خط یا لاگ ننویسید. در محیط امن، گواهی را با prompt/secret manager و `Import-PfxCertificate` و `SecureString` وارد certificate store شخصی موقت کنید؛ یا از signer سازمانی/HSM استفاده کنید. سپس با SignTool موجود در Windows SDK و thumbprint **گواهی نصب‌شده** (نه رمز خصوصی) امضا کنید:

```powershell
signtool sign /sha1 $env:TOOLBOX_WINDOWS_CERT_THUMBPRINT /s My /fd SHA256 /tr $env:TOOLBOX_TIMESTAMP_URL /td SHA256 build\windows\x64\runner\Release\management_toolbox.exe
signtool verify /pa /all /v build\windows\x64\runner\Release\management_toolbox.exe
python tool/package_windows.py
```

`TOOLBOX_TIMESTAMP_URL` باید نشانی HTTPS سرور timestamp مورداعتماد ناشر باشد. از گواهی/دسترسی مجاز خودتان استفاده کنید؛ وجود signature تضمین حذف SmartScreen یا اعتبار تجاری ناشر نیست. دارایی‌های ناشر/installer را مطابق سیاست امضا کنید و امضای vendor DLL را بی‌دلیل عوض نکنید. در runner موقت، certificate/private key و فایل موقت را در cleanup حذف کنید. **ابتدا امضا و verify، سپس بسته‌بندی/hash**؛ امضاکردن بعد از بسته‌بندی checksum را نامعتبر می‌کند. این تحویل شامل گواهی، private key یا امضای واقعی نیست.

## ۴. مسیر بدون نصب Flutter روی دستگاه شما

فایل `.github/workflows/release-validation.yml` به‌صورت دستی (`workflow_dispatch`) قابل اجراست؛ پس از قرارگرفتن **محتوای ریشهٔ پروژه** در همان repository، از Actions → Release validation → Run workflow استفاده کنید. این راهکار نصب Flutter روی دستگاه شخصی را لازم ندارد، ولی به دسترسی Actions و سهمیه/دسترسی شبکهٔ runner نیاز دارد. فایل صرفاً ارائه شده؛ هیچ run یا artifact آنلاین برای آن در این محیط ایجاد نشده است.

سه job: تحلیل/کل تست‌ها/format/Python؛ سپس ساخت **unsigned** APK و AAB روی Linux و ساخت Windows Release روی Windows و ZIP کل پوشه. jobهای build تنها پس از موفقیت QA شروع می‌شوند. artifactهای unsigned را به‌عنوان انتشار امضاشده توزیع نکنید. workflow هیچ deploy، انتشار، upload به فروشگاه یا secret پیش‌فرضی ندارد. پیش از کاربرد production، actionها را به SHAهای immutable بررسی‌شده pin کنید و سیاست حداقل‌دسترسی را حفظ کنید. برای Release واقعی، محیط حفاظت‌شده با تأیید انسانی و امضای امن جداگانه لازم است.

## ۵. عیب‌یابی

| نشانه | بررسی/راه‌حل |
|---|---|
| `Gradle daemon disappeared` یا exit 137 | لاگ OS/runner و OOM را بررسی کنید؛ exit 137 به‌تنهایی علت را ثابت نمی‌کند. RAM/فضای دیسک بیشتر، build ترتیبی و worker کمتر؛ debug-key fallback راه‌حل نیست. |
| `Exhausted heap space` در Flutter test | تست‌ها را با batch-size 1 جدا کنید؛ compiler هم RAM می‌خواهد. اجرای همزمان analyze و Android build روی میزبان ۲ GB مناسب نیست. |
| SDK/license/NDK پیدا نمی‌شود | `flutter doctor -v`، مسیر واقعی SDK/JDK و licenseها؛ minSdk را پایین نیاورید. |
| keystore خارج repository/پیکربندی ناقص | هر چهار متغیر و canonical path فایل بیرونی را اصلاح کنید؛ رمزها را چاپ نکنید. |
| APK unsigned یا امضای ناسازگار | apksigner و fingerprint را بررسی کنید؛ برای حفظ داده ابتدا راهبرد ارتقای صحیح/backup داشته باشید، uninstall داده را حذف می‌کند. |
| AAB با adb نصب نمی‌شود | AAB برای توزیع/ساخت APK با ابزار مناسب است، نه نصب مستقیم. |
| `build windows only supported on Windows hosts` | روی runner/ماشین Windows با toolchain C++ بسازید؛ Linux cross-build جایگزین نیست. |
| DLL/data missing یا اجرای EXE بلافاصله بسته می‌شود | ZIP کامل را استخراج کنید؛ معماری x64، همهٔ native-assets و VC++ runtime را بررسی کنید. فقط EXE را کپی نکنید. |
| فونت/لوگو در حالت آفلاین گم می‌شود | assets محلی و کل `data/flutter_assets` و OFL را حفظ کنید؛ دانلود زمان اجرا لازم نیست. |
| تم/داده بعد از بازکردن برنامه نیست | حساب/مسیر Application Support و دسترسی نوشتن را بررسی کنید؛ دیتابیس را برای رفع مشکل بی‌اجازه حذف نکنید. |
| PDF غیرفعال است | تصمیم آگاهانهٔ مرحلهٔ ۱۷ به‌علت شکست پذیرش متن ترکیبی؛ مشکل نصب dependency نیست. |

## ۶. دروازهٔ پذیرش بومی پیش از انتشار — هنوز باز

- [x] build موفق **unsigned arm64** APK و AAB با همان lockfile؛ minSdk 26 و نبود INTERNET در manifest کامپایل‌شدهٔ APK بررسی شد.
- [ ] ساخت موفق universal/دیگر ABIهای موردنیاز انتشار و نصب/اجرای واقعی روی دستگاه‌های هدف.
- [ ] امضا و verify با fingerprint مجاز؛ versionCode/شناسه تأییدشده؛ نصب APK روی Android API 26 و یک نسخهٔ جدیدتر.
- [ ] حذف دسترسی شبکه/حالت پرواز: ورود، ۷۳ ابزار، واژه‌نامه، ارقام `250`/`۲۵۰`/`٢٥٠`، نامعتبر/مرزی، ذخیرهٔ ۱۱ محاسبه، سقف ۱۰، خروج کامل و بازگشایی favorite/حذف آن.
- [ ] Windows Release موفق؛ امضای ناشر در صورت توزیع عمومی؛ استخراج **کل ZIP** و اجرای واقعی روی Windows 10/11 x64 تمیز با runtime لازم.
- [ ] بازگشایی/ارتقا بدون ازبین‌بردن داده؛ مسیر دارای فاصله/حروف فارسی، دسترسی عادی کاربر، نمایشگرهای ۱۰۰/۱۵۰/۲۰۰٪، متن بزرگ، RTL، صفحه‌کلید، TalkBack/Narrator.
- [ ] share بومی/clipboard، برگشت از لغو اشتراک‌گذاری، و نبود PDF ساختگی/خراب؛ تأیید عدم وجود private key/اطلاعات کاربر در artifact.

موفقیت تست Dart یا fixture بسته‌بندی، این گزینه‌های بومی را تیک نمی‌زند. گزارش مرحلهٔ ۱۸ و تصاویر آن محفوظ‌اند و به‌عنوان اجرای دستگاه مرحلهٔ ۱۹ بازبرچسب‌گذاری نشده‌اند.
