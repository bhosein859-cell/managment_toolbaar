import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/glossary/domain/glossary_catalog.dart';
import 'package:management_toolbox/features/glossary/presentation/glossary_page.dart';
import 'package:management_toolbox/features/home/domain/tool_catalog.dart';

void main() {
  final catalog = GlossaryCatalog.fromTools(AppCatalog.catalog);
  test('offline entries are complete, immutable, uniquely category-scoped and all links resolve', () {
    expect(catalog.entries.length, greaterThanOrEqualTo(73));
    expect(
      catalog.entries.map((e) => e.id).toSet().length,
      catalog.entries.length,
    );
    for (final entry in catalog.entries) {
      expect(entry.nameFa, isNotEmpty);
      expect(entry.nameEn, isNotEmpty);
      expect(entry.description, isNotEmpty);
      expect(entry.summary, isNotEmpty);
      expect(entry.description, startsWith(entry.summary));
      expect(AppCatalog.catalog.categoryById(entry.categoryId), isNotNull);
      expect(entry.calculatorIds, isNotEmpty);
      for (final id in entry.calculatorIds) {
        expect(AppCatalog.catalog.toolById(id), isNotNull);
      }
      expect(() => entry.calculatorIds.clear(), throwsUnsupportedError);
    }
    expect(() => catalog.entries.clear(), throwsUnsupportedError);
  });
  test(
    'English case, Persian forms, ZWNJ, empty query and category intersection',
    () {
      expect(
        catalog.search('oEe').any((e) => e.id == 'production:oee'),
        isTrue,
      );
      expect(
        catalog.search('اثربخشي كلي').any((e) => e.id == 'production:oee'),
        isTrue,
      );
      expect(catalog.search('بهرهوری'), isNotEmpty);
      expect(
        catalog
            .search('درصد')
            .every(
              (e) =>
                  e.nameFa.contains('درصد') || e.description.contains('درصد'),
            ),
        isTrue,
      );
      expect(
        catalog.search('', category: CalculatorCategoryId.utilities),
        hasLength(5),
      );
      expect(
        catalog.search('oee', category: CalculatorCategoryId.utilities),
        isEmpty,
      );
      expect(catalog.search(''), hasLength(catalog.entries.length));
      expect(catalog.search('zzzznonexistent'), isEmpty);
    },
  );
  test('same term in one discipline merges links, same id across categories stays separate', () {
    final base = AppCatalog.catalog.tools.first;
    CalculatorDefinition make(String id, CalculatorCategoryId category) =>
        CalculatorDefinition(
          id: id,
          categoryId: category,
          nameFa: 'ابزار $id',
          nameEn: id,
          description: 'آزمون',
          formulaLatex: 'x',
          fields: base.fields,
          relatedTerms: [
            RelatedTerm(
              id: 'shared',
              nameFa: 'اصطلاح مشترک',
              nameEn: 'Shared',
              description: 'توضیح کوتاه و مستقل اصطلاح مشترک برای آزمون.',
            ),
          ],
        );
    final tools = ToolCatalog(
      categories: AppCatalog.catalog.categories,
      tools: [
        make('one', CalculatorCategoryId.production),
        make('two', CalculatorCategoryId.production),
        make('three', CalculatorCategoryId.finance),
      ],
    );
    final result = GlossaryCatalog.fromTools(tools);
    expect(result.entries, hasLength(2));
    expect(
      result.entries
          .singleWhere((e) => e.categoryId == CalculatorCategoryId.production)
          .calculatorIds,
      ['one', 'two'],
    );
  });
  testWidgets(
    'offline glossary filters, no-match state and actual calculator link callback',
    (tester) async {
      String? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: GlossaryPage(
              catalog: catalog,
              onOpenCalculator: (id) => opened = id,
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('glossary-search')), 'OEE');
      await tester.pumpAndSettle();
      expect(find.text('OEE'), findsWidgets);
      final link = find.byKey(const Key('term-link-production:oee-oee'));
      await tester.ensureVisible(link);
      await tester.tap(link);
      expect(opened, 'oee');
      await tester.enterText(
        find.byKey(const Key('glossary-search')),
        'nothingzzzz',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('glossary-empty')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('glossary-search')), '');
      await tester.tap(find.byKey(const Key('glossary-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ابزارهای عمومی').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('glossary-count'))).data,
        '۵ اصطلاح',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
