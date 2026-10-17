import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/domain/tool_repository.dart';

import '../../tool/update_calculator_table.dart' as docs;

class PendingRepository implements ToolRepository {
  final pending = Completer<StoredTools>();
  bool closed = false;
  @override
  Future<StoredTools> load() => pending.future;
  @override
  Future<void> close() async => closed = true;
  @override
  Future<StoredTools> toggleFavorite(String id, DateTime time) =>
      throw UnsupportedError('Not used by startup test');
  @override
  Future<StoredTools> record(
    String id,
    RawCalculatorInput inputs,
    CalculationResult result,
    DateTime time,
  ) => throw UnsupportedError('Not used by startup test');
}

void main() {
  test('README table contains exactly the real 73 calculator IDs', () {
    final readme = File('README.md').readAsStringSync();
    expect(docs.updateCatalog(readme), readme);
    expect(AppCatalog.catalog.tools, hasLength(73));
    final table = docs.calculatorTable();
    expect(table.split('\n'), hasLength(75));
    for (final tool in AppCatalog.catalog.tools) {
      expect('`${tool.id}`'.allMatches(table), hasLength(1));
    }
  });

  test(
    'table update preserves surrounding docs and rejects malformed markers',
    () {
      final input =
          'before\n${docs.catalogStart}\nstale\n${docs.catalogEnd}\nafter';
      final output = docs.updateCatalog(input);
      expect(output, startsWith('before\n'));
      expect(output, endsWith('\nafter'));
      expect(docs.updateCatalog(output), output);
      expect(() => docs.updateCatalog('missing'), throwsFormatException);
      expect(
        () => docs.updateCatalog('${docs.catalogEnd}${docs.catalogStart}'),
        throwsFormatException,
      );
      expect(
        () => docs.updateCatalog('${docs.catalogStart}$input'),
        throwsFormatException,
      );
    },
  );

  for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
    testWidgets('branded RTL startup then welcome on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        final repo = PendingRepository();
        await tester.pumpWidget(ManagementToolboxApp(repository: repo));
        await tester.pump();
        expect(find.byKey(const Key('app-startup-splash')), findsOneWidget);
        expect(find.text('سازنده حسین بختیاری'), findsOneWidget);
        final splash = find.byKey(const Key('app-startup-splash'));
        expect(Directionality.of(tester.element(splash)), TextDirection.rtl);
        expect(find.byType(Image), findsOneWidget);
        repo.pending.complete(
          StoredTools(favorites: const {}, recent: const []),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('app-startup-splash')), findsNothing);
        expect(find.text('ورود به برنامه'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        expect(repo.closed, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('startup fits 360px viewport with large Persian text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 360);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repo = PendingRepository();
    await tester.pumpWidget(ManagementToolboxApp(repository: repo));
    await tester.pump();
    expect(find.byKey(const Key('app-startup-splash')), findsOneWidget);
    expect(tester.takeException(), isNull);
    repo.pending.complete(StoredTools(favorites: const {}, recent: const []));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('storage failure exits splash and keeps retry available', (
    tester,
  ) async {
    final repo = PendingRepository();
    await tester.pumpWidget(ManagementToolboxApp(repository: repo));
    await tester.pump();
    repo.pending.completeError(StateError('injected startup failure'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app-startup-splash')), findsNothing);
    expect(find.byKey(const Key('storage-startup-error')), findsOneWidget);
    expect(find.byKey(const Key('storage-retry')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(repo.closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}
