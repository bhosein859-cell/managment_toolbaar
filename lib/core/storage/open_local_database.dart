import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'toolbox_database.dart';

/// Production always uses a durable application-support file, never temp or
/// silently falling back to an in-memory store on an I/O error.
ToolboxDatabase openApplicationDatabase({
  Future<Directory> Function()? directoryProvider,
}) => ToolboxDatabase(
  LazyDatabase(() async {
    final directory =
        await (directoryProvider ?? getApplicationSupportDirectory)();
    await directory.create(recursive: true);
    return NativeDatabase.createInBackground(
      File(p.join(directory.path, 'management_toolbox.sqlite')),
    );
  }),
);
