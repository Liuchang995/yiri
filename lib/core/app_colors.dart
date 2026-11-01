import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.secondaryText,
    required this.divider,
    required this.primary,
    required this.onPrimary,
    required this.danger,
    required this.field,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color secondaryText;
  final Color divider;
  final Color primary;
  final Color onPrimary;
  final Color danger;
  final Color field;

  static const light = AppColors(
    background: Color(0xFFFAFAF8),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1C1C1E),
    secondaryText: Color(0xFF8A8A8E),
    divider: Color(0xFFEDEDEA),
    primary: Color(0xFF3A5A40),
    onPrimary: Color(0xFFFFFFFF),
    danger: Color(0xFFB3403A),
    field: Color(0xFFF1F1ED),
  );

  static const dark = AppColors(
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    text: Color(0xFFECECEC),
    secondaryText: Color(0xFF9A9A9A),
    divider: Color(0xFF1E1E1E),
    primary: Color(0xFF6E9A78),
    onPrimary: Color(0xFF121212),
    danger: Color(0xFFE08A83),
    field: Color(0xFF121212),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? AppColors.light;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? secondaryText,
    Color? divider,
    Color? primary,
    Color? onPrimary,
    Color? danger,
    Color? field,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      secondaryText: secondaryText ?? this.secondaryText,
      divider: divider ?? this.divider,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      danger: danger ?? this.danger,
      field: field ?? this.field,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      field: Color.lerp(field, other.field, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => AppColors.of(this);
}
