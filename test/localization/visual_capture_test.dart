import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/theme/theme_settings.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

// Opt-in, real-font rendering evidence, not a pixel-perfect golden baseline.
// flutter test --dart-define=CAPTURE_VISUALS=true test/localization/visual_capture_test.dart
void main() {
  const capture = bool.fromEnvironment('CAPTURE_VISUALS');
  for (final dark in [false, true]) {
    testWidgets('capture real-font lab ${dark ? 'dark' : 'light'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = FontLoader('Vazirmatn')
        ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ManagementToolboxApp(repository: DriftToolRepository.memory()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ورود به برنامه'));
      await tester.pumpAndSettle();
      final context = tester.element(find.text('جعبه‌ابزار مدیریت'));
      ThemeScope.of(context).setMode(dark ? ThemeMode.dark : ThemeMode.light);
      await tester.tap(find.byTooltip('آزمایش فارسی'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('numeric-input')), '۱۲۳٫۴۵');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          'docs/visual/stage04/lab-${dark ? 'dark' : 'light'}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }, skip: !capture);
  }
}
