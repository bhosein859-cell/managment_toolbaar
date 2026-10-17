import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:management_toolbox/app/theme/app_theme.dart';
import 'package:management_toolbox/app/theme/category_colors.dart';
import 'package:management_toolbox/features/calculators/domain/calculator_domain.dart';

import 'fixtures.dart';

void main() {
  test(
    'all nine categories retain distinct readable foregrounds in both themes',
    () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final palettes = [
          for (final id in CalculatorCategoryId.values)
            CategoryColors.forTheme(theme, id),
        ];
        expect(
          palettes.map((p) => p.foreground.toARGB32()).toSet(),
          hasLength(9),
        );
        for (final p in palettes) {
          expect(
            contrastRatio(theme.colorScheme.primary, p.background),
            greaterThanOrEqualTo(3),
          );
          expect(
            contrastRatio(p.foreground, p.background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(p.foreground, theme.colorScheme.surface),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    },
  );
  test('core text/error/result pairs meet AA normal text and focus indicator exceeds 3:1', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final c = theme.colorScheme;
      for (final pair in [
        (c.onSurface, c.surface),
        (c.onPrimary, c.primary),
        (c.onPrimaryContainer, c.primaryContainer),
        (c.error, c.surface),
        (c.onSurfaceVariant, c.surfaceContainerHighest),
      ]) {
        expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
      expect(contrastRatio(c.primary, c.surface), greaterThanOrEqualTo(3));
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    }
  });
  for (final screen in screens) {
    for (final config in [
      (const Size(320, 568), 1.0, 2.0, false),
      (const Size(390, 844), 3.0, 1.0, true),
      (const Size(800, 600), 1.5, 1.5, true),
      (const Size(1280, 800), 2.0, 2.0, false),
    ]) {
      testWidgets(
        '$screen RTL logical=${config.$1} DPR=${config.$2} text=${config.$3} dark=${config.$4}',
        (tester) async {
          final fixture = UiFixture();
          await tester.runAsync(fixture.initialize);
          addTearDown(() => tester.runAsync(fixture.close));
          tester.view.physicalSize = config.$1 * config.$2;
          tester.view.devicePixelRatio = config.$2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            fixture.host(
              screen,
              dark: config.$4,
              scale: config.$3,
              platform: config.$1.width >= 800
                  ? TargetPlatform.windows
                  : TargetPlatform.android,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            Directionality.of(tester.element(find.byType(Scaffold).first)),
            TextDirection.rtl,
          );
          expect(
            MediaQuery.textScalerOf(tester.element(find.byType(Scaffold).first))
                .scale(16),
            16 * config.$3,
          );
          expect(tester.takeException(), isNull);
          // A live desktop resize must retain the page and remain scrollable.
          tester.view.physicalSize = const Size(360, 360) * config.$2;
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
