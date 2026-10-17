import '../../calculators/domain/calculator_domain.dart';

/// Immutable catalog containing implemented calculators only, not roadmap tools.
final class ToolCatalog {
  ToolCatalog({
    required Iterable<CalculatorCategory> categories,
    required Iterable<CalculatorDefinition> tools,
  }) : categories = List.unmodifiable(categories),
       tools = List.unmodifiable(tools) {
    if (this.categories.isEmpty) throw ArgumentError('دسته‌بندی لازم است');
    for (final category in this.categories) {
      if (_categories.containsKey(category.id)) {
        throw ArgumentError('دستهٔ تکراری');
      }
      _categories[category.id] = category;
    }
    for (final tool in this.tools) {
      if (_tools.containsKey(tool.id)) throw ArgumentError('ابزار تکراری');
      if (!_categories.containsKey(tool.categoryId)) {
        throw ArgumentError('دستهٔ ابزار موجود نیست');
      }
      _tools[tool.id] = tool;
    }
    for (final category in this.categories) {
      _byCategory[category.id] = List.unmodifiable(
        this.tools.where((tool) => tool.categoryId == category.id),
      );
    }
  }
  final List<CalculatorCategory> categories;
  final List<CalculatorDefinition> tools;
  final _categories = <CalculatorCategoryId, CalculatorCategory>{};
  final _tools = <String, CalculatorDefinition>{};
  final _byCategory = <CalculatorCategoryId, List<CalculatorDefinition>>{};

  CalculatorDefinition? toolById(String id) => _tools[id];
  CalculatorCategory? categoryById(CalculatorCategoryId id) => _categories[id];
  List<CalculatorDefinition> toolsIn(CalculatorCategoryId id) =>
      _byCategory[id] ?? const [];
}
