# تحویل Git و آماده‌سازی Push — مرحلهٔ ۲۰

## مرز دسترسی و تاریخچه

در این محیط اتصال مستقیم GitHub پشتیبانی نمی‌شود. هیچ repository آنلاین، Pull Request، release، Push یا run Actions ایجاد نشده است. URL و credential ساختگی تنظیم نشده‌اند.

metadata قدیمی `.git` در workspace ناقص است (ref/config کامل در snapshot موجود نیست). آن را حذف یا به‌زور به repository کاربر تبدیل نکردیم. برای تحویل، **repository محلی مستقل** با import دقیق ZIP مرحلهٔ ۱۹ و commitهای مرحلهٔ ۲۰ ساخته می‌شود. این baseline، بازسازی تاریخچهٔ واقعی GitHub نیست و commitهای آن نباید جای تاریخچهٔ موجود را با force-push بگیرند.

فایل‌های کنار ZIP سورس:

- `management_toolbox_stage_20_git.bundle`: تاریخچهٔ قابل clone آفلاین شامل baseline و commitهای واقعی محلی
- `management_toolbox_stage_20_changes.patch`: فقط تغییرهای مرحلهٔ ۲۰ در قالب `git format-patch --binary`؛ baseline دوباره اعمال نمی‌شود
- `management_toolbox_stage_20_git_log.txt`: شناسه و پیام commitهای واقعاً ساخته‌شده
- فایل‌های SHA256 خروجی‌ها

author commitهای اتوماتیک `Management Toolbox Release Bot <release@management-toolbox.invalid>` است؛ امضای Git یا هویت GitHub صاحب پروژه جعل نشده است. commitهای تحویلی cryptographically signed نیستند.

## روش توصیه‌شده برای همان repository موجود

ابتدا از کار محلی backup بگیرید، شاخهٔ جدید بسازید و مطمئن شوید وضعیت شما با مرحلهٔ ۱۹ متناظر است. bundle و patch را **خارج checkout** نگه دارید. متغیر `STAGE20_PATCH_PATH` را به مسیر واقعی patch دریافت‌شده تنظیم کنید؛ placeholder را عیناً اجرا نکنید.

```sh
git status --short
git switch -c release/stage20
git am --3way "$STAGE20_PATCH_PATH"
```

در صورت conflict، اختلاف واقعی با پروژهٔ خود را بررسی کنید؛ برای لغو عملیات `git am --abort`، نه حذف فایل‌ها یا force-push. پس از resolve و قبل از Push، analyze/test/buildهای لازم را اجرا کنید. اگر هنوز تغییرهای مرحلهٔ ۱۹ را ندارید، اول baseline محتوایی را روی شاخهٔ خود هماهنگ کنید؛ patch مرحلهٔ ۲۰ به کد دیگر بی‌بررسی اعمال نشود.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1
dart run tool/update_calculator_table.dart --check
python -m unittest discover -s tool/tests -v
git diff --check
git status --short
```

remote موجود را بررسی کنید؛ آن را بدون اجازه عوض نکنید. token/private key را داخل remote URL ننویسید. احراز هویت با Git Credential Manager/SSH agent یا روش سازمانیِ خارج مخزن انجام شود.

```sh
git remote -v
git push -u origin release/stage20
```

پس از Push، PR به شاخهٔ اصلی باز کنید و workflow دستی **Release validation** را از Actions اجرا کنید. workflow هیچ انتشار فروشگاهی یا دسترسی پیش‌فرض به secret امضا ندارد. نام شاخهٔ اصلی repository شما ممکن است main/master یا نام دیگری باشد؛ این راهنما آن را حدس نمی‌زند.

## اگر repository جدید و خالی می‌خواهید

در یک پوشهٔ جدید، bundle را clone کنید (repository موجود را overwrite نکنید). متغیرهای زیر باید به مسیر bundle و URL واقعی repository خالی خودتان تنظیم شوند:

```sh
git clone "$STAGE20_BUNDLE_PATH" management_toolbox_release
cd management_toolbox_release
git status --short
git log --oneline -4
# origin حاصل clone به bundle محلی اشاره دارد؛ فقط در این clone جدید:
git remote set-url origin "$GITHUB_REPOSITORY_URL"
git push -u origin stage20-release
```

bundle credential/config شخصی را شامل نمی‌شود، اما کد/اسناد عمومی و شواهد QA را دارد. پیش از عمومی‌کردن repository، صاحب پروژه باید **مجوز انتشار سورس** را تعیین کند؛ در این مرحله خودسرانه LICENSE متن‌باز انتخاب نشده است. فونت Vazirmatn مجوز OFL جداگانه دارد و فایل آن باید حفظ شود.

## چک‌لیست بازبینی پیش از Push/Release

- [ ] محتوا و نام repository، applicationId، versionCode و مجوز انتشار توسط مالک تأیید شده‌اند.
- [ ] فایل‌های `.env`، keystore/JKS/PFX/P12، `local.properties`، دیتابیس کاربر، SDK/cache و artifactهای حجیم داخل commit نیستند.
- [ ] هیچ token در URL/README/لاگ وجود ندارد؛ SHA256 صرفاً integrity است، نه امضای ناشر.
- [ ] patch روی شاخهٔ جدا اعمال و تست شده؛ تاریخچهٔ قبلی حفظ شده؛ force-push لازم نیست.
- [ ] Actions و budget runner مجازند؛ actionها به SHAهای immutable pin شده‌اند و هنوز نیازمند بازبینی امنیتی‌اند.
- [ ] Android unsigned با نسخهٔ signed/قابل نصب اشتباه نشده؛ arm64-only با universal یکی فرض نشده است.
- [ ] Windows روی runner Windows ساخته و **کل Release** بسته‌بندی/روی مقصد واقعی اجرا شده است؛ EXE تنها منتشر نشده است.
- [ ] امضا، نصب دستگاه، حالت پرواز و cold-start/launcher/DPI بومی قبل از انتشار عمومی آزمایش شده‌اند.

لاگ‌ها فقط شواهد اجرای واقعی‌اند. وضعیت build این مرحله در `docs/validation/stage20/README.md` ثبت می‌شود؛ نتیجهٔ موفق مرحلهٔ ۱۹ برای سورس با برندینگ تازه، موفقیت جدید محسوب نمی‌شود.
