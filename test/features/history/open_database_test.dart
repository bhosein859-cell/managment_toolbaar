import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/core/storage/open_local_database.dart';
import 'package:management_toolbox/core/storage/toolbox_database.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

import 'fixtures.dart';

void main() {
  test('production opener creates stable support file in background isolate and reopens it', () async {
    final root = Directory.systemTemp.createTempSync('toolbox-support-');
    addTearDown(() => root.deleteSync(recursive: true));
    final support = Directory('${root.path}/nested/application-support');
    var repo = DriftToolRepository(
      openApplicationDatabase(directoryProvider: () async => support),
    );
    await repo.toggleFavorite('oee', clock);
    await repo.record('oee', input, result, clock);
    await repo.close();
    expect(
      File('${support.path}/management_toolbox.sqlite').existsSync(),
      isTrue,
    );
    repo = DriftToolRepository(
      openApplicationDatabase(directoryProvider: () async => support),
    );
    expect((await repo.load()).favorites, {'oee'});
    expect((await repo.load()).recent, hasLength(1));
    await repo.close();
  });
  test('retry reconstructs a failed lazy opener; never masks failure with memory storage', () async {
    final root = Directory.systemTemp.createTempSync('toolbox-retry-');
    addTearDown(() => root.deleteSync(recursive: true));
    var attempts = 0;
    ToolboxDatabase create() => openApplicationDatabase(
      directoryProvider: () async {
        if (attempts++ == 0) {
          throw const FileSystemException('transient directory failure');
        }
        return root;
      },
    );
    final repo = DriftToolRepository(create(), reopen: create);
    await expectLater(repo.load(), throwsA(anything));
    expect(
      File('${root.path}/management_toolbox.sqlite').existsSync(),
      isFalse,
    );
    expect((await repo.load()).recent, isEmpty);
    expect(attempts, 2);
    await repo.toggleFavorite('oee', clock);
    await repo.close();
    final reopened = DriftToolRepository(create());
    expect((await reopened.load()).favorites, {'oee'});
    await reopened.close();
  });
}
