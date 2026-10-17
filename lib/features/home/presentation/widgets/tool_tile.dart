import 'package:flutter/material.dart';

import '../../../../app/theme/category_colors.dart';
import '../../../calculators/domain/calculator_domain.dart';
import 'category_grid.dart';

String toolDisplayTitle(CalculatorDefinition tool) {
  final parts = tool.nameFa.split(' — ');
  return parts.length == 2 && parts.last.toLowerCase() == tool.id.toLowerCase()
      ? '${parts.last} — ${parts.first}'
      : tool.nameFa;
}

class ToolTile extends StatelessWidget {
  const ToolTile({
    super.key,
    required this.tool,
    required this.prefix,
    required this.isFavorite,
    required this.onOpen,
    required this.onFavorite,
    this.subtitle,
    this.approximate = false,
  });
  final CalculatorDefinition tool;
  final String prefix;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback? onFavorite;
  final String? subtitle;
  final bool approximate;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: Key('$prefix-tool-${tool.id}'),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
      mouseCursor: SystemMouseCursors.click,
      minLeadingWidth: 24,
      horizontalTitleGap: 12,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CategoryColors.forTheme(
            Theme.of(context),
            tool.categoryId,
          ).background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          CategoryVisuals.icon(tool.categoryId),
          color: CategoryColors.forTheme(
            Theme.of(context),
            tool.categoryId,
          ).foreground,
        ),
      ),
      title: Text(toolDisplayTitle(tool)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle ?? tool.description.split('\n').first,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (approximate)
            Text(
              'تطبیق تقریبی',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
        ],
      ),
      trailing: Semantics(
        label:
            '${isFavorite ? "حذف از" : "افزودن به"} علاقه‌مندی‌ها: ${tool.nameFa}',
        button: true,
        toggled: isFavorite,
        enabled: onFavorite != null,
        onTap: onFavorite,
        excludeSemantics: true,
        child: IconButton(
          key: Key('$prefix-favorite-${tool.id}'),
          tooltip: isFavorite
              ? 'حذف از علاقه‌مندی‌ها'
              : 'افزودن به علاقه‌مندی‌ها',
          onPressed: onFavorite,
          icon: Icon(
            isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          ),
          color: isFavorite ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      onTap: onOpen,
    ),
  );
}
