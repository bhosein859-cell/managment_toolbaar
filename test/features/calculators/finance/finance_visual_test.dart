import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

void main() {
  const capture = bool.fromEnvironment('CAPTURE_FINANCE_VISUALS');
  testWidgets(
    'capture finance registry IRR valid and rejected roots and loan',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.runAsync(() async {
        final manifest = (jsonDecode(
          await rootBundle.loadString('FontManifest.json'),
        ) as List<Object?>).cast<Map<String, Object?>>();
        for (final family in manifest) {
          final fonts = (family['fonts']! as List<Object?>)
              .cast<Map<String, Object?>>();
          final loader = FontLoader(family['family']! as String)
            ..addFont(rootBundle.load(fonts.first['asset']! as String));
          await loader.load();
        }
      });
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ManagementToolboxApp(repository: DriftToolRepository.memory()),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> save(String name) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('docs/visual/stage10/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tap(find.text('ورود به برنامه'));
      await tap(find.byKey(const Key('category-finance')));
      await save('finance-category-desktop');
      await tap(find.byKey(const Key('category-tool-irr')));
      tester.view.physicalSize = const Size(1100, 2000);
      await tester.pumpAndSettle();
      await save('irr-valid-light-desktop');
      final input = find.byKey(const Key('input-cash_flows'));
      await tester.ensureVisible(input);
      await tester.enterText(input, '-100\n230\n-132');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.textContaining('یک جواب انتخابی'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('primary-result')), findsNothing);
      await save('irr-ambiguous-light-desktop');
      await tap(find.byType(BackButton));
      await tap(find.byKey(const Key('category-tool-loan_payment')));
      tester.view.physicalSize = const Size(390, 1100);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      await save('loan-dark-mobile');
      expect(tester.takeException(), isNull);
    },
    skip: !capture,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
