# مستندات فنی جعبه‌ابزار مدیریت

مبنای این سند **کد واقعی مرحلهٔ ۲۰** است: Flutter 3.47.7 stable / Dart 3.13.5، Android API26+ و Windows x64؛ ۷۳ ماشین‌حساب در ۹ دسته. README آرشیوی سند وضعیت فعلی معماری نیست.

## ۱. معماری و جهت وابستگی

ساختار Feature-based با تفکیک سبک Domain/Data/Presentation:

```text
lib/main.dart                         bootstrap و مدیریت خطای واقعی
lib/app/app.dart                     composition root، session و ThemeScope
lib/app/catalog/                     تعریف ماشین‌حساب‌ها و registry موتورها
lib/app/routing/                     routeها، CalculatorRequest و اتصال callbackها
lib/core/storage/                    مسیر پایدار و SQLite/Drift schema/migration
lib/core/utils/                      نرمال‌سازی/قالب‌بندی و جست‌وجو
lib/core/widgets/                    اجزای مشترک، خطا و AppStartupSplash
lib/features/calculators/domain/     قراردادها، مدل‌ها، normalizer و موتورهای مستقل
lib/features/calculators/presentation/  فرم generic، نتیجه و بخش‌های آموزشی
lib/features/*/domain/               موتورهای تخصصی بعضی دسته‌ها (مانند utilities)
lib/features/history/{domain,data,presentation}/
lib/features/home/                   ToolCatalog، session و صفحات جست‌وجو/دسته
lib/features/glossary/               واژه‌نامهٔ مشتق‌شده از کاتالوگ محلی
lib/features/{welcome,settings,utilities}/presentation/
android/                            host Kotlin و منابع بومی launch/icon
windows/runner/                     host Win32/C++، منابع ICO و metadata
```

Domain محاسبات به Widget، مسیر فایل، Drift یا سرویس شبکه وابسته نیست. UI فقط از `CalculatorRunner` استفاده می‌کند؛ storage از قرارداد `ToolRepository` پیروی می‌کند. `ManagementToolboxApp` repository را inject می‌کند؛ مسیر production دیتابیس واقعی است و روی شکست I/O به memory fallback نمی‌کند. repository حافظه‌ای فقط fixture/تست است.

### مسیر محاسبه

```text
RawCalculatorInput (متن فرم/فهرست/انتخاب)
  → InputNormalizer (ارقام، نوع، محدوده، درصد)
  → CalculatorInput (مقادیر canonical)
  → CalculatorEngine<I>.bind (اعتبارسنجی بین‌فیلدی)
  → BoundInput<I> / RejectedInput<I>
  → calculate(I پارامتر immutable)
  → CalculationSuccess(CalculationResult) / CalculationFailure(issues)
  → نمایش/قالب‌بندی و ذخیرهٔ دستی snapshot
```

`formulaLatex` فقط برای آموزش و نمایش است؛ هیچ eval، تفسیر فرمول رشته‌ای یا اجرای arbitrary code وجود ندارد. UI محاسبهٔ تجاری را دوباره پیاده نمی‌کند. نرمال‌سازی موفق به‌تنهایی معتبر بودن معنای دامنه را ثابت نمی‌کند؛ denominator، ترتیب زمان، بازهٔ نرخ و شرط‌های بین‌فیلدی در `bind`/engine بررسی می‌شوند.

## ۲. مدل دادهٔ محاسبات

منبع اصلی: `lib/features/calculators/domain/calculator_domain.dart` که قراردادها را export می‌کند.

| مدل | نقش و invariant |
|---|---|
| `CalculatorCategoryId` / `CalculatorCategory` | ۹ شناسهٔ enum؛ نام فارسی/انگلیسی و توضیح دسته |
| `CalculatorDefinition` | id پایدار، categoryId، نام‌ها/aliases، توضیح، LaTeX، assumptions، fields، examples و relatedTerms |
| `InputFieldDefinition` و زیرنوع‌ها | فیلد عددی/انتخابی/فهرست/ساختاریافته، defaults، واحد، help و range؛ از مدل موجود استفاده شود |
| `RawCalculatorInput` | map immutable از شناسهٔ فیلد به `RawFieldInput`؛ ورودی خام برای بازسازی دقیق فرم نگه‌داری می‌شود |
| `RawTextInput` / `RawNumberListInput` | متن یا لیست متن؛ ارقام فارسی/لاتین/عربی در مسیر normalizer تبدیل می‌شوند |
| `CalculatorInput` | map immutable از `NumberInputValue`، `ChoiceInputValue` و `NumberListInputValue` |
| `CalculatorParameters` | marker interface برای پارامتر اختصاصی و immutable هر موتور |
| `CalculatorEngine<I>` | `calculatorId`، `bind(CalculatorInput)` و `calculate(I)`؛ شناسه باید با Definition برابر باشد |
| `CalculationIssue` | code پایدار، پیام فارسی، fieldId و itemIndex اختیاری برای اتصال خطا به فرم |
| `CalculationResult` | primary، details، warnings و interpretation؛ object مستقل از قالب‌بندی Widget |
| `ResultValue` | عددی با واحد/نمایش، متن یا لیست عددی؛ عدد غیرمتناهی پذیرفته نمی‌شود |
| `CalculationOutcome` | union صریح success/failure؛ نتیجهٔ ساختگی برای ورودی نامعتبر ساخته نمی‌شود |

درصد canonical کسری است: فیلد percentage با متن `20` به `0.2` تبدیل می‌شود؛ موتور دوباره بر ۱۰۰ تقسیم نکند، مگر قرارداد همان فیلد صریحاً چیز دیگری باشد. نمونهٔ واقعی `UtilityCalculators.percentageOfRunner` و `PercentageOfEngine` را پیش از توسعه بررسی کنید. تاریخ‌های جریان نقدی/واحد زمان، زمان t=0، نرخ و assumptions باید در ورودی/نتیجه قابل مشاهده باشند. NPV/IRR توصیهٔ سرمایه‌گذاری شخصی نیستند؛ IRR بدون ریشهٔ معتبر نباید عدد ساختگی بازگرداند.

## ۳. کاتالوگ، route و فرم generic

- `AppCatalog.catalog`، `ToolCatalog` immutable با دسته‌ها و تعریف ابزارهای واقعی است؛ duplicate id/category و ابزار نامعتبر رد می‌شود.
- هر فایل دسته، مانند `lib/app/catalog/utility_calculators.dart`، `runners`، `definitions` مشتق از runners و `byId` دارد.
- `AppRouter` در `lib/app/routing/app_router.dart` با شناسهٔ calculator از map دستهٔ مناسب runner را پیدا می‌کند. OEE/NPV/Cp همچنین routeهای قدیمی سازگار دارند؛ برای توسعه آن‌ها را حذف نکنید.
- `CalculatorRequest` شناسه و ورودی snapshot اختیاری برای بازگشایی history را حمل می‌کند.
- `CalculatorPage` از تعریف فیلدها UI می‌سازد؛ نتیجهٔ معتبر reactive است. ذخیرهٔ history **دستی** است، نه به‌ازای هر key stroke.
- glossary از relatedTerms کاتالوگ ساخته می‌شود و از idهای category-scoped استفاده می‌کند؛ لینک‌ها باید به ابزار واقعی resolve شوند.
- جدول README توسط `tool/update_calculator_table.dart` از همین کاتالوگ تولید و با `--check` کنترل می‌شود. ۶۸ مورد تخصصی و ۵ عمومی جمعاً ۷۳ موردند؛ demo جدا شمرده نمی‌شود.

## ۴. persistence و نسخه‌بندی

### فایل و executor

`openApplicationDatabase()` در `lib/core/storage/open_local_database.dart` با `getApplicationSupportDirectory()` مسیر قابل‌نوشتن حساب کاربر را می‌گیرد، پوشه را می‌سازد و فایل **`management_toolbox.sqlite`** را با `NativeDatabase.createInBackground` باز می‌کند. مسیر temp یا کنار EXE برای production نیست. sqlite3 از native build hook بسته استفاده می‌کند؛ DLL/so در artifact باید حفظ شود.

`ToolboxDatabase` در `lib/core/storage/toolbox_database.dart` از Drift با SQL صریح استفاده می‌کند؛ برای این schema، `build_runner` یا generated ORM لازم نیست. PRAGMAها شامل foreign_keys، WAL، busy_timeout=5000 و synchronous=FULL هستند. SQLite WAL معادل رمزگذاری داده نیست؛ هیچ رمزگذاری at-rest سفارشی در این پروژه ادعا نمی‌شود.

### schemaVersion = 2

| جدول | ستون‌ها | قید/معنا |
|---|---|---|
| `favorites` | `calculator_id TEXT PRIMARY KEY`، `created_at_micros INTEGER` | id غیرخالی و زمان؛ Set منطقی بدون duplicate |
| `calculation_history` | `id INTEGER PRIMARY KEY AUTOINCREMENT`، `calculator_id`، `inputs_json`، `result_json`، `created_at_micros`، `payload_version` | sequence insertion معیار جدیدترین؛ payload_version مثبت و پیش‌فرض ۱ |

trigger `history_keep_ten` بعد از INSERT، فقط ۱۰ id آخر را **در کل برنامه** نگه می‌دارد، نه ۱۰ رکورد به‌ازای هر ابزار. `DriftToolRepository` mutation و read snapshot نهایی را در یک transaction انجام می‌دهد؛ UI قبل از commit، داده را durable اعلام نمی‌کند. queue در `ToolSessionController` عملیات را مرتب می‌کند؛ خطای load/write به پیام فارسی قابل بازیابی تبدیل می‌شود.

`RecentCalculation` شامل sequence، calculatorId، **RawCalculatorInput**، **CalculationResult** و createdAt است. `CalculationSnapshotCodec.version = 1` از schema SQLite جداست؛ ذخیرهٔ snapshot نتیجهٔ زمان ثبت را نگه می‌دارد، نه صرفاً محاسبهٔ دوباره با موتور آینده. دادهٔ ناشناخته/ناسازگار نباید با مثال پیش‌فرض جایگزین و بی‌صدا بازنویسی شود. id ابزار بازنشسته روی دیسک حفظ ولی از UI نامعتبر فیلتر می‌شود.

migration فعلی فقط ۱→۲ است: افزودن `payload_version`، اعمال retention و ساخت trigger در transaction. نسخهٔ جدیدتر یا مسیر migration پشتیبانی‌نشده خطا می‌دهد و داده حذف نمی‌شود. توسعهٔ schema مستلزم افزایش schemaVersion، migration صریح و تست فایل قدیمی/خطا است؛ حذف دیتابیس برای عبور از migration پذیرفته نیست.

**چه چیزی ذخیره نمی‌شود؟** انتخاب ThemeMode و reduceMotion در `ThemeSettings` فعلی در حافظهٔ نشست هستند. این دو را با favorites/history ماندگار اشتباه نگیرید. هیچ حساب کاربری، sync ابری یا backend اضافه نشده است.

## ۵. افزودن ماشین‌حساب جدید — چک‌لیست عملی

۱. **قرارداد ریاضی:** فرمول، units، assumptions، محدودهٔ معتبر، رفتار مرزها و expected result مستقل را بنویسید. شناسهٔ جدید ASCII و پایدار انتخاب کنید؛ id ابزار منتشرشده را بی‌مهاجرت عوض نکنید.

۲. **پارامتر و موتور مستقل:** کنار موتورهای همان feature، `final class NewParameters implements CalculatorParameters` با فیلدهای final و سپس `CalculatorEngine<NewParameters>` بسازید. `bind` مقادیر canonical را می‌گیرد، خطاهای بین‌فیلدی را با `RejectedInput` و پیام فارسی برمی‌گرداند؛ `calculate` از پارامتر تایپ‌شده استفاده می‌کند. از موتور کوچک موجود `lib/features/utilities/domain/percentage_of.dart` به‌عنوان الگوی واقعی استفاده کنید، نه کپی UI.

۳. **Definition:** در فایل catalog دسته، `CalculatorDefinition` با nameFa/nameEn/aliases، field id/unit/default/min/max/help، formulaLatex، assumptions، relatedTerms و یک یا چند `CalculatorExample` با expectedResult بسازید. اطلاعات آموزشی/هشدارهای دامنه را حذف نکنید.

۴. **Runner و ثبت:** runner را با تعریف و موتور یکسان و normalizer مناسب بسازید؛ در `runners` همان دسته قرار دهید تا `definitions` و `byId` به‌روزرسانی شوند. برای دستهٔ موجود، مسیر فعلی AppCatalog/AppRouter آن map را می‌بیند. برای **دستهٔ کاملاً جدید** enum، فهرست categories، spreadهای AppCatalog، lookup route و policyهای رنگ/فیلتر را نیز به‌روز کنید.

۵. **UI:** ابتدا فرم/نتیجهٔ generic را reuse کنید. نوع ورودی تازه فقط وقتی ضروری است اضافه شود و validation مشترک/codec را دور نزند. ساخت chart یا structured result جدید نیازمند تست layout/RTL/متن بزرگ است.

۶. **تست موتور:** مثال مرجع و tolerance عددی، صفر/منفی/مخرج صفر، حدود مجاز، invalid cross-field، extreme/overflow، نامتناهی، locale digits و عدم تغییر ورودی را پوشش دهید. failure خروجی ساختگی ندهد.

۷. **تست اتصال:** حضور یکتای id، resolve شدن route، ساخت فرم، نتیجهٔ reactive، عدم نمایش نتیجهٔ قدیمی بعد از input نامعتبر، save دستی، favorite و restore snapshot را بررسی کنید. schema/payload جدید به تست round-trip/migration نیاز دارد.

۸. **مستندسازی و پذیرش:** `dart run tool/update_calculator_table.dart`، حالت `--check`، analyze، format و کل suite را اجرا کنید. شمارندهٔ smoke که عمداً snapshot ۷۳ را قفل کرده و مستندات عددی را فقط پس از افزودن واقعی ابزار به‌روز کنید؛ عدد را صرفاً برای سبزکردن تست عوض نکنید.

```sh
flutter analyze
flutter test --concurrency=1
dart format --output=none --set-exit-if-changed lib test tool
dart run tool/update_calculator_table.dart --check
```

## ۶. برندینگ و startup

لوگوی مرجع موجود حفظ شده است. `tool/generate_branding.py`، با نسخهٔ pin‌شدهٔ Pillow در فایل requirements توسعه، آیکون‌ها را بدون شبکه از آن تولید می‌کند. asset اصلی برای welcome/startup و مجوز فونت در Flutter bundle باقی می‌مانند.

- Android API26–30: `launch_background.xml` با bitmap محلی و رنگ روز/شب؛ PNGهای launcher برای fallback.
- API26+: adaptive icon با background و foreground امن برای mask؛ آیکون اصلی manifest همان `@mipmap/ic_launcher` است.
- API31+: overrideهای روز/شب `windowSplashScreenBackground` و `windowSplashScreenAnimatedIcon` با safe padding.
- Windows: `windows/runner/resources/app_icon.ico` چنداندازه در `Runner.rc`؛ product metadata نهایی. native runner مانند قبل پس از first frame پنجره را نشان می‌دهد.
- `AppStartupSplash` در Flutter تا آماده‌شدن repository نمایش داده می‌شود؛ Windows **پیش از engine** splash مستقل ندارد. شکست storage همان خطا و retry را نشان می‌دهد؛ splash برای پوشاندن خطا دائمی نمی‌شود. تأخیر زمانی/شبکه برای animation اضافه نشده است.

## ۷. کیفیت، ایمنی و تحویل

تست‌ها بخشی از محصول توسعه‌اند و حذف نشده‌اند. نبود `print/debugPrint` در `lib/` کنترل می‌شود؛ گزارش خطای واقعی `FlutterError` و خروجی عمدی CLIهای QA حفظ شده‌اند. کامنت‌های template مردهٔ splash و TODO عمومی جایگزین شده‌اند؛ توضیح invariants، migration، درصد و قراردادهای امنیتی «کامنت غیرضروری» محسوب نمی‌شوند.

build و امضای production در README و `docs/stage19_release.md` است. secretها فقط خارج checkout؛ release بدون secrets عمداً unsigned است. Windows باید کل Release با DLL/data/native-assets بسته‌بندی شود. PNG/ICO header و widget test صحت source را بررسی می‌کنند، نه launcher واقعی/Windows compilation.

برای audit نتیجهٔ همین مرحله، `docs/validation/stage20/README.md` را ببینید. نتایج مرحلهٔ ۱۹ و APK/AAB آن تاریخی و جدا هستند؛ نه build جدید branding مرحلهٔ ۲۰. CI/Push/امضای ناشر/تست دستگاه بدون شاهد موفقیت اعلام نمی‌شوند.
