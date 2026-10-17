import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/app.dart';
import 'package:management_toolbox/app/catalog/prototype_calculators.dart';
import 'package:management_toolbox/app/state/tool_session_scope.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';
import 'package:management_toolbox/features/history/data/drift_tool_repository.dart';

void main() {
  const capture = bool.fromEnvironment('CAPTURE_HOME_VISUALS');
  testWidgets(
    'capture home search and engineering economics with actual session data',
    (tester) async {
      tester.view.physicalSize = const Size(1100, 1500);
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
      await tester.tap(find.text('ورود به برنامه'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byKey(const Key('home-search')));
      final session = ToolSessionScope.of(context);
      await session.toggleFavorite('npv');
      final input = PrototypeCalculators.oee.examples.single.inputs;
      final output =
          PrototypeCalculators.oeeRunner.run(input) as CalculationSuccess;
      await session.record('oee', input, output.result);
      await tester.pumpAndSettle();
      Future<void> save(String name) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('docs/visual/stage08/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await save('home-light-desktop');
      tester.view.physicalSize = const Size(390, 844);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      await save('home-dark-mobile');
      final search = find.byKey(const Key('home-search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'nvp');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await save('fuzzy-search-mobile');
      await tester.tap(find.byTooltip('پاک کردن جستجو'));
      await tester.pumpAndSettle();
      final category = find.byKey(const Key('category-engineeringEconomics'));
      await tester.ensureVisible(category);
      await tester.tap(category);
      await tester.pumpAndSettle();
      await save('economics-category-mobile');
      expect(tester.takeException(), isNull);
    },
    skip: !capture,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
