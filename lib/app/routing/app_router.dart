import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/calculators/domain/calculator_domain.dart';
import '../../features/calculators/presentation/pages/calculator_page.dart';
import '../../features/glossary/domain/glossary_catalog.dart';
import '../../features/glossary/presentation/glossary_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/home/presentation/pages/category_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/utilities/presentation/pages/typography_lab_page.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';
import '../catalog/app_catalog.dart';
import '../catalog/decision_calculators.dart';
import '../catalog/engineering_economics_calculators.dart';
import '../catalog/finance_calculators.dart';
import '../catalog/form_demo.dart';
import '../catalog/hr_calculators.dart';
import '../catalog/inventory_calculators.dart';
import '../catalog/production_calculators.dart';
import '../catalog/project_calculators.dart';
import '../catalog/prototype_calculators.dart';
import '../catalog/quality_calculators.dart';
import '../catalog/utility_calculators.dart';
import '../state/tool_session_scope.dart';
import 'calculator_request.dart';

abstract final class AppRoutes {
  static const welcome = '/';
  static const home = '/home';
  static const settings = '/settings';
  static const glossary = '/glossary';
  static const history = '/history';
  static const typography = '/typography';
  static const calculatorDemo = '/calculator-demo';
  static const categories = '/categories';
  static const category = '/category';
  static const calculator = '/calculator';
  static const oee = '/calculators/oee';
  static const npv = '/calculators/npv';
  static const cp = '/calculators/cp';
}

abstract final class AppRouter {
  static Route<void> onGenerateRoute(RouteSettings settings) =>
      _ToolboxPageRoute(
        settings: settings,
        builder: (context) => _build(context, settings),
      );

  static Widget _build(BuildContext context, RouteSettings settings) {
    final session = ToolSessionScope.of(context);
    final catalog = AppCatalog.catalog;
    void openTool(String id, [RawCalculatorInput? inputs]) => unawaited(
      Navigator.of(context).pushNamed(
        AppRoutes.calculator,
        arguments: CalculatorRequest(id, inputs: inputs),
      ),
    );
    void openCategory(CalculatorCategoryId id) => unawaited(
      Navigator.of(context).pushNamed(AppRoutes.category, arguments: id),
    );
    switch (settings.name) {
      case AppRoutes.welcome:
        return WelcomePage(
          onEnter: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.home),
        );
      case AppRoutes.home:
        return HomePage(
          catalog: catalog,
          session: session,
          onOpenCalculator: openTool,
          onOpenCategory: openCategory,
          onAllCategories: () =>
              Navigator.of(context).pushNamed(AppRoutes.categories),
        );
      case AppRoutes.categories:
        return CategoriesPage(catalog: catalog, onOpen: openCategory);
      case AppRoutes.category:
        final id = settings.arguments;
        if (id is! CalculatorCategoryId) return const _NotFoundPage();
        final category = catalog.categoryById(id);
        if (category == null) return const _NotFoundPage();
        return CategoryPage(
          catalog: catalog,
          category: category,
          session: session,
          onOpen: (id) => openTool(id),
        );
      case AppRoutes.calculator:
        final request = settings.arguments;
        if (request is! CalculatorRequest) return const _NotFoundPage();
        final utilityRunner = UtilityCalculators.byId[request.calculatorId];
        if (utilityRunner != null) {
          return _calculator(context, utilityRunner, request.inputs);
        }
        final productionRunner =
            ProductionCalculators.byId[request.calculatorId];
        if (productionRunner != null) {
          return _calculator(context, productionRunner, request.inputs);
        }
        final financeRunner = FinanceCalculators.byId[request.calculatorId];
        if (financeRunner != null) {
          return _calculator(context, financeRunner, request.inputs);
        }
        final qualityRunner = QualityCalculators.byId[request.calculatorId];
        if (qualityRunner != null) {
          return _calculator(context, qualityRunner, request.inputs);
        }
        final inventoryRunner = InventoryCalculators.byId[request.calculatorId];
        if (inventoryRunner != null) {
          return _calculator(context, inventoryRunner, request.inputs);
        }
        final projectRunner = ProjectCalculators.byId[request.calculatorId];
        if (projectRunner != null) {
          return _calculator(context, projectRunner, request.inputs);
        }
        final hrRunner = HrCalculators.byId[request.calculatorId];
        if (hrRunner != null) {
          return _calculator(context, hrRunner, request.inputs);
        }
        final economicsRunner =
            EngineeringEconomicsCalculators.byId[request.calculatorId];
        if (economicsRunner != null) {
          return _calculator(context, economicsRunner, request.inputs);
        }
        final decisionRunner = DecisionCalculators.byId[request.calculatorId];
        if (decisionRunner != null) {
          return _calculator(context, decisionRunner, request.inputs);
        }
        return const _NotFoundPage();
      case AppRoutes.oee:
        return _calculator(context, PrototypeCalculators.oeeRunner, null);
      case AppRoutes.npv:
        return _calculator(context, PrototypeCalculators.npvRunner, null);
      case AppRoutes.cp:
        return _calculator(context, PrototypeCalculators.cpRunner, null);
      case AppRoutes.calculatorDemo:
        return CalculatorPage(runner: FormDemo.runner);
      case AppRoutes.history:
        return HistoryPage(
          catalog: catalog,
          session: session,
          onOpen: (id, inputs) => openTool(id, inputs),
        );
      case AppRoutes.glossary:
        return GlossaryPage(
          catalog: GlossaryCatalog.fromTools(catalog),
          onOpenCalculator: openTool,
        );
      case AppRoutes.settings:
        return const SettingsPage();
      case AppRoutes.typography:
        return const TypographyLabPage();
      default:
        return const _NotFoundPage();
    }
  }

  static Widget _calculator<I extends CalculatorParameters>(
    BuildContext context,
    CalculatorRunner<I> runner,
    RawCalculatorInput? input,
  ) {
    final session = ToolSessionScope.of(context);
    return CalculatorPage(
      runner: runner,
      initialInput: input,
      isFavorite: session.isFavorite(runner.definition.id),
      storageBusy: session.isBusy,
      storageError: session.lastError,
      onToggleFavorite: () => session.toggleFavorite(runner.definition.id),
      onSaveCalculation: (inputs, result) async {
        final saved = await session.record(
          runner.definition.id,
          inputs,
          result,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'محاسبه در تاریخچهٔ محلی ذخیره شد.'
                  : session.lastError ?? 'ذخیره‌سازی انجام نشد.',
            ),
          ),
        );
      },
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('صفحه پیدا نشد')),
    body: Center(
      child: FilledButton(
        onPressed: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
        child: const Text('بازگشت به خانه'),
      ),
    ),
  );
}

class _ToolboxPageRoute extends MaterialPageRoute<void> {
  _ToolboxPageRoute({required super.settings, required super.builder});
  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 140);
}
