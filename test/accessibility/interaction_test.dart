import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/utility_calculators.dart';
import 'package:management_toolbox/app/routing/app_router.dart';
import 'package:management_toolbox/app/routing/calculator_request.dart';
import 'package:management_toolbox/app/theme/theme_settings.dart';
import 'package:management_toolbox/core/widgets/interaction_support.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/glossary/domain/glossary_catalog.dart';
import 'package:management_toolbox/features/glossary/presentation/glossary_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';
import 'package:management_toolbox/features/home/presentation/widgets/category_grid.dart';

import 'fixtures.dart';

Future<void> chord(
  WidgetTester t,
  LogicalKeyboardKey key, {
  LogicalKeyboardKey modifier = LogicalKeyboardKey.controlLeft,
}) async {
  await t.sendKeyDownEvent(modifier);
  await t.sendKeyEvent(key);
  await t.sendKeyUpEvent(modifier);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'Ctrl+F, Tab and Shift+Tab give search and predictable traversal',
    (tester) async {
      final fixture = UiFixture();
      await tester.runAsync(fixture.initialize);
      addTearDown(() => tester.runAsync(fixture.close));
      await tester.pumpWidget(fixture.host('home'));
      await tester.pumpAndSettle();
      await chord(tester, LogicalKeyboardKey.keyF);
      final search = tester.widget<TextField>(
        find.byKey(const Key('home-search')),
      );
      expect(search.focusNode!.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(search.focusNode!.hasFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(search.focusNode!.hasFocus, isTrue);
    },
  );
  testWidgets(
    'Alt+I focuses input; Tab advances; Ctrl+Enter saves only live valid result',
    (tester) async {
      var saved = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CalculatorPage(
            runner: UtilityCalculators.percentageOfRunner,
            onSaveCalculation: (_, _) {
              saved++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await chord(
        tester,
        LogicalKeyboardKey.keyI,
        modifier: LogicalKeyboardKey.altLeft,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-amount')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-rate')))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await chord(tester, LogicalKeyboardKey.enter);
      expect(saved, 1);
      await tester.enterText(find.byKey(const Key('input-rate')), 'NaN');
      await chord(tester, LogicalKeyboardKey.enter);
      expect(saved, 1);
    },
  );
  testWidgets(
    'category mouse hover and keyboard Enter use the same real action',
    (tester) async {
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: CategoryGrid(
                  catalog: AppCatalog.catalog,
                  onOpen: (id) => opened = id.name,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = find.byKey(const Key('category-production'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(target));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedContainer>(
              find
                  .descendant(
                    of: target,
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .decoration,
        isNotNull,
      );
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final ink = FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<InkWell>();
        if (ink?.key == const Key('category-production')) break;
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(opened, 'production');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'glossary query and category survive wide/narrow resize and keyboard insets',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: GlossaryPage(
              catalog: GlossaryCatalog.fromTools(AppCatalog.catalog),
              onOpenCalculator: (_) {},
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('glossary-search')), 'درصد');
      await tester.tap(find.byKey(const Key('glossary-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابزارهای عمومی').last);
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(320, 568);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('glossary-search')))
            .controller!
            .text,
        'درصد',
      );
      expect(find.text('ابزارهای عمومی'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('motion honors OS preference and explicit opt-out', (
    tester,
  ) async {
    final fixture = UiFixture();
    await tester.runAsync(fixture.initialize);
    addTearDown(() => tester.runAsync(fixture.close));
    await tester.pumpWidget(fixture.host('settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reduce-motion')));
    await tester.pumpAndSettle();
    expect(fixture.settings.reduceMotion, isTrue);
    BuildContext? context;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(interactionDuration(context!), Duration.zero);
    const builder = ToolboxTransitions();
    final route = MaterialPageRoute<void>(builder: (_) => const SizedBox());
    final child = const SizedBox(key: Key('motion-child'));
    expect(
      builder.buildTransitions(
        route,
        context!,
        const AlwaysStoppedAnimation(0.5),
        const AlwaysStoppedAnimation(0),
        child,
      ),
      same(child),
    );
    route.dispose();
  });
  testWidgets(
    'dedicated history navigation, keyboard back and raw-input reopen',
    (tester) async {
      await tester.pumpWidget(
        ManagementToolboxApp(repository: DriftToolRepository.memory()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ورود به برنامه'));
      await tester.pumpAndSettle();
      final homeContext = tester.element(find.byKey(const Key('home-search')));
      Navigator.of(homeContext).pushNamed(
        AppRoutes.calculator,
        arguments: const CalculatorRequest('percentage_of'),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('input-amount'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '۵۰۰');
      await chord(tester, LogicalKeyboardKey.enter);
      await chord(tester, LogicalKeyboardKey.keyH);
      expect(find.byKey(const Key('history-count')), findsOneWidget);
      final record = find.byKey(const Key('history-1-tool-percentage_of'));
      await tester.ensureVisible(record);
      await tester.tap(record);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('input-amount')))
            .controller!
            .text,
        '۵۰۰',
      );
      await chord(
        tester,
        LogicalKeyboardKey.arrowLeft,
        modifier: LogicalKeyboardKey.altLeft,
      );
      expect(find.byKey(const Key('history-count')), findsOneWidget);
      final historyContext = tester.element(
        find.byKey(const Key('history-count')),
      );
      ThemeScope.of(historyContext).setReduceMotion(true);
      await tester.pumpAndSettle();
      expect(
        MediaQuery.disableAnimationsOf(
          tester.element(find.byKey(const Key('history-count'))),
        ),
        isTrue,
      );
    },
  );
  testWidgets(
    'home touch targets and labels; category name/action and favorite state are explicit',
    (tester) async {
      final semantics = tester.ensureSemantics();

      final fixture = UiFixture();
      await tester.runAsync(fixture.initialize);
      addTearDown(() => tester.runAsync(fixture.close));
      await tester.pumpWidget(fixture.host('home'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('دستهٔ تولید، ۱۰ ابزار'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    },
  );
  testWidgets('mouse wheel scrolls history without touch drag', (tester) async {
    final fixture = UiFixture();
    await tester.runAsync(fixture.initialize);
    addTearDown(() => tester.runAsync(fixture.close));
    await tester.pumpWidget(fixture.host('history'));
    await tester.pumpAndSettle();
    final list = find.byKey(const Key('history-list'));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(list),
        scrollDelta: const Offset(0, 400),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));
  });
}
