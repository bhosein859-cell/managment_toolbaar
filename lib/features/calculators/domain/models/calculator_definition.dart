import '../src/guards.dart';
import 'calculation_result.dart';
import 'calculator_category.dart';
import 'calculator_input.dart';
import 'input_field_definition.dart';

final class RelatedTerm {
  RelatedTerm({
    required this.id,
    required this.nameFa,
    required this.nameEn,
    required this.description,
  }) {
    requireId(id);
    requireText(nameFa, 'nameFa');
    requireText(nameEn, 'nameEn');
    requireText(description, 'description');
  }
  final String id;
  final String nameFa;
  final String nameEn;
  final String description;
}

final class CalculatorExample {
  CalculatorExample({
    required this.title,
    required this.inputs,
    required this.explanation,
    this.expectedResult,
  }) {
    requireText(title, 'title');
    requireText(explanation, 'explanation');
  }
  final String title;
  final RawCalculatorInput inputs;
  final String explanation;
  final CalculationResult? expectedResult;
}

/// Educational strings are display-only: never evaluate formulaLatex as code.
final class CalculatorDefinition {
  CalculatorDefinition({
    required this.id,
    required this.categoryId,
    required this.nameFa,
    required this.nameEn,
    required this.description,
    required this.formulaLatex,
    required Iterable<InputFieldDefinition> fields,
    this.assumptions = '',
    Iterable<String> aliases = const [],
    Iterable<CalculatorExample> examples = const [],
    Iterable<RelatedTerm> relatedTerms = const [],
  }) : fields = List.unmodifiable(fields),
       aliases = List.unmodifiable(aliases),
       examples = List.unmodifiable(examples),
       relatedTerms = List.unmodifiable(relatedTerms) {
    requireId(id);
    requireText(nameFa, 'nameFa');
    requireText(nameEn, 'nameEn');
    requireText(description, 'description');
    requireText(formulaLatex, 'formulaLatex');
    requireUnique(this.fields.map((field) => field.id));
    requireUnique(this.relatedTerms.map((term) => term.id));
    final ids = this.fields.map((field) => field.id).toSet();
    for (final example in this.examples) {
      if (example.inputs.values.keys.any((key) => !ids.contains(key))) {
        throw ArgumentError('مثال به فیلد ناشناخته ارجاع می‌دهد');
      }
    }
  }
  final String id;
  final CalculatorCategoryId categoryId;
  final String nameFa;
  final String nameEn;
  final String description;
  final String formulaLatex;
  final String assumptions;
  final List<InputFieldDefinition> fields;
  final List<String> aliases;
  final List<CalculatorExample> examples;
  final List<RelatedTerm> relatedTerms;
}
