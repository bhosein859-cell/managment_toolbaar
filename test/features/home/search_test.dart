import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/core/utils/search_text.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/home/domain/catalog_search.dart';
import 'package:management_toolbox/features/home/domain/tool_catalog.dart';

CalculatorDefinition fixture(
  String id, {
  String name = 'ابزار ۱۲۳',
  String description = 'توضیح ویژه',
  List<String> aliases = const [],
}) => CalculatorDefinition(
  id: id,
  categoryId: CalculatorCategoryId.production,
  nameFa: name,
  nameEn: 'Reference Tool',
  description: description,
  formulaLatex: 'x',
  fields: [],
  aliases: aliases,
);

int referenceDistance(String a, String b) {
  final d = List.generate(a.length + 1, (i) => List.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      d[i][j] = math.min(
        math.min(d[i - 1][j] + 1, d[i][j - 1] + 1),
        d[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1),
      );
      if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
        d[i][j] = math.min(d[i][j], d[i - 2][j - 2] + 1);
      }
    }
  }
  return d[a.length][b.length];
}

void main() {
  final catalog = AppCatalog.catalog;
  final search = CatalogSearch(catalog);
  test('nine honest categories, seventy-three implemented tools', () {
    expect(
      catalog.categories.map((item) => item.id).toSet(),
      CalculatorCategoryId.values.toSet(),
    );
    expect(catalog.tools.map((tool) => tool.id), [
      'oee',
      'takt_time',
      'production_capacity',
      'labor_productivity',
      'cycle_time',
      'smed',
      'unit_production_cost',
      'wip',
      'throughput',
      'capacity_utilization',
      'npv',
      'irr',
      'payback',
      'roi',
      'current_ratio',
      'quick_ratio',
      'wacc',
      'compound_interest',
      'loan_payment',
      'break_even',
      'cp',
      'cpk',
      'pp',
      'ppk',
      'dpmo',
      'sigma_level',
      'xbar_control',
      'coq',
      'eoq',
      'rop',
      'safety_stock',
      'abc',
      'inventory_turnover',
      'days_inventory',
      'inventory_holding_cost',
      'reorder_interval',
      'pert_duration',
      'cpm',
      'project_float',
      'evm_performance',
      'three_point',
      'eac_etc',
      'sv_cv',
      'duration_comparison',
      'cost_per_hire',
      'employee_turnover',
      'employee_productivity',
      'training_roi',
      'replacement_time',
      'absence_cost',
      'ahp',
      'topsis',
      'decision_matrix',
      'expected_value_tree',
      'weight_sensitivity',
      'weighted_scoring',
      'cost_benefit_comparison',
      'two_option_break_even',
      'time_value_money',
      'future_present_factor',
      'present_future_factor',
      'future_annuity_factor',
      'annuity_future_factor',
      'present_annuity_factor',
      'annuity_present_factor',
      'straight_line_depreciation',
      'declining_balance_depreciation',
      'inflation_adjustment',
      'percentage_of',
      'percentage_change',
      'percentage_base',
      'discount',
      'unit_conversion',
    ]);
    expect(catalog.toolsIn(CalculatorCategoryId.production), hasLength(10));
    expect(catalog.toolsIn(CalculatorCategoryId.inventory), hasLength(8));
    expect(catalog.toolsIn(CalculatorCategoryId.quality), hasLength(8));
    expect(catalog.toolsIn(CalculatorCategoryId.project), hasLength(8));
    expect(catalog.toolsIn(CalculatorCategoryId.humanResources), hasLength(6));
    expect(catalog.toolsIn(CalculatorCategoryId.decisionMaking), hasLength(8));
    expect(
      catalog.toolsIn(CalculatorCategoryId.engineeringEconomics),
      hasLength(10),
    );
    expect(catalog.toolById('not_implemented'), isNull);
    expect(catalog.toolById('form_demo'), isNull);
    expect(() => catalog.tools.clear(), throwsUnsupportedError);
    expect(() => catalog.categories.clear(), throwsUnsupportedError);
    expect(
      () => catalog.toolsIn(CalculatorCategoryId.production).clear(),
      throwsUnsupportedError,
    );
  });
  test('catalog guards missing categories and duplicate IDs', () {
    final category = catalog.categories.first;
    expect(() => ToolCatalog(categories: [], tools: []), throwsArgumentError);
    expect(
      () => ToolCatalog(categories: [category, category], tools: []),
      throwsArgumentError,
    );
    expect(
      () => ToolCatalog(
        categories: [category],
        tools: [fixture('a'), fixture('a')],
      ),
      throwsArgumentError,
    );
    expect(
      () => ToolCatalog(
        categories: [category],
        tools: [catalog.toolById('npv')!],
      ),
      throwsArgumentError,
    );
  });
  test('normalizes Arabic letters digits marks spaces and punctuation without changing source', () {
    const input = '  كِيفيت‌ ي ۱۲٣  NPV ـ ';
    expect(SearchText.normalize(input), 'کیفیت ی 123 npv');
    expect(SearchText.normalize('\u2066آزمون\u2069 ١٢٣'), 'ازمون 123');
    expect(
      SearchText.compact(SearchText.normalize('بهره‌وری')),
      SearchText.compact(SearchText.normalize('بهره وری')),
    );
    expect(input, contains('ك'));
  });
  for (final query in [
    'OEE',
    'اثربخشي كلي تجهيزات',
    'بهره‌وری تجهیزات',
    'بهره وری تجهیزات',
    'بهرهوری تجهیزات',
  ]) {
    test('finds OEE by name/alias/normalization: $query', () {
      expect(search.search(query).first.tool.id, 'oee');
    });
  }
  for (final query in [
    'NPV',
    'Net present VALUE',
    'ارزش خالص فعلی',
    'ارزش‌خالص‌فعلی',
    'ارزشخالصفعلی',
    'دوره‌های برابر',
  ]) {
    test('finds NPV by English/alias/description: $query', () {
      expect(search.search(query).first.tool.id, 'npv');
    });
  }
  for (final query in ['Cp', 'توانمندي فرايند', 'Process Capability Index']) {
    test('finds Cp by metadata: $query', () {
      expect(search.search(query).first.tool.id, 'cp');
    });
  }
  test('broad Quality search includes Cp among eight quality tools', () {
    expect(search.search('Quality').map((h) => h.tool.id), contains('cp'));
  });
  test('multi-token queries can match across indexed fields', () {
    expect(search.search('oee کیفیت').first.tool.id, 'oee');
    expect(search.search('ارزش پرتقال'), isEmpty);
  });
  for (final query in ['nvp', 'اثربخشب', 'capabilty']) {
    test('light fuzzy handles deletion/substitution/transposition: $query', () {
      final hit = search.search(query).first;
      expect(hit.match, SearchMatch.fuzzy);
      expect(
        hit.tool.id,
        query == 'nvp'
            ? 'npv'
            : query == 'اثربخشب'
            ? 'oee'
            : 'cp',
      );
    });
  }
  test('short inputs do not get speculative fuzzy matches', () {
    expect(search.search('zz'), isEmpty);
    expect(search.search('zzzzzzzzzz'), isEmpty);
    expect(search.search(''), isEmpty);
    expect(search.search('؟؟؟'), isEmpty);
    expect(search.search('x' * 257), isEmpty);
    expect(search.search(List.filled(17, 'oee').join(' ')), isEmpty);
    expect(search.search('oee', limit: 0), isEmpty);
  });
  test('all three digit sets match the same synthetic metadata', () {
    final local = CatalogSearch(
      ToolCatalog(categories: catalog.categories, tools: [fixture('digits')]),
    );
    for (final query in ['123', '۱۲۳', '١٢٣']) {
      expect(local.search(query).single.tool.id, 'digits');
    }
  });
  test(
    'exact metadata outranks fuzzy hits, ties and limits are deterministic',
    () {
      final local = CatalogSearch(
        ToolCatalog(
          categories: catalog.categories,
          tools: [
            fixture('b', name: 'مشترک'),
            fixture('a', name: 'مشترک'),
            fixture('c', name: 'مشترگ'),
          ],
        ),
      );
      final hits = local.search('مشترک');
      expect(hits.map((hit) => hit.tool.id), ['a', 'b', 'c']);
      expect(hits.last.match, SearchMatch.fuzzy);
      expect(local.search('مشترک', limit: 1).single.tool.id, 'a');
      expect(() => hits.clear(), throwsUnsupportedError);
    },
  );
  test(
    'banded Damerau agrees with full reference on exhaustive short strings',
    () {
      var layer = <String>[''];
      final strings = <String>[''];
      for (var length = 1; length <= 3; length++) {
        layer = [
          for (final text in layer)
            for (final char in ['a', 'b', 'ک']) '$text$char',
        ];
        strings.addAll(layer);
      }
      for (final a in strings) {
        for (final b in strings) {
          final expected = referenceDistance(a, b);
          for (var budget = 0; budget <= 2; budget++) {
            expect(
              boundedDamerauDistance(a, b, budget),
              expected <= budget ? expected : budget + 1,
              reason: '$a/$b/$budget',
            );
          }
        }
      }
      expect(() => boundedDamerauDistance('a', 'b', -1), throwsArgumentError);
    },
  );
}
