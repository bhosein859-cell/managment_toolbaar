import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

void main() {
  testWidgets('shows the foundation page without the sample counter', (
    tester,
  ) async {
    await tester.pumpWidget(
      ManagementToolboxApp(repository: DriftToolRepository.memory()),
    );
    await tester.pumpAndSettle();
    expect(find.text('جعبه‌ابزار مدیریت'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 640), const Size(1280, 720)]) {
    testWidgets('foundation fits viewport $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ManagementToolboxApp(repository: DriftToolRepository.memory()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
