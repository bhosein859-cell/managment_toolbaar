import 'dart:io';

import 'package:management_toolbox/app/catalog/app_catalog.dart';

const catalogStart = '<!-- CALCULATORS:START -->';
const catalogEnd = '<!-- CALCULATORS:END -->';

String calculatorTable() {
  final catalog = AppCatalog.catalog;
  String cell(String value) =>
      value.replaceAll('|', r'\|').replaceAll('\n', ' ');
  final lines = <String>[
    '| ردیف | دسته | شناسهٔ پایدار | نام فارسی | English |',
    '|---:|---|---|---|---|',
  ];
  for (var i = 0; i < catalog.tools.length; i++) {
    final tool = catalog.tools[i];
    final category = catalog.categoryById(tool.categoryId)!;
    lines.add(
      '| ${i + 1} | ${cell(category.nameFa)} | `${tool.id}` | ${cell(tool.nameFa)} | ${cell(tool.nameEn)} |',
    );
  }
  return lines.join('\n');
}

String updateCatalog(String readme) {
  if (catalogStart.allMatches(readme).length != 1 ||
      catalogEnd.allMatches(readme).length != 1) {
    throw FormatException('README must have one calculator marker pair');
  }
  final start = readme.indexOf(catalogStart) + catalogStart.length;
  final end = readme.indexOf(catalogEnd);
  if (end < start) throw FormatException('Calculator markers are reversed');
  return readme.replaceRange(start, end, '\n${calculatorTable()}\n');
}

void main(List<String> args) {
  if (args.any((a) => a != '--check')) {
    stderr.writeln(
      'Usage: dart run tool/update_calculator_table.dart [--check]',
    );
    exitCode = 2;
    return;
  }
  final file = File('README.md');
  final before = file.readAsStringSync();
  final after = updateCatalog(before);
  if (args.contains('--check')) {
    if (before != after) {
      stderr.writeln(
        'Calculator table is stale; regenerate it from AppCatalog.',
      );
      exitCode = 1;
    }
  } else {
    file.writeAsStringSync(after);
  }
}
