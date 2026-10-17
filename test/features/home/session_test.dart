import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/data/calculation_snapshot_codec.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';
import 'package:management_toolbox/features/home/presentation/controllers/tool_session_controller.dart';

void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
  test('favorites committed through repository; explicitly separate databases are isolated', () async {
    final session = ToolSessionController(
      catalog: AppCatalog.catalog,
      repository: DriftToolRepository.memory(),
    );
    final next = ToolSessionController(
      catalog: AppCatalog.catalog,
      repository: DriftToolRepository.memory(),
    );
    addTearDown(() => session.close());
    addTearDown(() => next.close());
    expect(await session.initialize(), isTrue);
    expect(await next.initialize(), isTrue);
    expect(await session.toggleFavorite('oee'), isTrue);
    expect(session.isFavorite('oee'), isTrue);
    final snapshot = session.favorites;
    expect(() => snapshot.clear(), throwsUnsupportedError);
    expect(await session.toggleFavorite('oee'), isTrue);
    expect(snapshot, {'oee'});
    expect(session.isFavorite('oee'), isFalse);
    expect(next.favorites, isEmpty);
    expect(() => session.toggleFavorite('fake'), throwsArgumentError);
  });
  test('repository snapshots preserve inputs and retain ten committed calculations', () async {
    final time = DateTime.utc(2026, 10, 16, 12),
        session = ToolSessionController(
          catalog: AppCatalog.catalog,
          repository: DriftToolRepository.memory(),
          now: () => DateTime.utc(2026, 10, 16, 12),
        );
    addTearDown(() => session.close());
    expect(await session.initialize(), isTrue);
    final input = PrototypeCalculators.oee.examples.single.inputs,
        result = (PrototypeCalculators.oeeRunner.run(
          input,
        ) as CalculationSuccess).result;
    for (var i = 0; i < 11; i++) {
      expect(await session.record('oee', input, result), isTrue);
    }
    expect(session.recent, hasLength(10));
    expect(session.recent.first.sequence, 11);
    expect(session.recent.last.sequence, 2);
    expect(session.recent.first.createdAt, time);
    expect(
      CalculationSnapshotCodec.encodeInputs(session.recent.first.inputs),
      CalculationSnapshotCodec.encodeInputs(input),
    );
    expect(() => session.recent.clear(), throwsUnsupportedError);
    expect(() => session.record('fake', input, result), throwsArgumentError);
  });
}
