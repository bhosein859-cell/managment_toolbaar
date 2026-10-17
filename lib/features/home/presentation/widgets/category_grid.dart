import 'package:flutter/material.dart';

import '../../../../app/theme/category_colors.dart';
import '../../../../core/utils/persian_numbers.dart';
import '../../../../core/widgets/interaction_support.dart';
import '../../../calculators/domain/calculator_domain.dart';
import '../../domain/tool_catalog.dart';

abstract final class CategoryVisuals {
  static IconData icon(CalculatorCategoryId id) => switch (id) {
    CalculatorCategoryId.utilities => Icons.handyman_outlined,
    CalculatorCategoryId.production => Icons.precision_manufacturing_outlined,
    CalculatorCategoryId.finance => Icons.account_balance_outlined,
    CalculatorCategoryId.quality => Icons.verified_outlined,
    CalculatorCategoryId.inventory => Icons.inventory_2_outlined,
    CalculatorCategoryId.project => Icons.account_tree_outlined,
    CalculatorCategoryId.humanResources => Icons.groups_outlined,
    CalculatorCategoryId.decisionMaking => Icons.balance_outlined,
    CalculatorCategoryId.engineeringEconomics => Icons.trending_up,
  };
  static Color color(CalculatorCategoryId id) => CategoryColors.seed(id);
}

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.catalog, required this.onOpen});
  final ToolCatalog catalog;
  final ValueChanged<CalculatorCategoryId> onOpen;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minimum = MediaQuery.textScalerOf(context).scale(130);
      final columns = ((constraints.maxWidth + 12) / (minimum + 12))
          .floor()
          .clamp(1, 4);
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final category in catalog.categories)
            SizedBox(
              width: width,
              child: _CategoryCard(
                category: category,
                count: catalog.toolsIn(category.id).length,
                onOpen: () => onOpen(category.id),
              ),
            ),
        ],
      );
    },
  );
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.count,
    required this.onOpen,
  });
  final CalculatorCategory category;
  final int count;
  final VoidCallback onOpen;
  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _focused = false, _hovered = false;
  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final palette = CategoryColors.forTheme(Theme.of(context), category.id);
    return Semantics(
      label:
          'دستهٔ ${category.nameFa}، ${PersianNumbers.format(widget.count)} ابزار',
      button: true,
      focused: _focused,
      onTap: widget.onOpen,
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('category-${category.id.name}'),
          onTap: widget.onOpen,
          mouseCursor: SystemMouseCursors.click,
          onFocusChange: (v) => setState(() => _focused = v),
          onHover: (v) => setState(() => _hovered = v),
          child: AnimatedContainer(
            duration: interactionDuration(context),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _hovered ? palette.background : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                width: 2,
                color: _focused
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    CategoryVisuals.icon(category.id),
                    color: palette.foreground,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  category.nameFa,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${PersianNumbers.format(widget.count)} ابزار',
                  key: Key('category-count-${category.id.name}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
