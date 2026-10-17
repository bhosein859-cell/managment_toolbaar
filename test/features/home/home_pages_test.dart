import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/routing/app_router.dart';
import 'package:management_toolbox/app/routing/calculator_request.dart';
import 'package:management_toolbox/app/state/tool_session_scope.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

Future<void> start(WidgetTester tester) async {
  await tester.pumpWidget(
    ManagementToolboxApp(repository: DriftToolRepository.memory()),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('ورود به برنامه'));
  await tester.tap(find.text('ورود به برنامه'));
  await tester.pumpAndSettle();
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> search(WidgetTester tester, String text) async {
  final field = find.byKey(const Key('home-search'));
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

String result(WidgetTester tester) => tester
    .widget<SelectableText>(find.byKey(const Key('primary-result')))
    .data!;

void main() {
  testWidgets(
    'home shows all nine honest category counts and session sections',
    (tester) async {
      await start(tester);
      for (final id in CalculatorCategoryId.values) {
        expect(find.byKey(Key('category-${id.name}')), findsOneWidget);
        final expected = switch (id) {
          CalculatorCategoryId.production => '۱۰ ابزار',
          CalculatorCategoryId.finance ||
          CalculatorCategoryId.engineeringEconomics => '۱۰ ابزار',
          CalculatorCategoryId.quality ||
          CalculatorCategoryId.inventory ||
          CalculatorCategoryId.project ||
          CalculatorCategoryId.decisionMaking => '۸ ابزار',
          CalculatorCategoryId.humanResources => '۶ ابزار',
          CalculatorCategoryId.utilities => '۵ ابزار',
        };
        expect(
          tester
              .widget<Text>(find.byKey(Key('category-count-${id.name}')))
              .data,
          expected,
        );
      }
      expect(find.byKey(const Key('empty-favorites')), findsOneWidget);
      expect(find.byKey(const Key('empty-recent')), findsOneWidget);
      expect(find.byKey(const Key('local-storage-notice')), findsOneWidget);
      expect(find.byKey(const Key('available-tool-oee')), findsOneWidget);
    },
  );

  testWidgets('overview and each category show implemented tools', (
    tester,
  ) async {
    await start(tester);
    await tester.ensureVisible(find.text('همهٔ دسته‌ها'));
    await tester.tap(find.text('همهٔ دسته‌ها'));
    await tester.pumpAndSettle();
    await tapKey(tester, 'category-engineeringEconomics');
    expect(find.text('۱۰ ابزار قابل استفاده'), findsOneWidget);
    expect(
      find.byKey(const Key('category-tool-time_value_money')),
      findsOneWidget,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tapKey(tester, 'category-production');
    expect(find.text('۱۰ ابزار قابل استفاده'), findsOneWidget);
    await tapKey(tester, 'category-tool-oee');
    expect(result(tester), '۸۳٫۷۹٪');
  });

  testWidgets(
    'live fuzzy search is marked, opens real engine and retains query on return',
    (tester) async {
      await start(tester);
      await search(tester, 'nvp');
      expect(find.text('تطبیق تقریبی'), findsOneWidget);
      expect(find.byKey(const Key('search-tool-npv')), findsOneWidget);
      await tapKey(tester, 'search-tool-npv');
      expect(result(tester), '۴۱٫۳۲۲۳۱۴ ریال');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('home-search')))
            .controller!
            .text,
        'nvp',
      );
      await tester.tap(find.byTooltip('پاک کردن جستجو'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('category-inventory')), findsOneWidget);
    },
  );

  testWidgets(
    'Arabic/halfspace aliases search without rewriting text; no match is safe',
    (tester) async {
      await start(tester);
      const query = 'بهره‌وري تجهيزات';
      await search(tester, query);
      expect(find.byKey(const Key('search-tool-oee')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('home-search')))
            .controller!
            .text,
        query,
      );
      await search(tester, 'zzzzzzzzzz');
      expect(find.byKey(const Key('empty-search')), findsOneWidget);
      expect(find.byKey(const Key('search-tool-oee')), findsNothing);
    },
  );

  testWidgets(
    'favorite updates across pages; valid saved snapshot reopens exact prior inputs',
    (tester) async {
      await start(tester);
      await tapKey(tester, 'available-tool-oee');
      final input = find.byKey(const Key('input-availability'));
      await tester.ensureVisible(input);
      await tester.enterText(input, '50');
      await tester.pumpAndSettle();
      expect(result(tester), '۴۶٫۵۵٪');
      await tester.tap(find.byKey(const Key('calculator-favorite')));
      await tester.pumpAndSettle();
      expect(result(tester), '۴۶٫۵۵٪');
      expect(tester.widget<TextField>(input).controller!.text, '50');
      final session = ToolSessionScope.of(tester.element(input));
      expect(
        session.recent,
        isEmpty,
      ); // Live computation does not create keystroke history.
      await tester.tap(find.byKey(const Key('calculator-save')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(session.recent, hasLength(1));
      await tester.ensureVisible(input);
      await tester.enterText(input, 'bad');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('calculator-save')))
            .onPressed,
        isNull,
      );
      expect(session.recent, hasLength(1));
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('favorite-tool-oee')), findsOneWidget);
      expect(find.byKey(const Key('recent-1-tool-oee')), findsOneWidget);
      await tapKey(tester, 'recent-1-tool-oee');
      expect(result(tester), '۴۶٫۵۵٪');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-availability')))
            .controller!
            .text,
        '50',
      );
      await tester.tap(find.byKey(const Key('calculator-favorite')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('empty-favorites')), findsOneWidget);
    },
  );

  testWidgets(
    'home star does not navigate; explicitly isolated test databases stay isolated',
    (tester) async {
      await start(tester);
      await tapKey(tester, 'available-favorite-npv');
      expect(find.byKey(const Key('favorite-tool-npv')), findsOneWidget);
      expect(find.byKey(const Key('primary-result')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await start(tester);
      expect(find.byKey(const Key('empty-favorites')), findsOneWidget);
      expect(find.byKey(const Key('empty-recent')), findsOneWidget);
    },
  );

  testWidgets('invalid typed route arguments safely show not found', (
    tester,
  ) async {
    await start(tester);
    var context = tester.element(find.byKey(const Key('home-search')));
    Navigator.of(context)
        .pushNamed(AppRoutes.category, arguments: 'not an enum');
    await tester.pumpAndSettle();
    expect(find.text('صفحه پیدا نشد'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    context = tester.element(find.byKey(const Key('home-search')));
    Navigator.of(context).pushNamed(
      AppRoutes.calculator,
      arguments: const CalculatorRequest('not_implemented'),
    );
    await tester.pumpAndSettle();
    expect(find.text('صفحه پیدا نشد'), findsOneWidget);
  });

  for (final size in [const Size(320, 568), const Size(1280, 800)]) {
    for (final dark in [false, true]) {
      testWidgets(
        'home and actual calculator fit $size dark=$dark with text scale 1.5',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 1.5;
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await start(tester);
          await tester.ensureVisible(
            find.byKey(const Key('category-engineeringEconomics')),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await search(tester, 'npv');
          await tapKey(tester, 'search-tool-npv');
          expect(result(tester), '۴۱٫۳۲۲۳۱۴ ریال');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
