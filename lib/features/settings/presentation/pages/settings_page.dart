import 'package:flutter/material.dart';

import '../../../../app/theme/theme_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final settings = ThemeScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              key: const Key('settings-list'),
              padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'ظاهر برنامه',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'حالت روشن یا تاریک',
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      key: const Key('theme-mode'),
                      value: settings.mode,
                      isExpanded: true,
                      onChanged: (value) {
                        if (value != null) settings.setMode(value);
                      },
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('پیروی از سیستم'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('روشن'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('تاریک'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  key: const Key('reduce-motion'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('کاهش حرکت'),
                  subtitle: const Text(
                    'انیمیشن جابه‌جایی صفحه و تغییر رنگ را خاموش می‌کند. درخواست کاهش حرکت سیستم همیشه رعایت می‌شود.',
                  ),
                  value: settings.reduceMotion,
                  onChanged: settings.setReduceMotion,
                ),
                const SizedBox(height: 16),
                const Text(
                  'انتخاب ظاهر و کاهش حرکت در این اجرای برنامه حفظ می‌شود. ذخیرهٔ دائمی تنظیمات هنوز اضافه نشده است.',
                ),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    'دسترس‌پذیری و صفحه‌کلید',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'اندازهٔ متن از تنظیمات سیستم پیروی می‌کند و محدود نشده است. نام و آیکون هر دسته در کنار رنگ آن نمایش داده می‌شوند.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tab و Shift+Tab: حرکت بین کنترل‌ها\nEnter یا Space روی دکمه: فعال‌سازی\nCtrl+F: فوکوس جست‌وجو در خانه و واژه‌نامه\nAlt+I: اولین ورودی محاسبه‌گر\nCtrl+Enter: ثبت محاسبهٔ معتبر در تاریخچه\nCtrl+H: بازکردن تاریخچه\nAlt+←: بازگشت به صفحهٔ قبل\nEscape: بستن منو یا پنجرهٔ محاوره‌ای',
                ),
                const SizedBox(height: 12),
                const Text(
                  'کپی، چسباندن و انتخاب متن استاندارد با صفحه‌کلید حفظ شده‌اند. محاسبات و واژه‌نامه بدون شبکه کار می‌کنند.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
