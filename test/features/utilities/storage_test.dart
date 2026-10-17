import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/app_catalog.dart';
import 'package:management_toolbox/app/catalog/utility_calculators.dart';
import 'package:management_toolbox/core/storage/toolbox_database.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/data/calculation_snapshot_codec.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';
import 'package:management_toolbox/features/home/presentation/controllers/tool_session_controller.dart';

void main() {
  test('all five utilities persist exact raw inputs, results and favorites across file reopen without schema change', () async {
    final dir = Directory.systemTemp.createTempSync('toolbox-stage17-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/toolbox.sqlite');
    ToolSessionController open() => ToolSessionController(
      catalog: AppCatalog.catalog,
      repository: DriftToolRepository(
        ToolboxDatabase.file(file, background: false),
      ),
    );
    final session = open();
    expect(await session.initialize(), isTrue);
    final encoded = <String, String>{};
    for (final runner in UtilityCalculators.runners) {
      final raw = RawCalculatorInput({
        ...runner.definition.examples.single.inputs.values,
        runner.definition.fields.first.id: const RawTextInput('  ۵۰  '),
      });
      final result = (runner.run(raw) as CalculationSuccess).result;
      expect(await session.toggleFavorite(runner.definition.id), isTrue);
      expect(await session.record(runner.definition.id, raw, result), isTrue);
      encoded[runner.definition.id] = CalculationSnapshotCodec.encodeResult(
        result,
      );
    }
    await session.close();
    session.dispose();
    final reopened = open();
    try {
      expect(await reopened.initialize(), isTrue);
      expect(reopened.favorites, UtilityCalculators.byId.keys.toSet());
      expect(reopened.recent, hasLength(5));
      for (final record in reopened.recent) {
        final r = UtilityCalculators.byId[record.calculatorId]!;
        expect(
          (record.inputs.values[r.definition.fields.first.id] as RawTextInput)
              .text,
          '  ۵۰  ',
        );
        expect(
          CalculationSnapshotCodec.encodeResult(record.result),
          encoded[record.calculatorId],
        );
        expect(
          CalculationSnapshotCodec.encodeResult(
            (r.run(record.inputs) as CalculationSuccess).result,
          ),
          encoded[record.calculatorId],
        );
      }
    } finally {
      await reopened.close();
      reopened.dispose();
    }
  });
}
