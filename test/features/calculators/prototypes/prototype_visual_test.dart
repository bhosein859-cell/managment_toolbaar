import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/features/calculators/presentation/widgets/calculator_formula.dart';

import '../presentation/fixtures.dart';

void main() {
  const capture = bool.fromEnvironment('CAPTURE_PROTOTYPE_VISUALS');
  var fontsLoaded = false;
  final pages = <String, Widget Function()>{
    'oee': () => host(PrototypeCalculators.oeeRunner),
    'npv': () => host(PrototypeCalculators.npvRunner),
    'cp': () => host(PrototypeCalculators.cpRunner),
  };
  for (final entry in pages.entries) {
    testWidgets(
      'capture ${entry.key} form and explanations',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1200);
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
              final loader = FontLoader(family['family']! as String)
                ..addFont(rootBundle.load(fonts.first['asset']! as String));
              await loader.load();
            }
          });
          fontsLoaded = true;
        }
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(key: key, child: entry.value()),
        );
        await tester.pumpAndSettle();
        Future<void> save(String section) async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('docs/visual/stage07/${entry.key}-$section.png');
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
        expect(find.textContaining('نمایش ریاضی ممکن نیست'), findsNothing);
        expect(tester.takeException(), isNull);
      },
      skip: !capture,
      timeout: const Timeout(Duration(seconds: 60)),
    );
  }
}
