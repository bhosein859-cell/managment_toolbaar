import '../src/guards.dart';

enum CalculatorCategoryId {
  production,
  finance,
  quality,
  inventory,
  project,
  humanResources,
  decisionMaking,
  engineeringEconomics,
  utilities,
}

final class CalculatorCategory {
  CalculatorCategory({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.description,
  }) {
    requireText(nameFa, 'nameFa');
    requireText(nameEn, 'nameEn');
    requireText(description, 'description');
  }

  final CalculatorCategoryId id;
  final String nameFa;
  final String nameEn;
  final String description;
}
