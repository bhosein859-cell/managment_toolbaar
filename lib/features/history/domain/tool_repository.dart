import '../../calculators/domain/calculator_domain.dart';
import 'recent_calculation.dart';

final class StoredTools {
  StoredTools({
    required Iterable<String> favorites,
    required Iterable<RecentCalculation> recent,
  }) : favorites = Set.unmodifiable(favorites),
       recent = List.unmodifiable(recent);
  final Set<String> favorites;
  final List<RecentCalculation> recent;
}

abstract interface class ToolRepository {
  Future<StoredTools> load();
  Future<StoredTools> toggleFavorite(String calculatorId, DateTime createdAt);
  Future<StoredTools> record(
    String calculatorId,
    RawCalculatorInput inputs,
    CalculationResult result,
    DateTime createdAt,
  );
  Future<void> close();
}

final class StorageReadException implements Exception {
  const StorageReadException();
  @override
  String toString() =>
      'دادهٔ ذخیره‌شده خوانده نشد؛ داده حذف یا با مثال جایگزین نشده است.';
}
