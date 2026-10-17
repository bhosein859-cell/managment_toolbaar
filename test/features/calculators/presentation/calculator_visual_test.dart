import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/form_demo.dart';
import 'package:management_toolbox/features/calculators/presentation/widgets/calculator_formula.dart';

import 'fixtures.dart';

// Opt-in rendering evidence, not golden tests or screenshots of native builds.
void main() {
  const capture = bool.fromEnvironment('CAPTURE_CALCULATOR_VISUALS');
  var fontsLoaded = false;
  for (final dark in [false, true]) {
    testWidgets(
      'capture calculator ${dark ? 'dark-mobile' : 'light-desktop'}',
      (tester) async {
        tester.view.physicalSize = dark
            ? const Size(390, 844)
            : const Size(900, 1300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (!fontsLoaded) {
          await tester.runAsync(() async {
            final manifest = (jsonDecode(
              await rootBundle.loadString('FontManifest.json'),
            ) as List<Object?>).cast<Map<String, Object?>>();
            for (final family in manifest) {
              final fonts = (family['fonts']! as List<Object?>)
                  .cast<Map<String, Object?>>();
              // One regular/primary face per family for test capture. Real app builds
              // use all weights/styles registered in the font manifest.
              final loader = FontLoader(family['family']! as String)
                ..addFont(rootBundle.load(fonts.first['asset']! as String));
              await loader.load();
            }
          });
          fontsLoaded = true;
        }
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: host(FormDemo.runner, dark: dark),
          ),
        );
        await tester.pumpAndSettle();
        final name = dark ? 'dark-mobile' : 'light-desktop';
        Future<void> save(String part) async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('docs/visual/stage06/$name-$part.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        await save('form');
        await Scrollable.ensureVisible(
          tester.element(find.byType(CalculatorFormula)),
          alignment: 0.05,
        );
        await tester.pumpAndSettle();
        await save('details');
        expect(tester.takeException(), isNull);
      },
      skip: !capture,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  }
}
