part of '../home.dart';

extension _ThemeColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  Color get positive =>
      colors.brightness == Brightness.dark
          ? const Color(0xFF97DFB5)
          : const Color(0xFF11775B);

  Color readable(Color color) {
    final surface = colors.surface.computeLuminance();
    bool passes(Color value) {
      final luminance = value.computeLuminance();
      return (max(luminance, surface) + .05) /
              (min(luminance, surface) + .05) >=
          4.5;
    }

    if (passes(color)) return color;
    final adjusted = Color.lerp(color, colors.onSurface, .65)!;
    return passes(adjusted) ? adjusted : colors.onSurface;
  }
}
