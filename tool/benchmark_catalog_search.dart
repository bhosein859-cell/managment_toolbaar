// Reproducible offline search benchmark; synthetic tools NEVER enter the app.
import 'dart:convert';
import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/home/domain/catalog_search.dart';
import 'package:management_toolbox/features/home/domain/tool_catalog.dart';

const queries = [
  'oee',
  'NPV',
  'ارزش خالص فعلی',
  'اثربخشي كلي تجهيزات',
  'بهرهوری تجهیزات',
  'nvp',
  'اثربخشب',
  'capabilty',
  'کیفیت',
  'zzzzzzzzzz',
];
Map<String, Object> measure(ToolCatalog catalog, int iterations, String label) {
  final build = Stopwatch()..start();
  final search = CatalogSearch(catalog);
  build.stop();
  for (var i = 0; i < 100; i++) {
    search.search(queries[i % queries.length]);
  }
  final samples = <double>[];
  var checksum = 0;
  final total = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    final timer = Stopwatch()..start();
    final hits = search.search(queries[i % queries.length]);
    timer.stop();
    samples.add(timer.elapsedTicks * 1000000 / timer.frequency);
    checksum += hits.length;
  }
  total.stop();
  samples.sort();
  return {
    'label': label,
    'tools': catalog.tools.length,
    'iterations': iterations,
    'index_build_ms': build.elapsedMicroseconds / 1000,
    'median_query_us': samples[samples.length ~/ 2],
    'p95_query_us': samples[(samples.length * 0.95).floor()],
    'max_query_us': samples.last,
    'total_ms': total.elapsedMicroseconds / 1000,
    'checksum': checksum,
  };
}

void main() {
  final actual = AppCatalog.catalog;
  final synthetic = ToolCatalog(
    categories: actual.categories,
    tools: [
      for (var i = 0; i < 1000; i++)
        CalculatorDefinition(
          id: 'bench_$i',
          categoryId: actual.tools[i % actual.tools.length].categoryId,
          nameFa: 'ابزار آزمایشی شماره $i',
          nameEn: 'Synthetic Calculator $i',
          description: actual.tools[i % actual.tools.length].description,
          aliases: actual.tools[i % actual.tools.length].aliases,
          formulaLatex: 'benchmark only',
          fields: [],
        ),
    ],
  );
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'purpose': 'Linux sandbox AOT measurements, not Android/Windows device guarantees',
      'runtime': Platform.version,
      'os': Platform.operatingSystem,
      'queries': queries,
      'cases': [
        measure(actual, 3000, 'actual_app_catalog'),
        measure(synthetic, 300, 'synthetic_stress_only'),
      ],
    }),
  );
}
