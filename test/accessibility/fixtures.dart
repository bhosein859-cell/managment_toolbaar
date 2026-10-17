import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/app/state/tool_session_scope.dart';
import 'package:management_toolbox/app/theme/app_theme.dart';
import 'package:management_toolbox/app/theme/theme_settings.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/calculators/presentation/pages/calculator_page.dart';
import 'package:management_toolbox/features/glossary/domain/glossary_catalog.dart';
import 'package:management_toolbox/features/glossary/presentation/glossary_page.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';
import 'package:management_toolbox/features/history/presentation/pages/history_page.dart';
import 'package:management_toolbox/features/home/presentation/controllers/tool_session_controller.dart';
import 'package:management_toolbox/features/home/presentation/pages/category_page.dart';
import 'package:management_toolbox/features/home/presentation/pages/home_page.dart';
import 'package:management_toolbox/features/settings/presentation/pages/settings_page.dart';

const screens = [
  'home',
  'category',
  'calculator',
  'history',
  'glossary',
  'settings',
];

class UiFixture {
  final settings = ThemeSettings();
  final session = ToolSessionController(
    catalog: AppCatalog.catalog,
    repository: DriftToolRepository.memory(),
    now: () => DateTime(2026, 10, 16, 12, 30),
  );
  Future<void> initialize() async {
    await session.initialize();
    for (var i = 0; i < 10; i++) {
      final raw = PrototypeCalculators.oee.examples.single.inputs;
      await session.record(
        'oee',
        raw,
        (PrototypeCalculators.oeeRunner.run(raw) as CalculationSuccess).result,
      );
    }
    await session.toggleFavorite('oee');
  }

  Future<void> close() async {
    await session.close();
    session.dispose();
    settings.dispose();
  }

  Widget page(String screen) => switch (screen) {
    'home' => HomePage(
      catalog: AppCatalog.catalog,
      session: session,
      onOpenCalculator: (_, [input]) {},
      onOpenCategory: (_) {},
      onAllCategories: () {},
    ),
    'category' => CategoryPage(
      catalog: AppCatalog.catalog,
      category: AppCatalog.catalog.categoryById(
        CalculatorCategoryId.production,
      )!,
      session: session,
      onOpen: (_) {},
    ),
    'calculator' => CalculatorPage(
      runner: PrototypeCalculators.oeeRunner,
      onToggleFavorite: () {},
      onSaveCalculation: (_, _) {},
      isFavorite: true,
    ),
    'history' => HistoryPage(
      catalog: AppCatalog.catalog,
      session: session,
      onOpen: (_, _) {},
    ),
    'glossary' => GlossaryPage(
      catalog: GlossaryCatalog.fromTools(AppCatalog.catalog),
      onOpenCalculator: (_) {},
    ),
    'settings' => const SettingsPage(),
    _ => throw ArgumentError(screen),
  };
  Widget host(
    String screen, {
    bool dark = false,
    double scale = 1,
    TargetPlatform platform = TargetPlatform.android,
    Widget Function(Widget)? capture,
  }) => ThemeScope(
    settings: settings,
    child: ToolSessionScope(
      session: session,
      child: MaterialApp(
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light().copyWith(platform: platform),
        darkTheme: AppTheme.dark().copyWith(platform: platform),
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: capture == null ? child! : capture(child!),
        ),
        home: page(screen),
      ),
    ),
  );
}
