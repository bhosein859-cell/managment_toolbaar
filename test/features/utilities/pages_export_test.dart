import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/utility_calculators.dart';
import 'package:management_toolbox/app/theme/app_theme.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/formatting/result_text_export.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/calculators/presentation/services/result_actions.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

class FakeActions implements ResultActions {
  String? copied, shared;
  bool fail = false;
  ResultShareStatus status = ResultShareStatus.shared;
  Completer<void>? pending;
  @override
  Future<void> copyText(String text) async {
    if (fail) throw StateError('failure');
    copied = text;
    await pending?.future;
  }

  @override
  Future<ResultShareStatus> shareText(String text, {Rect? origin}) async {
    if (fail) throw StateError('failure');
    shared = text;
    return status;
  }
}

Widget host(
  CalculatorRunner<CalculatorParameters> runner,
  FakeActions actions, {
  bool dark = false,
}) => MaterialApp(
  locale: const Locale('fa', 'IR'),
  supportedLocales: const [Locale('fa', 'IR')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  home: CalculatorPage(runner: runner, resultActions: actions),
);
Future<void> tap(WidgetTester tester, String id) async {
  final f = find.byKey(Key(id));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'real clipboard adapter sends the complete Unicode result to platform',
    () async {
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      try {
        await const PlatformResultActions().copyText('نتیجه ۲۰٪\nNPV = 12');
        expect(copied, 'نتیجه ۲۰٪\nNPV = 12');
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      }
    },
  );
  test('real share adapter preserves text and maps native statuses', () async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    String returned = 'target';
    Map<Object?, Object?>? params;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'share');
          params = call.arguments as Map;
          return returned;
        });
    try {
      const actions = PlatformResultActions();
      expect(await actions.shareText('نتیجه ۲۰٪'), ResultShareStatus.shared);
      expect(params!['text'], 'نتیجه ۲۰٪');
      returned = '';
      expect(await actions.shareText('لغو'), ResultShareStatus.dismissed);
      returned = 'dev.fluttercommunity.plus/share/unavailable';
      expect(await actions.shareText('نامشخص'), ResultShareStatus.unavailable);
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });
  for (final runner in UtilityCalculators.runners) {
    testWidgets(
      '${runner.definition.id}: reactive result, copy/share and disabled PDF',
      (tester) async {
        final actions = FakeActions();
        await tester.pumpWidget(host(runner, actions));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('primary-result')), findsOneWidget);
        expect(find.byKey(const Key('pdf-disabled-reason')), findsOneWidget);
        expect(
          tester
              .widget<OutlinedButton>(
                find.ancestor(
                  of: find.byKey(const Key('result-pdf-disabled')),
                  matching: find.byType(OutlinedButton),
                ),
              )
              .onPressed,
          isNull,
        );
        await tap(tester, 'result-copy');
        final input = runner.definition.examples.single.inputs;
        final expected = ResultTextExport.format(
          runner.definition,
          input,
          (runner.run(input) as CalculationSuccess).result,
        ); // default text can be Persian, so compare semantic content below.
        expect(actions.copied, contains(runner.definition.nameFa));
        expect(actions.copied, contains('ورودی‌ها:'));
        expect(actions.copied, contains('سازنده حسین بختیاری'));
        expect(expected, contains('نتیجه:'));
        await tap(tester, 'result-share');
        expect(actions.shared, actions.copied);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'latest live input and result are paired even before next frame; invalid input cannot copy',
    (tester) async {
      final actions = FakeActions();
      await tester.pumpWidget(
        host(UtilityCalculators.percentageOfRunner, actions),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('input-amount'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '۵۰۰'); // deliberately no pump
      final copy = tester.widget<OutlinedButton>(
        find.byKey(const Key('result-copy')),
      );
      copy.onPressed!();
      await tester.pumpAndSettle();
      expect(actions.copied, contains('۵۰۰'));
      expect(actions.copied, contains('۱۰۰'));
      final previous = actions.copied;
      await tester.ensureVisible(field);
      await tester.enterText(field, 'bad');
      copy.onPressed!();
      await tester.pumpAndSettle();
      expect(actions.copied, previous);
      expect(find.byKey(const Key('result-copy')), findsNothing);
    },
  );
  testWidgets('busy export blocks duplicates and clears after completion', (
    tester,
  ) async {
    final actions = FakeActions()..pending = Completer<void>();
    await tester.pumpWidget(
      host(UtilityCalculators.percentageOfRunner, actions),
    );
    await tester.pumpAndSettle();
    final copy = tester.widget<OutlinedButton>(
      find.byKey(const Key('result-copy')),
    );
    copy.onPressed!();
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('result-copy')))
          .onPressed,
      isNull,
    );
    actions.pending!.complete();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('result-copy')))
          .onPressed,
      isNotNull,
    );
  });
  for (final status in ResultShareStatus.values) {
    testWidgets('share status $status is reported honestly', (tester) async {
      final actions = FakeActions()..status = status;
      await tester.pumpWidget(host(UtilityCalculators.discountRunner, actions));
      await tester.pumpAndSettle();
      await tap(tester, 'result-share');
      final expected = switch (status) {
        ResultShareStatus.shared =>
          'نتیجه به رابط اشتراک سیستم تحویل شد؛ دریافت آن تأیید نمی‌شود.',
        ResultShareStatus.dismissed => 'اشتراک لغو شد.',
        ResultShareStatus.unavailable => 'سیستم وضعیت اشتراک را گزارش نکرد؛ ممکن است برنامهٔ مقصد باز شده باشد. در صورت نیاز از کپی استفاده کنید.',
      };
      expect(find.text(expected), findsOneWidget);
    });
  }
  testWidgets('clipboard/share exceptions are surfaced and do not crash', (
    tester,
  ) async {
    final actions = FakeActions()..fail = true;
    await tester.pumpWidget(host(UtilityCalculators.discountRunner, actions));
    await tester.pumpAndSettle();
    await tap(tester, 'result-copy');
    expect(find.textContaining('کپی انجام نشد'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tap(tester, 'result-share');
    expect(find.textContaining('اشتراک متنی انجام نشد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets('glossary/utilities RTL layout $size dark=$dark', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final actions = FakeActions();
        await tester.pumpWidget(
          host(UtilityCalculators.unitConversionRunner, actions, dark: dark),
        );
        await tester.pumpAndSettle();
        expect(
          Directionality.of(tester.element(find.byType(Scaffold))),
          TextDirection.rtl,
        );
        expect(find.textContaining('واحدهای پشتیبانی‌شده:'), findsWidgets);
        await tester.ensureVisible(find.byKey(const Key('input-from_unit')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets(
    'home -> offline glossary -> real percentage calculator -> favorite/history',
    (tester) async {
      await tester.pumpWidget(
        ManagementToolboxApp(repository: DriftToolRepository.memory()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ورود به برنامه'));
      await tester.pumpAndSettle();
      await tap(tester, 'open-glossary');
      await tester.enterText(
        find.byKey(const Key('glossary-search')),
        'Percentage of Amount',
      );
      await tester.pumpAndSettle();
      await tap(tester, 'term-link-utilities:percentage_of-percentage_of');
      expect(find.byKey(const Key('primary-result')), findsOneWidget);
      await tap(tester, 'calculator-favorite');
      await tap(tester, 'calculator-save');
      expect(find.text('محاسبه در تاریخچهٔ محلی ذخیره شد.'), findsOneWidget);
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('favorite-tool-percentage_of')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
