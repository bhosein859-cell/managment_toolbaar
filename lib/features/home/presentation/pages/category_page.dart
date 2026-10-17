import 'package:flutter/material.dart';

import '../../../../app/theme/category_colors.dart';
import '../../../../core/utils/persian_numbers.dart';
import '../../../calculators/domain/calculator_domain.dart';
import '../../domain/tool_catalog.dart';
import '../controllers/tool_session_controller.dart';
import '../widgets/category_grid.dart';
import '../widgets/tool_tile.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({
    super.key,
    required this.catalog,
    required this.onOpen,
  });
  final ToolCatalog catalog;
  final ValueChanged<CalculatorCategoryId> onOpen;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('دسته‌بندی‌ها')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: CategoryGrid(catalog: catalog, onOpen: onOpen),
        ),
      ),
    ),
  );
}

class CategoryPage extends StatelessWidget {
  const CategoryPage({
    super.key,
    required this.catalog,
    required this.category,
    required this.session,
    required this.onOpen,
  });
  final ToolCatalog catalog;
  final CalculatorCategory category;
  final ToolSessionController session;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final tools = catalog.toolsIn(category.id);
      return Scaffold(
        appBar: AppBar(title: Text(category.nameFa)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    CategoryVisuals.icon(category.id),
                    size: 44,
                    color: CategoryColors.forTheme(
                      Theme.of(context),
                      category.id,
                    ).foreground,
                  ),
                  const SizedBox(height: 16),
                  Text(category.description),
                  const SizedBox(height: 8),
                  Text(
                    '${PersianNumbers.format(tools.length)} ابزار قابل استفاده',
                    key: const Key('category-tool-count'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (session.lastError != null)
                    Text(
                      session.lastError!,
                      key: const Key('category-storage-error'),
                    ),
                  if (tools.isEmpty)
                    const Text(
                      'هنوز ابزاری برای این دسته پیاده‌سازی نشده است.',
                      key: Key('empty-category'),
                    ),
                  for (final tool in tools)
                    ToolTile(
                      tool: tool,
                      prefix: 'category',
                      isFavorite: session.isFavorite(tool.id),
                      onOpen: () => onOpen(tool.id),
                      onFavorite: session.isBusy
                          ? null
                          : () => session.toggleFavorite(tool.id),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
