import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import '../presentation/fixtures.dart';

String result(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const Key('primary-result')))
    .data!;
Future<void> edit(WidgetTester tester, String id, String value) async {
  final input = find.byKey(Key('input-$id'));
  await tester.ensureVisible(input);
  await tester.enterText(input, value);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'OEE renders 83.79 percent and hides stale result on invalid ratio',
    (tester) async {
      await tester.pumpWidget(host(PrototypeCalculators.oeeRunner));
      await tester.pumpAndSettle();
      expect(result(tester), '۸۳٫۷۹٪');
      expect(find.textContaining('۰٫۸۳۷۹'), findsWidgets);
      expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
      await edit(tester, 'performance', '101');
      expect(find.byKey(const Key('primary-result')), findsNothing);
      await edit(tester, 'performance', '100');
      expect(result(tester), '۸۸٫۲٪');
    },
  );

  testWidgets('NPV cash flows begin at period 1; rate -100 is rejected in UI', (
    tester,
  ) async {
    await tester.pumpWidget(host(PrototypeCalculators.npvRunner));
    await tester.pumpAndSettle();
    expect(result(tester), '۴۱٫۳۲۲۳۱۴ ریال');
    expect(find.textContaining('XNPV'), findsWidgets);
    expect(find.textContaining('توصیهٔ سرمایه‌گذاری'), findsWidgets);
    expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
    await edit(tester, 'discount_rate', '−۱۰۰');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    expect(
      find.text('نرخ تنزیل هر دوره باید متناهی و بیشتر از منفی ۱۰۰٪ باشد.'),
      findsOneWidget,
    );
    await edit(tester, 'discount_rate', '۰');
    expect(result(tester), '۲۰۰ ریال');
    await edit(tester, 'initial_investment', '0');
    await edit(tester, 'cash_flows', '-100\n۲۰۰\n٣٠٠');
    expect(result(tester), '۴۰۰ ریال');
    await edit(tester, 'cash_flows', '');
    expect(find.byKey(const Key('primary-result')), findsNothing);
  });

  testWidgets('Cp sigma and limits are validated with assumptions visible', (
    tester,
  ) async {
    await tester.pumpWidget(host(PrototypeCalculators.cpRunner));
    await tester.pumpAndSettle();
    expect(result(tester), '۱٫۶۶۶۶۶۷');
    expect(find.textContaining('فرایند پایدار'), findsWidgets);
    expect(find.textContaining('جایگزین Cpk'), findsWidgets);
    expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
    await edit(tester, 'sigma', '۰');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    expect(
      find.text('سیگمای درون‌فرایندی باید عدد متناهی و بزرگ‌تر از صفر باشد.'),
      findsOneWidget,
    );
    await edit(tester, 'sigma', '۲');
    await edit(tester, 'usl', '۹۰');
    expect(find.byKey(const Key('primary-result')), findsNothing);
    expect(
      find.text('حد بالای مشخصات باید بزرگ‌تر از حد پایین مشخصات باشد.'),
      findsOneWidget,
    );
    final example = find.byKey(const Key('load-example-0'));
    await tester.ensureVisible(example);
    await tester.tap(example);
    await tester.pumpAndSettle();
    expect(result(tester), '۱');
  });

  testWidgets(
    'all three tools are reachable from home and retain existing tools',
    (tester) async {
      await tester.pumpWidget(
        ManagementToolboxApp(repository: DriftToolRepository.memory()),
      );
      await tester.pumpAndSettle();
      expect(find.text('سازنده حسین بختیاری'), findsOneWidget);
      await tester.tap(find.text('ورود به برنامه'));
      await tester.pumpAndSettle();
      for (final item in [
        ('OEE — اثربخشی کلی تجهیزات', '۸۳٫۷۹٪'),
        ('NPV — ارزش فعلی خالص', '۴۱٫۳۲۲۳۱۴ ریال'),
        ('Cp — قابلیت بالقوهٔ فرایند', '۱٫۶۶۶۶۶۷'),
      ]) {
        await tester.ensureVisible(find.text(item.$1));
        await tester.tap(find.text(item.$1));
        await tester.pumpAndSettle();
        expect(result(tester), item.$2);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(find.byTooltip('آزمایش فرم ماشین‌حساب'), findsOneWidget);
      expect(find.byTooltip('تنظیمات'), findsOneWidget);
    },
  );

  final pages = <String, Widget Function()>{
    'oee': () => host(PrototypeCalculators.oeeRunner, dark: true),
    'npv': () => host(PrototypeCalculators.npvRunner, dark: true),
    'cp': () => host(PrototypeCalculators.cpRunner, dark: true),
  };
  for (final entry in pages.entries) {
    for (final size in [const Size(320, 568), const Size(1280, 800)]) {
      testWidgets('${entry.key} fits RTL $size with enlarged text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(entry.value());
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('تفسیر'));
        await tester.pumpAndSettle();
        expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
