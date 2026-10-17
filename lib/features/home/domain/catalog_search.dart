import '../../../core/utils/search_text.dart';
import '../../calculators/domain/calculator_domain.dart';
import 'tool_catalog.dart';

enum SearchMatch { exact, partial, fuzzy }

final class CatalogSearchHit {
  const CatalogSearchHit({
    required this.tool,
    required this.match,
    required this.score,
  });
  final CalculatorDefinition tool;
  final SearchMatch match;
  final int score;
}

/// Pre-indexed, offline, deterministic search. No package/server dependency.
final class CatalogSearch {
  CatalogSearch(ToolCatalog catalog)
    : _documents = [
        for (final tool in catalog.tools)
          _Document(tool, catalog.categoryById(tool.categoryId)),
      ];
  final List<_Document> _documents;
  static const maxQueryLength = 256;
  static const maxTokens = 16;

  List<CatalogSearchHit> search(String query, {int limit = 20}) {
    if (limit <= 0 || query.length > maxQueryLength) return const [];
    final normalized = SearchText.normalize(query);
    if (normalized.isEmpty) return const [];
    final tokens = normalized.split(' ');
    if (tokens.length > maxTokens) return const [];
    final compact = SearchText.compact(normalized);
    final hits = <CatalogSearchHit>[];
    for (final document in _documents) {
      var exact = 0;
      var partial = 0;
      for (final field in document.fields) {
        if (field.normalized == normalized || field.compact == compact) {
          if (field.weight > exact) exact = field.weight;
        } else if (field.normalized.contains(normalized) ||
            field.compact.contains(compact)) {
          if (field.weight > partial) partial = field.weight;
        }
      }
      if (exact > 0 || partial > 0) {
        hits.add(
          CatalogSearchHit(
            tool: document.tool,
            match: exact > 0 ? SearchMatch.exact : SearchMatch.partial,
            score: exact > 0 ? 1000 + exact : 600 + partial,
          ),
        );
        continue;
      }
      if (tokens.every(
        (token) =>
            document.fields.any((field) => field.normalized.contains(token)),
      )) {
        hits.add(
          CatalogSearchHit(
            tool: document.tool,
            match: SearchMatch.partial,
            score: 400,
          ),
        );
        continue;
      }
      var edits = 0;
      var matches = true;
      for (final token in tokens) {
        if (document.fields.any((field) => field.normalized.contains(token))) {
          continue;
        }
        if (token.length < 3 || token.length > 64) {
          matches = false;
          break;
        }
        final budget = token.length >= 6 ? 2 : 1;
        var best = budget + 1;
        for (final candidate in document.tokens) {
          final distance = boundedDamerauDistance(token, candidate, budget);
          if (distance < best) best = distance;
          if (best == 0) break;
        }
        if (best > budget) {
          matches = false;
          break;
        }
        edits += best;
      }
      if (matches) {
        hits.add(
          CatalogSearchHit(
            tool: document.tool,
            match: SearchMatch.fuzzy,
            score: 100 - edits,
          ),
        );
      }
    }
    hits.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : a.tool.id.compareTo(b.tool.id);
    });
    return List.unmodifiable(hits.take(limit));
  }
}

final class _IndexedField {
  _IndexedField(String text, this.weight)
    : normalized = SearchText.normalize(text),
      compact = SearchText.compact(SearchText.normalize(text));
  final String normalized;
  final String compact;
  final int weight;
}

final class _Document {
  _Document(this.tool, CalculatorCategory? category)
    : fields = [
        _IndexedField(tool.id, 110),
        _IndexedField(tool.nameFa, 100),
        _IndexedField(tool.nameEn, 90),
        for (final alias in tool.aliases) _IndexedField(alias, 95),
        _IndexedField(tool.description, 45),
        if (category != null) _IndexedField(category.nameFa, 30),
        if (category != null) _IndexedField(category.nameEn, 25),
      ] {
    tokens = {
      for (final field in fields) ...field.normalized.split(' '),
      for (final field in fields)
        if (field.compact.length <= 64) field.compact,
    }..remove('');
  }
  final CalculatorDefinition tool;
  final List<_IndexedField> fields;
  late final Set<String> tokens;
}

/// Banded optimal-string-alignment Damerau-Levenshtein, including one adjacent
/// transposition. Returns maxEdits+1 if outside the budget; not a full distance.
int boundedDamerauDistance(String a, String b, int maxEdits) {
  if (maxEdits < 0) throw ArgumentError('بودجهٔ فاصله نامعتبر است');
  final outside = maxEdits + 1;
  if ((a.length - b.length).abs() > maxEdits) return outside;
  if (a == b) return 0;
  if (a.isEmpty) return b.length <= maxEdits ? b.length : outside;
  if (b.isEmpty) return a.length <= maxEdits ? a.length : outside;
  var previous = List<int>.generate(b.length + 1, (index) => index);
  List<int>? beforePrevious;
  for (var i = 1; i <= a.length; i++) {
    final row = List<int>.filled(b.length + 1, outside);
    row[0] = i;
    var rowMin = outside;
    final start = i - maxEdits > 1 ? i - maxEdits : 1;
    final end = i + maxEdits < b.length ? i + maxEdits : b.length;
    for (var j = start; j <= end; j++) {
      final substitution =
          previous[j - 1] +
          (a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1);
      var value = substitution;
      if (previous[j] + 1 < value) value = previous[j] + 1;
      if (row[j - 1] + 1 < value) value = row[j - 1] + 1;
      if (i > 1 &&
          j > 1 &&
          beforePrevious != null &&
          a.codeUnitAt(i - 1) == b.codeUnitAt(j - 2) &&
          a.codeUnitAt(i - 2) == b.codeUnitAt(j - 1) &&
          beforePrevious[j - 2] + 1 < value) {
        value = beforePrevious[j - 2] + 1;
      }
      row[j] = value;
      if (value < rowMin) rowMin = value;
    }
    if (rowMin > maxEdits) return outside;
    beforePrevious = previous;
    previous = row;
  }
  return previous[b.length] <= maxEdits ? previous[b.length] : outside;
}
