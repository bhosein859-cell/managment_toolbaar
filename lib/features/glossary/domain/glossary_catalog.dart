import '../../../core/utils/search_text.dart';
import '../../calculators/domain/calculator_domain.dart';
import '../../home/domain/tool_catalog.dart';

final class GlossaryEntry {
  GlossaryEntry({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.description,
    required this.categoryId,
    required Iterable<String> calculatorIds,
  }) : calculatorIds = List.unmodifiable(calculatorIds);
  final String id, nameFa, nameEn, description;
  final CalculatorCategoryId categoryId;
  final List<String> calculatorIds;

  /// Excerpt at a clause boundary only; the full explanation remains available.
  String get summary {
    final stops = RegExp(r'[.؛\n]').allMatches(description);
    for (final stop in stops) {
      if (stop.start >= 45) return description.substring(0, stop.end);
    }
    return description;
  }
}

/// Derived solely from shipped metadata. Category-scoped IDs avoid merging
/// homonyms across disciplines; repeated terms link all related calculators.
final class GlossaryCatalog {
  GlossaryCatalog._(this.tools, Iterable<GlossaryEntry> entries)
    : entries = List.unmodifiable(entries);
  factory GlossaryCatalog.fromTools(ToolCatalog tools) {
    final terms = <String, RelatedTerm>{},
        links = <String, Set<String>>{},
        categories = <String, CalculatorCategoryId>{};
    for (final tool in tools.tools) {
      for (final term in tool.relatedTerms) {
        final key = '${tool.categoryId.name}:${term.id}';
        terms.putIfAbsent(key, () => term);
        categories[key] = tool.categoryId;
        links.putIfAbsent(key, () => {}).add(tool.id);
      }
    }
    final entries = [
      for (final item in terms.entries)
        GlossaryEntry(
          id: item.key,
          nameFa: item.value.nameFa,
          nameEn: item.value.nameEn,
          description: item.value.description,
          categoryId: categories[item.key]!,
          calculatorIds: links[item.key]!,
        ),
    ];
    entries.sort(
      (a, b) =>
          SearchText.normalize(a.nameFa)
              .compareTo(SearchText.normalize(b.nameFa)),
    );
    return GlossaryCatalog._(tools, entries);
  }
  final ToolCatalog tools;
  final List<GlossaryEntry> entries;
  List<GlossaryEntry> search(String query, {CalculatorCategoryId? category}) {
    final words = SearchText.normalize(query)
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    return List.unmodifiable(
      entries.where((entry) {
        if (category != null && entry.categoryId != category) return false;
        final haystack = SearchText.normalize(
          '${entry.nameFa} ${entry.nameEn} ${entry.description} ${tools.categoryById(entry.categoryId)!.nameFa}',
        );
        final compact = SearchText.compact(haystack);
        return words.every(
          (word) =>
              haystack.contains(word) ||
              compact.contains(SearchText.compact(word)),
        );
      }),
    );
  }
}
