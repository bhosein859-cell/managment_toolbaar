import 'dart:io';

import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/core/storage/toolbox_database.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

/// Run write, read-remove, then verify-removed in three independent processes.
Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw ArgumentError(
      'Usage: verify_local_storage.dart <write|read-remove|verify-removed> <db-path>',
    );
  }
  final repo = DriftToolRepository(ToolboxDatabase.file(File(args[1])));
  try {
    final mode = args[0];
    if (mode == 'write') {
      final start = await repo.load();
      if (start.recent.isNotEmpty || start.favorites.isNotEmpty) {
        throw StateError('Use a fresh database path');
      }
      await repo.toggleFavorite('oee', DateTime.now());
      final raw = RawCalculatorInput({
        ...PrototypeCalculators.oee.examples.single.inputs.values,
        'availability': const RawTextInput('50'),
      });
      final result = (PrototypeCalculators.oeeRunner.run(
        raw,
      ) as CalculationSuccess).result;
      for (var i = 0; i < 11; i++) {
        await repo.record('oee', raw, result, DateTime.now());
      }
    } else if (mode == 'read-remove' || mode == 'verify-removed') {
      final s = await repo.load();
      if (s.recent.length != 10 ||
          s.recent.first.sequence != 11 ||
          s.recent.last.sequence != 2) {
        throw StateError('Retention or persistence failed');
      }
      if ((s.recent.first.inputs.values['availability'] as RawTextInput).text !=
          '50') {
        throw StateError('Input snapshot failed');
      }
      if (((s.recent.first.result.primary.value as NumericResultValue).value -
                  0.4655)
              .abs() >
          1e-12) {
        throw StateError('Result snapshot failed');
      }
      if (mode == 'read-remove') {
        if (!s.favorites.contains('oee')) {
          throw StateError('Favorite was not durable');
        }
        await repo.toggleFavorite('oee', DateTime.now());
      } else if (s.favorites.isNotEmpty) {
        throw StateError('Favorite removal was not durable');
      }
    } else {
      throw ArgumentError('Unknown mode');
    }
    final version = await repo.database
        .customSelect('SELECT sqlite_version() AS version')
        .getSingle();
    stdout.writeln(
      '$mode: PASS; SQLite ${version.read<String>('version')}; committed, file-backed, background isolate',
    );
  } finally {
    await repo.close();
  }
}
