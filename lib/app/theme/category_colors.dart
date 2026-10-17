import 'package:flutter/material.dart';

import '../../features/calculators/domain/calculator_domain.dart';

/// WCAG sRGB luminance ratio. Colors passed here must be opaque/composited.
double contrastRatio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
}

Color readableColor(Color seed, Color background, {double minimum = 4.5}) {
  if (contrastRatio(seed, background) >= minimum) return seed;
  final target = background.computeLuminance() > .179
      ? Colors.black
      : Colors.white;
  for (var step = 1; step <= 100; step++) {
    final candidate = Color.lerp(seed, target, step / 100)!;
    if (contrastRatio(candidate, background) >= minimum) return candidate;
  }
  return target;
}

final class CategoryColors {
  const CategoryColors({required this.background, required this.foreground});
  final Color background, foreground;
  static Color seed(CalculatorCategoryId id) => switch (id) {
    CalculatorCategoryId.production => const Color(0xFF087F8C),
    CalculatorCategoryId.finance => const Color(0xFF4267B2),
    CalculatorCategoryId.quality => const Color(0xFF65812B),
    CalculatorCategoryId.inventory => const Color(0xFFB2681C),
    CalculatorCategoryId.project => const Color(0xFF7C55A3),
    CalculatorCategoryId.humanResources => const Color(0xFFB24769),
    CalculatorCategoryId.decisionMaking => const Color(0xFF477A70),
    CalculatorCategoryId.engineeringEconomics => const Color(0xFF8D6648),
    CalculatorCategoryId.utilities => const Color(0xFF526375),
  };
  factory CategoryColors.forTheme(ThemeData theme, CalculatorCategoryId id) {
    final base = seed(id);
    final background = Color.alphaBlend(
      base.withValues(alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10),
      theme.colorScheme.surface,
    );
    return CategoryColors(
      background: background,
      foreground: readableColor(base, background),
    );
  }
}
