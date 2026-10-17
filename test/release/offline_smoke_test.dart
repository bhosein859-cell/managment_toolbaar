import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/decision_calculators.dart';
import 'package:management_toolbox/app/catalog/engineering_economics_calculators.dart';
import 'package:management_toolbox/app/catalog/finance_calculators.dart';
import 'package:management_toolbox/app/catalog/hr_calculators.dart';
import 'package:management_toolbox/app/catalog/inventory_calculators.dart';
import 'package:management_toolbox/app/catalog/production_calculators.dart';
import 'package:management_toolbox/app/catalog/project_calculators.dart';
import 'package:management_toolbox/app/catalog/quality_calculators.dart';
import 'package:management_toolbox/app/catalog/utility_calculators.dart';
import 'package:management_toolbox/core/storage/toolbox_database.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/glossary/domain/glossary_catalog.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

class DenyNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Network forbidden during offline smoke test');
  }
}

// A zonal override wins over flutter_test's own HTTP override. Probe it first
// so a false-positive zero-attempt counter cannot masquerade as network denial.
Future<void> withoutHttp(Future<void> Function(DenyNetwork) body) {
  final guard = DenyNetwork();
  return HttpOverrides.runWithHttpOverrides(() async {
    expect(() => HttpClient(), throwsStateError);
    expect(guard.attempts, 1);
    guard.attempts = 0;
    await body(guard);
    expect(guard.attempts, 0);
  }, guard);
}

void main() {
  test(
    'all 73 real examples, glossary, 11th-record retention and favorites reopen without Dart HTTP',
    () => withoutHttp((guard) async {
      final folder = Directory.systemTemp.createTempSync('toolbox-offline-');
      try {
        final runners = <CalculatorRunner<CalculatorParameters>>[
          ...ProductionCalculators.runners,
          ...FinanceCalculators.runners,
          ...QualityCalculators.runners,
          ...InventoryCalculators.runners,
          ...ProjectCalculators.runners,
          ...HrCalculators.runners,
          ...DecisionCalculators.runners,
          ...EngineeringEconomicsCalculators.runners,
          ...UtilityCalculators.runners,
        ];
        expect(runners, hasLength(73));
        for (final r in runners) {
          expect(
            r.run(r.definition.examples.single.inputs),
            isA<CalculationSuccess>(),
            reason: r.definition.id,
          );
        }
        final glossary = GlossaryCatalog.fromTools(AppCatalog.catalog);
        expect(glossary.search('oee'), isNotEmpty);
        expect(glossary.search('درصد'), isNotEmpty);
        final file = File('${folder.path}/offline.sqlite');
        var repo = DriftToolRepository(
          ToolboxDatabase.file(file, background: false),
        );
        final runner = UtilityCalculators.percentageOfRunner,
            raw = UtilityCalculators.percentageOf.examples.single.inputs;
        final result = (runner.run(raw) as CalculationSuccess).result;
        await repo.toggleFavorite('percentage_of', DateTime.now());
        for (var i = 0; i < 11; i++) {
          await repo.record('percentage_of', raw, result, DateTime.now());
        }
        await repo.close();
        repo = DriftToolRepository(
          ToolboxDatabase.file(file, background: false),
        );
        try {
          final state = await repo.load();
          expect(state.recent, hasLength(10));
          expect(state.recent.first.sequence, 11);
          expect(state.recent.last.sequence, 2);
          expect(state.favorites, {'percentage_of'});
          expect(
            runner.run(state.recent.first.inputs),
            isA<CalculationSuccess>(),
          );
        } finally {
          await repo.close();
        }
        expect(guard.attempts, 0);
      } finally {
        folder.deleteSync(recursive: true);
      }
    }),
  );
  testWidgets(
    'offline app shell, glossary and Persian/Latin form input work with HTTP denied',
    (tester) => withoutHttp((guard) async {
      final repository = DriftToolRepository.memory();
      try {
        await tester.pumpWidget(ManagementToolboxApp(repository: repository));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ورود به برنامه'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('open-glossary')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('glossary-search')),
          'Percentage of Amount',
        );
        await tester.pumpAndSettle();
        final link = find.byKey(
          const Key('term-link-utilities:percentage_of-percentage_of'),
        );
        await tester.ensureVisible(link);
        await tester.tap(link);
        await tester.pumpAndSettle();
        final field = find.byKey(const Key('input-amount'));
        expect(Directionality.of(tester.element(field)), TextDirection.rtl);
        for (final text in ['250', '۲۵۰', '٢٥٠']) {
          await tester.ensureVisible(field);
          await tester.enterText(field, text);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<SelectableText>(find.byKey(const Key('primary-result')))
                .data,
            '۵۰',
          );
        }
        await tester.enterText(field, '0');
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<SelectableText>(find.byKey(const Key('primary-result')))
              .data,
          '۰',
        );
        for (final invalid in ['-1', 'NaN', 'Infinity', '1e309']) {
          await tester.enterText(field, invalid);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('primary-result')), findsNothing);
        }
        expect(guard.attempts, 0);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.runAsync(repository.close);
      }
    }),
  );
  test('source main manifest (not merged output) and local assets have no direct network dependency', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, isNot(contains('android.permission.INTERNET')));
    for (final name in [
      'assets/branding/logo.png',
      'assets/fonts/Vazirmatn-Regular.ttf',
      'assets/fonts/Vazirmatn-Bold.ttf',
    ]) {
      expect(File(name).existsSync(), isTrue);
    }
  });
}
