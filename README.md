# جعبه‌ابزار مدیریت | Management Toolbox

برنامهٔ فارسی، راست‌به‌چپ و آفلاین برای Android 8.0+ (**API 26+**) و Windows 10/11 **x64**.

**سازنده حسین بختیاری** · ۷۳ ماشین‌حساب در ۹ دسته · تاریخچهٔ دستی با سقف ۱۰ رکورد · علاقه‌مندی ماندگار · واژه‌نامهٔ محلی · فونت Vazirmatn محلی با OFL.

## خروجی نهایی ۱.۱.۱ — فایل‌های آمادهٔ نصب

بیلد واقعی Android و Windows روی GitHub Actions ساخته و **[Release ‏v1.1.1](https://github.com/bhosein859-cell/managment_toolbaar/releases/tag/v1.1.1)** منتشر شد
(`versionName=1.1.1`, `versionCode=11101`, کد برنامه برابر مرحلهٔ ۲۰):

- **Android:** چهار APK **امضاشده** (universal و سه split بر پایهٔ ABI) با کلید self-signed تازه؛
  برای نصب مستقیم روی Android 8.0+. AAB هم در Release است و برای Google Play باید با کلید upload
  خود ناشر امضا شود. `apksigner verify` رسمی SDK هر چهار APK را تأیید کرد.
- **Windows 10/11 x64:** `management_toolbox-1.1.1-windows-x64-portable.zip` — **کل درخت Release**
  (۳۹ فایل: exe، `flutter_windows.dll`، پلاگین‌ها، `sqlite3.dll` و تمام `data/`) با SHA256.
  استخراج کنید و `management_toolbox\management_toolbox.exe` را اجرا کنید؛ EXE تنها کافی نیست.
- **بازتولید:** `Actions → Final release build (Android + Windows)` روی همین مخزن؛ سه job موازی
  QA/Android/Windows و سپس `python tool/package_windows.py`. امضا در CI انجام **نمی‌شود**.
- **مرز:** نصب روی گوشی فیزیکی و اجرای EXE روی ویندوز آزمون نشد؛ keystore، کلید خصوصی و
  رمزها هیچ‌گاه داخل مخزن یا لاگ CI قرار نگرفتند. شواهد: [گزارش مرحله](docs/validation/stage21/README.md).

## وضعیت تحویل مرحلهٔ ۲۰

همان کدبیس مرحلهٔ ۱۹ حفظ شده است. تعداد «۶۸» در درخواست با کاتالوگ واقعی تطابق ندارد: **۶۸ ابزار تخصصی + ۵ ابزار عمومی = ۷۳ ماشین‌حساب**؛ هیچ ابزار قبلی حذف نشده است. جدول انتهای README از `AppCatalog` تولید می‌شود.

- آیکون Android (adaptive و density fallback)، ICO چنداندازهٔ Windows و splash نهایی بر اساس لوگوی موجود تنظیم شده‌اند.
- Android دارای splash بومی API 26–30 و API 31+ روشن/تاریک است. Windows صفحهٔ شروع برنددار Flutter را **از نخستین frame هنگام خواندن دیتابیس** نشان می‌دهد؛ splash مستقلِ Win32 پیش از راه‌اندازی engine ادعا نمی‌شود. تأخیر مصنوعی اضافه نشده است.
- تحلیل نهایی بدون مسئله؛ **۱۷۲۲ تست Flutter موفق، ۱۴ capture اختیاری skip، ۱۳ تست Python موفق**.
- [گزارش واقعی این مرحله](docs/validation/stage20/README.md) و [معماری و توسعه](TECHNICAL_DOCS.md) همراه پروژه‌اند.
- APK/AAB مرحلهٔ ۲۰ **بدون امضا** بودند و Windows Release روی آن میزبان Linux قابل ساخت نبود. وضعیت بیلد نهایی در بخش بالا با workflow جدید و Release ‏`v1.1.1` جای همان بند را می‌گیرد.
- خروجی‌های Android مرحلهٔ ۱۹، **unsigned arm64 و مربوط به سورس مرحلهٔ ۱۹** هستند؛ لوگو/splash مرحلهٔ ۲۰ در آن‌ها نیست. آن‌ها را build جدید مرحلهٔ ۲۰ معرفی نکنید. نصب دستگاه و Windows بومی همچنان نیازمند آزمون هدف‌اند.
- PDF طبق شکست پذیرش متن ترکیبی در مرحلهٔ ۱۷ غیرفعال مانده است. وعدهٔ خروجی PDF سالم داده نمی‌شود.

## ۱. نصب پیش‌نیازها

- **Flutter 3.47.7 stable / Dart 3.13.5**؛ فایل `.flutter-version` و `pubspec.lock` را حفظ کنید.
- Android: **JDK 17**، Android SDK/platform 36، build-tools 36.0.0، platform-tools و NDK `28.2.13676358` مطابق Flutter این پروژه. `minSdk=26` با compileSdk/targetSdk یکی نیست.
- Windows: میزبان Windows و Visual Studio با workload **Desktop development with C++**، MSVC و Windows SDK. VS Code به‌تنهایی کافی نیست.
- Python 3.10+ فقط برای QA و بسته‌بندی Windows؛ برای اجرای برنامه لازم نیست.

```sh
flutter --version
flutter doctor -v
# فقط برای توسعهٔ Android:
flutter doctor --android-licenses
flutter pub get --enforce-lockfile
```

محتوای ZIP را استخراج و وارد پوشهٔ دارای `pubspec.yaml` شوید. مسیرهای شخصی `android/local.properties` را commit نکنید؛ Flutter آن‌ها را محلی می‌سازد. دریافت SDK/dependency و build اول شبکه می‌خواهد؛ محاسبه، تاریخچه و واژه‌نامه در زمان اجرای برنامه به شبکه وابسته نیستند.

## ۲. اجرای توسعه

```sh
flutter devices
flutter run -d DEVICE_ID
# فقط روی Windows:
flutter run -d windows
```

`DEVICE_ID` را با شناسهٔ واقعی دستگاه جایگزین کنید. دادهٔ favorites/history در Application Support حساب کاربر، داخل `management_toolbox.sqlite` نگه‌داری می‌شود؛ دیتابیس واقعی کاربر را commit یا برای رفع اشکال بی‌اجازه حذف نکنید. تم/کاهش حرکت در پیاده‌سازی فعلی تنظیم درون‌حافظه‌ای نشست هستند، نه جدول SQLite.

## ۳. تست و بررسی کیفیت

```sh
flutter analyze
flutter test --concurrency=1
dart format --output=none --set-exit-if-changed lib test tool
python -m unittest discover -s tool/tests -v
dart run tool/update_calculator_table.dart --check
```

روی میزبان کم‌حافظه، همهٔ فایل‌ها را در فرایندهای جدا اجرا کنید؛ تستی حذف نمی‌شود:

```sh
python tool/run_test_shards.py --flutter /absolute/path/to/flutter --batch-size 1 --timeout 180 --output docs/validation/local/shards
```

در summary باید `files_discovered == files_run` و `all_batches_succeeded == true` باشد. captureهای تصویری opt-in با skip گزارش می‌شوند، نه pass. تست‌های مرحلهٔ ۱۹: **۱۷۱۶ موفق، ۱۴ skip در ۸۶ فایل**؛ این آمار تاریخی است و به‌عنوان اجرای مرحلهٔ ۲۰ بازبرچسب‌گذاری نشده است. آزمون HTTP فقط zone/isolate تست را پوشش می‌دهد؛ حالت پرواز و رفتار native باید روی دستگاه بررسی شوند.

تست‌های خودکار پروژه حذف نشده‌اند. در کد اجرایی `lib/` دستور `print/debugPrint` تشخیصی وجود ندارد؛ خروجی CLI ابزارهای QA و گزارش خطاهای واقعی عمداً حفظ شده‌اند.

## ۴. بیلد Android — APK و AAB

دستورات دقیق از ریشهٔ پروژه:

```sh
flutter pub get --enforce-lockfile
flutter build apk --release --no-pub
flutter build appbundle --release --no-pub
# اختیاری: APK جداگانه برای هر ABI
flutter build apk --release --no-pub --split-per-abi
# اختیاری: فقط arm64
flutter build apk --release --no-pub --target-platform android-arm64
flutter build appbundle --release --no-pub --target-platform android-arm64
```

خروجی APK: `build/app/outputs/flutter-apk/`؛ AAB: `build/app/outputs/bundle/release/app-release.aab`. AAB مستقیماً با `adb install` نصب نمی‌شود. `android/app/build.gradle.kts` مقدار **`minSdk = 26`** دارد. برای رفع خطا این مقدار را پایین نیاورید.

### امضای امن

بدون متغیرهای زیر، Release **unsigned، صرفاً برای بررسی کامپایل** است؛ fallback به کلید debug وجود ندارد:

- `TOOLBOX_ANDROID_KEYSTORE`: مسیر واقعی فایل keystore **خارج کل repository**
- `TOOLBOX_ANDROID_STORE_PASSWORD`
- `TOOLBOX_ANDROID_KEY_ALIAS`
- `TOOLBOX_ANDROID_KEY_PASSWORD`

هر چهار مقدار باید توسط secret manager/محیط امن تزریق شوند؛ پیکربندی ناقص یا keystore داخل repository رد می‌شود. رمز را در فرمان، README، Gradle، لاگ، history یا workflow ننویسید. از `set -x` استفاده نکنید. workflow همراه پروژه عمداً secret انتشار ندارد. کلید upload و کلید Play App Signing را یکی فرض نکنید. پیش از انتشار، ناشر شناسهٔ اولیهٔ `com.managementtoolbox.management_toolbox` و versionCode را تأیید کند.

پس از ساخت امضاشده، گواهی/امضا را با ابزار مناسب بررسی کنید:

```sh
apksigner verify --verbose --print-certs path/to/signed-release.apk
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
adb install -r path/to/signed-release.apk
```

apksigner برای APK است، نه AAB. fingerprint باید با گواهی مجاز ناشر تطبیق داده شود. جزئیات کلید، منابع build و محدودیت‌ها: [راهنمای Release](docs/stage19_release.md).

## ۵. بیلد و بسته‌بندی Windows

این دستورات را روی **Windows** اجرا کنید؛ Linux cross-build این هدف را پشتیبانی نمی‌کند:

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
flutter pub get --enforce-lockfile
flutter build windows --release --no-pub
python tool/package_windows.py
Get-FileHash releases\management_toolbox-windows-x64.zip -Algorithm SHA256
```

**EXE تنها بستهٔ کامل نیست.** تمام `build/windows/x64/runner/Release/` باید با ساختار اصلی حفظ شود:

- `management_toolbox.exe` و `flutter_windows.dll`
- `share_plus_plugin.dll` و `url_launcher_windows_plugin.dll`
- DLL SQLite/native-assets، در محل تولیدشده توسط build
- تمام `data/` شامل `app.so`، `icudtl.dat`، `flutter_assets/`، فونت، لوگو و OFL

ابزار بسته‌بندی کل درخت را به `releases/management_toolbox-windows-x64.zip` تبدیل می‌کند و inventory و SHA256 می‌نویسد؛ فقدان اجزای ضروری، symlink و EXE تنها را رد می‌کند. این بررسی جای اجرای واقعی یا بررسی امضای EXE نیست. Microsoft VC++ Redistributable x64 سازگار ممکن است روی مقصد لازم باشد؛ DLL تصادفی از وب یا System32 کپی نکنید.

برای امضای Windows، private key/PFX/رمز خارج repository و تحت کنترل ناشر بمانند. از certificate store/HSM امن و SignTool استفاده کنید؛ **اول امضا و verify، سپس بسته‌بندی/hash**. SHA256 هویت ناشر را اثبات نمی‌کند. روش کامل در [راهنمای Release](docs/stage19_release.md) آمده است. این پروژه installer/MSIX آمادهٔ تأییدشده تحویل نمی‌دهد.

## ۶. آیکون و Splash

لوگوی مرجع دست‌نخورده: `assets/branding/logo.png`. برای بازتولید ابزارهای برندینگ (فقط توسعه، بدون dependency جدید Flutter):

```sh
python -m pip install -r tool/requirements-branding.txt
python tool/generate_branding.py
python tool/generate_branding.py --check
```

Android: آیکون adaptive API26 و PNGهای 48/72/96/144/192؛ splash روشن/تاریک و Android12+. Windows: فایل ICO با اندازه‌های 16 تا 256، متصل به `Runner.rc`، و startup widget محلی. قبل از انتشار، maskهای launcher، cold-start و تغییر DPI را واقعاً روی دستگاه بررسی کنید؛ آزمایش هدر فایل یا widget معادل اجرای native نیست.

## ۷. آماده‌سازی GitHub و Push

workflow دستی `.github/workflows/release-validation.yml`: Actions → Release validation → Run workflow. QA سپس build Android unsigned و Windows/ZIP کامل را روی runnerهای مناسب انجام می‌دهد. **ارائهٔ workflow به‌معنی اجرای CI یا Push انجام‌شده نیست.** actionها در این تحویل به SHAهای immutable نسخه‌های انتخاب‌شده pin شده‌اند؛ پیش از production بازبینی امنیتی و سیاست به‌روزرسانی همچنان لازم است.

[راهنمای تحویل Git](docs/stage20_github_handoff.md) شامل Git bundle، patch و روش حفظ تاریخچهٔ repository فعلی است. credential، token، keystore، PFX، دیتابیس شخصی، build و SDK را Push نکنید. هیچ remote/شناسهٔ GitHub ساختگی تنظیم نشده است. هرگز برای جاانداختن تحویل، تاریخچهٔ موجود را force-push نکنید.

## ۸. رفع اشکال و مستندات

| مسئله | اقدام |
|---|---|
| Gradle daemon disappeared / Metaspace / heap | منابع RAM/swap، لاگ OS و سقف حافظهٔ Gradle را بررسی کنید؛ analyze/test/build را روی میزبان کوچک همزمان اجرا نکنید. lint یا امضا را برای پنهان‌کردن خطا دور نزنید. |
| Android SDK/NDK/license | `flutter doctor -v` و مسیر واقعی SDK/JDK؛ minSdk را پایین نیاورید. |
| APK نصب نمی‌شود | unsigned بودن، ABI، API و fingerprint/امضای نسخهٔ قبلی را بررسی کنید؛ uninstall می‌تواند داده را حذف کند. |
| EXE به‌تنهایی اجرا نمی‌شود | کل Release را استخراج کنید؛ DLLها، native-assets، x64 و VC++ runtime رسمی را بررسی کنید. |
| آیکون قبلی دیده می‌شود | build تازه، نصب/به‌روزرسانی صحیح و cache launcher؛ پاک‌سازی دادهٔ کاربر پیش‌فرض راه‌حل نیست. |
| splash در شروع سریع دیده نمی‌شود | Windows پس از اولین frame و فقط تا آماده‌شدن دیتابیس نمایش می‌دهد؛ عمداً delay ندارد. |
| PDF غیرفعال است | محدودیت ثبت‌شدهٔ رندر متن ترکیبی؛ دوباره فعال نشده است. |

- [TECHNICAL_DOCS.md](TECHNICAL_DOCS.md): معماری، مدل داده و افزودن ماشین‌حساب
- [گزارش مرحلهٔ ۲۰](docs/validation/stage20/README.md)
- [گزارش و buildهای مرحلهٔ ۱۹](docs/validation/stage19/README.md)
- [آرشیو README مراحل ۱ تا ۱۹](docs/history/README_stages_01_to_19.md)

## فهرست کامل ماشین‌حساب‌های پیاده‌شده

**۶۸ ابزار تخصصی + ۵ ابزار عمومی = ۷۳ مورد.** جدول فقط ابزارهای موجود در کاتالوگ اجرایی است؛ برنامهٔ آینده یا calculator-demo را به آن اضافه نمی‌کند. برای تغییر کاتالوگ، سپس `dart run tool/update_calculator_table.dart` و حالت `--check` را اجرا کنید.

<!-- CALCULATORS:START -->
| ردیف | دسته | شناسهٔ پایدار | نام فارسی | English |
|---:|---|---|---|---|
| 1 | تولید | `oee` | اثربخشی کلی تجهیزات — OEE | Overall Equipment Effectiveness |
| 2 | تولید | `takt_time` | زمان تکت — Takt Time | Takt Time |
| 3 | تولید | `production_capacity` | ظرفیت تولید | Production Capacity |
| 4 | تولید | `labor_productivity` | بهره‌وری نیروی کار | Labor Productivity |
| 5 | تولید | `cycle_time` | زمان سیکل | Cycle Time |
| 6 | تولید | `smed` | کاهش زمان تعویض — SMED | SMED Setup Reduction |
| 7 | تولید | `unit_production_cost` | هزینهٔ تولید واحد | Unit Production Cost |
| 8 | تولید | `wip` | موجودی در جریان ساخت — WIP | Work In Process |
| 9 | تولید | `throughput` | نرخ خروجی — Throughput | Throughput Rate |
| 10 | تولید | `capacity_utilization` | نرخ بهره‌برداری از ظرفیت | Capacity Utilization |
| 11 | مالی | `npv` | ارزش فعلی خالص — NPV | Net Present Value |
| 12 | مالی | `irr` | نرخ بازده داخلی — IRR | Internal Rate of Return |
| 13 | مالی | `payback` | دورهٔ بازگشت سرمایه | Simple Payback Period |
| 14 | مالی | `roi` | بازده سرمایه‌گذاری — ROI | Return on Investment |
| 15 | مالی | `current_ratio` | نسبت جاری | Current Ratio |
| 16 | مالی | `quick_ratio` | نسبت آنی | Quick Ratio |
| 17 | مالی | `wacc` | میانگین موزون هزینهٔ سرمایه — WACC | Weighted Average Cost of Capital |
| 18 | مالی | `compound_interest` | سود مرکب | Compound Interest |
| 19 | مالی | `loan_payment` | قسط ثابت وام | Loan Payment |
| 20 | مالی | `break_even` | نقطهٔ سربه‌سر | Break Even Point |
| 21 | کیفیت | `cp` | قابلیت بالقوهٔ فرایند — Cp | Process Capability Index |
| 22 | کیفیت | `cpk` | قابلیت مرکزدار — Cpk | Process Capability Index Cpk |
| 23 | کیفیت | `pp` | عملکرد بالقوه — Pp | Process Performance Index Pp |
| 24 | کیفیت | `ppk` | عملکرد مرکزدار — Ppk | Process Performance Index Ppk |
| 25 | کیفیت | `dpmo` | نقص در میلیون فرصت — DPMO | Defects Per Million Opportunities |
| 26 | کیفیت | `sigma_level` | برآورد سطح سیگما | Equivalent Sigma Level |
| 27 | کیفیت | `xbar_control` | داده‌های نمودار کنترل X-bar | X-bar Control Chart Data |
| 28 | کیفیت | `coq` | هزینهٔ کیفیت — COQ | Cost of Quality |
| 29 | انبار | `eoq` | مقدار اقتصادی سفارش — EOQ | Economic Order Quantity |
| 30 | انبار | `rop` | نقطهٔ سفارش مجدد — ROP | Reorder Point |
| 31 | انبار | `safety_stock` | ذخیرهٔ اطمینان آماری | Safety Stock |
| 32 | انبار | `abc` | طبقه‌بندی ABC موجودی | ABC Inventory Classification |
| 33 | انبار | `inventory_turnover` | نرخ گردش موجودی | Inventory Turnover |
| 34 | انبار | `days_inventory` | روزهای موجودی | Days Inventory Outstanding |
| 35 | انبار | `inventory_holding_cost` | هزینهٔ نگهداری موجودی | Inventory Holding Cost |
| 36 | انبار | `reorder_interval` | فاصلهٔ زمانی بازسفارش | Reorder Interval |
| 37 | پروژه | `pert_duration` | برآورد مدت PERT | PERT Expected Duration |
| 38 | پروژه | `cpm` | CPM و مسیر بحرانی | Critical Path Method CPM |
| 39 | پروژه | `project_float` | شناوری کل و آزاد پروژه | Total and Free Float |
| 40 | پروژه | `evm_performance` | شاخص‌های EVM؛ SPI و CPI | Earned Value Performance SPI CPI |
| 41 | پروژه | `three_point` | برآورد سه‌نقطه‌ای | Three-point Estimation |
| 42 | پروژه | `eac_etc` | برآورد EAC و ETC | Estimate at Completion EAC ETC |
| 43 | پروژه | `sv_cv` | انحراف زمان‌بندی و هزینه؛ SV/CV | Schedule and Cost Variance SV CV |
| 44 | پروژه | `duration_comparison` | مقایسهٔ مدت برنامه و واقعی | Planned versus Actual Duration |
| 45 | منابع انسانی | `cost_per_hire` | هزینهٔ استخدام به‌ازای هر جذب | Cost per Hire |
| 46 | منابع انسانی | `employee_turnover` | نرخ ترک خدمت کارکنان | Employee Turnover Rate |
| 47 | منابع انسانی | `employee_productivity` | بهره‌وری نیروی کار؛ خروجی بر نفرساعت | Labor Productivity per Worked Hour |
| 48 | منابع انسانی | `training_roi` | بازده برآوردی آموزش؛ ROI | Estimated Training ROI |
| 49 | منابع انسانی | `replacement_time` | زمان تکمیل جایگزینی؛ میانگین مدت | Replacement Completion Time |
| 50 | منابع انسانی | `absence_cost` | هزینهٔ مستقیم غیبت با پرداخت | Direct Paid Absence Cost |
| 51 | تصمیم‌گیری | `ahp` | AHP؛ اولویت و سازگاری | AHP Priorities and Consistency |
| 52 | تصمیم‌گیری | `topsis` | رتبه‌بندی TOPSIS | TOPSIS Vector Normalization |
| 53 | تصمیم‌گیری | `decision_matrix` | ماتریس تصمیم با نرمال‌سازی | Min-max Decision Matrix |
| 54 | تصمیم‌گیری | `expected_value_tree` | درخت تصمیم؛ ارزش مورد انتظار | Decision Tree Expected Monetary Value |
| 55 | تصمیم‌گیری | `weight_sensitivity` | تحلیل حساسیت تک‌معیار وزن | One-at-a-time Weight Sensitivity |
| 56 | تصمیم‌گیری | `weighted_scoring` | امتیازدهی وزنی روی مقیاس مشترک | Weighted Scoring Common Scale |
| 57 | تصمیم‌گیری | `cost_benefit_comparison` | مقایسهٔ هزینه و منفعت دو گزینه | Two-option Cost Benefit Comparison |
| 58 | تصمیم‌گیری | `two_option_break_even` | نقطهٔ سربه‌سر هزینهٔ دو گزینه | Two-option Cost Crossover |
| 59 | اقتصاد مهندسی | `time_value_money` | ارزش زمانی پول؛ رشد مرکب | Time Value of Money |
| 60 | اقتصاد مهندسی | `future_present_factor` | عامل F/P | Single Payment Compound Amount Factor |
| 61 | اقتصاد مهندسی | `present_future_factor` | عامل P/F | Single Payment Present Worth Factor |
| 62 | اقتصاد مهندسی | `future_annuity_factor` | عامل F/A | Uniform Series Compound Amount Factor |
| 63 | اقتصاد مهندسی | `annuity_future_factor` | عامل A/F | Sinking Fund Factor |
| 64 | اقتصاد مهندسی | `present_annuity_factor` | عامل P/A | Uniform Series Present Worth Factor |
| 65 | اقتصاد مهندسی | `annuity_present_factor` | عامل A/P | Capital Recovery Factor |
| 66 | اقتصاد مهندسی | `straight_line_depreciation` | استهلاک خط مستقیم | Straight Line Depreciation |
| 67 | اقتصاد مهندسی | `declining_balance_depreciation` | استهلاک ماندهٔ نزولی | Declining Balance Depreciation |
| 68 | اقتصاد مهندسی | `inflation_adjustment` | تعدیل مبلغ اسمی با تورم | Inflation Adjusted Purchasing Power |
| 69 | ابزارهای عمومی | `percentage_of` | درصدی از مقدار | Percentage of Amount |
| 70 | ابزارهای عمومی | `percentage_change` | درصد تغییر | Percentage Change |
| 71 | ابزارهای عمومی | `percentage_base` | مقدار پایه از درصد | Base from Percentage |
| 72 | ابزارهای عمومی | `discount` | محاسبهٔ تخفیف | Discount |
| 73 | ابزارهای عمومی | `unit_conversion` | تبدیل واحد | Unit Conversion |
<!-- CALCULATORS:END -->
