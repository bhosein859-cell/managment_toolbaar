import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/theme/theme_settings.dart';
import 'package:management_toolbox/core/widgets/ltr_text.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

Future<void> enterHome(WidgetTester tester) async {
  await tester.pumpWidget(
    ManagementToolboxApp(repository: DriftToolRepository.memory()),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('ورود به برنامه'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('ورود به برنامه'));
  await tester.pumpAndSettle();
}

void main() {
  test('bundled regular, bold and OFL assets are available offline', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = await rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    expect(font.lengthInBytes, greaterThan(100000));
    expect(bold.lengthInBytes, greaterThan(100000));
    expect(
      await rootBundle.loadString('assets/fonts/OFL.txt'),
      contains('SIL OPEN FONT LICENSE Version 1.1'),
    );
  });

  testWidgets('themes follow system brightness and use local font', (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await enterHome(tester);
    final element = tester.element(find.text('جعبه‌ابزار مدیریت'));
    expect(Theme.of(element).brightness, Brightness.dark);
    expect(Theme.of(element).textTheme.bodyMedium!.fontFamily, 'Vazirmatn');
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(Theme.of(element).brightness, Brightness.light);
  });

  testWidgets(
    'settings switch theme without resetting route; all three modes work',
    (tester) async {
      await enterHome(tester);
      await tester.tap(find.byTooltip('تنظیمات'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تاریک').last);
      await tester.pumpAndSettle();
      final element = tester.element(find.text('ظاهر برنامه'));
      expect(Theme.of(element).brightness, Brightness.dark);
      expect(ThemeScope.of(element).mode, ThemeMode.dark);
      ThemeScope.of(element).setMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(Theme.of(element).brightness, Brightness.light);
      ThemeScope.of(element).setMode(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(ThemeScope.of(element).mode, ThemeMode.system);
      expect(find.text('ظاهر برنامه'), findsOneWidget);
    },
  );

  testWidgets('lab accepts Persian Arabic and Latin, rejects invalid values', (
    tester,
  ) async {
    await enterHome(tester);
    await tester.tap(find.byTooltip('آزمایش فارسی'));
    await tester.pumpAndSettle();
    final input = find.byKey(const Key('numeric-input'));
    await tester.ensureVisible(input);
    for (final text in ['۱۲۳٫۴۵', '١٢٣٫٤٥', '123.45']) {
      await tester.enterText(input, text);
      await tester.pump();
      expect(
        find.textContaining('نمایش فارسی: \u2066۱۲۳٫۴۵\u2069'),
        findsOneWidget,
      );
    }
    final labContext = tester.element(find.byKey(const Key('numeric-input')));
    ThemeScope.of(labContext).setMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(input).controller!.text, '123.45');
    expect(find.textContaining('نمایش فارسی:'), findsOneWidget);
    await tester.enterText(input, 'NaN');
    await tester.pump();
    expect(find.text('یک عدد معتبر وارد کنید.'), findsOneWidget);
    expect(find.textContaining('نمایش فارسی:'), findsNothing);
    await tester.enterText(input, '');
    await tester.pump();
    expect(find.text('یک عدد معتبر وارد کنید.'), findsNothing);
    expect(
      Directionality.of(tester.element(find.byType(ListView))),
      TextDirection.rtl,
    );
    final latin = tester.element(find.text('OEE = A × P × Q'));
    expect(Directionality.of(latin), TextDirection.ltr);
    expect(find.byType(LtrText), findsWidgets);
    expect(Icons.arrow_forward.matchTextDirection, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(1280, 720)]) {
    testWidgets('RTL lab fits $size with enlarged text', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await enterHome(tester);
      await tester.tap(find.byTooltip('آزمایش فارسی'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
