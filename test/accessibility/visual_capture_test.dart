import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  const capture = bool.fromEnvironment('CAPTURE_STAGE18_VISUALS');
  const targetDevice = String.fromEnvironment(
    'STAGE18_CAPTURE_DEVICE',
    defaultValue: 'phone',
  );
  const targetDark = bool.fromEnvironment('STAGE18_CAPTURE_DARK');
  testWidgets(
    'capture six RTL pages in both themes and phone/desktop DPI with bundled fonts',
    (tester) async {
      await tester.runAsync(() async {
        final manifest = (jsonDecode(
          await rootBundle.loadString('FontManifest.json'),
        ) as List).cast<Map<String, dynamic>>();
        for (final family in manifest) {
          final loader = FontLoader(family['family'] as String);
          for (final font
              in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
            loader.addFont(rootBundle.load(font['asset'] as String));
          }
          await loader.load();
        }
      });
      final fixture = UiFixture();
      await tester.runAsync(fixture.initialize);
      addTearDown(() => tester.runAsync(fixture.close));
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final manifest = <Map<String, Object>>[];
      for (final device in [
        ('phone', const Size(390, 844), 3.0),
        ('desktop', const Size(1280, 900), 1.5),
      ]) {
        if (device.$1 != targetDevice) continue;
        for (final dark in [targetDark]) {
          for (final screen in screens) {
            tester.view.physicalSize = device.$2 * device.$3;
            tester.view.devicePixelRatio = device.$3;
            final key = GlobalKey();
            await tester.pumpWidget(
              fixture.host(
                screen,
                dark: dark,
                platform: device.$1 == 'desktop'
                    ? TargetPlatform.windows
                    : TargetPlatform.android,
                capture: (child) => RepaintBoundary(key: key, child: child),
              ),
            );
            await tester.pumpAndSettle();
            final name =
                '$screen-${dark ? 'dark' : 'light'}-${device.$1}-dpr${device.$3}.png';
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File('docs/visual/stage18/$name');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              manifest.add({
                'file': name,
                'screen': screen,
                'theme': dark ? 'dark' : 'light',
                'logicalWidth': device.$2.width,
                'logicalHeight': device.$2.height,
                'simulatedDpr': device.$3,
                'pixelWidth': image.width,
                'pixelHeight': image.height,
                'textScale': 1,
                'capturePixelRatio': 1,
                'themePlatform': device.$1 == 'desktop' ? 'windows' : 'android',
                'nativePlatformScreenshot': false,
              });
              image.dispose();
            });
            expect(tester.takeException(), isNull);
          }
        }
      }
      await tester.runAsync(
        () =>
            File(
              'docs/visual/stage18/capture-manifest-$targetDevice-${targetDark ? 'dark' : 'light'}.json',
            ).writeAsString(
              '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
            ),
      );
    },
    skip: !capture,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
