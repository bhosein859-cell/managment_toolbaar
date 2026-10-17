import 'package:flutter/material.dart';

import '../../core/widgets/interaction_support.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF087F8C),
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      colorScheme: colors,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      focusColor: colors.primary.withValues(alpha: .20),
      hoverColor: colors.primary.withValues(alpha: .08),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: colors.primary, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: colors.onPrimary, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? colors.primary
                  : colors.outline,
              width: states.contains(WidgetState.focused) ? 2 : 1,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? BorderSide(color: colors.primary, width: 2)
                : BorderSide.none,
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ToolboxTransitions(),
          TargetPlatform.windows: ToolboxTransitions(),
          TargetPlatform.linux: ToolboxTransitions(),
        },
      ),
    );
  }
}
