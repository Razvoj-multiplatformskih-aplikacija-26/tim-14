import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// The design tokens that have no [ColorScheme] slot, so widgets can still read them from the theme.
/// Read with `AppExtraColors.of(context).verified`.
@immutable
class AppExtraColors extends ThemeExtension<AppExtraColors> {
  const AppExtraColors({
    required this.verified,
    required this.verifiedSubtle,
    required this.verifiedForeground,
    required this.warning,
    required this.warningSubtle,
    required this.warningForeground,
    required this.muted,
    required this.border,
  });

  static const AppExtraColors light = AppExtraColors(
    verified: AppColors.verified,
    verifiedSubtle: AppColors.verifiedSubtle,
    verifiedForeground: AppColors.verifiedForeground,
    warning: AppColors.warning,
    warningSubtle: AppColors.warningSubtle,
    warningForeground: AppColors.warningForeground,
    muted: AppColors.muted,
    border: AppColors.border,
  );

  /// Throws if the theme wasn't built with [AppExtraColors], e.g. a `MaterialApp` not using `buildAppTheme()`.
  static AppExtraColors of(BuildContext context) => Theme.of(context).extension<AppExtraColors>()!;

  final Color verified;
  final Color verifiedSubtle;
  final Color verifiedForeground;
  final Color warning;
  final Color warningSubtle;
  final Color warningForeground;
  final Color muted;
  final Color border;

  @override
  AppExtraColors copyWith({
    Color? verified,
    Color? verifiedSubtle,
    Color? verifiedForeground,
    Color? warning,
    Color? warningSubtle,
    Color? warningForeground,
    Color? muted,
    Color? border,
  }) {
    return AppExtraColors(
      verified: verified ?? this.verified,
      verifiedSubtle: verifiedSubtle ?? this.verifiedSubtle,
      verifiedForeground: verifiedForeground ?? this.verifiedForeground,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      warningForeground: warningForeground ?? this.warningForeground,
      muted: muted ?? this.muted,
      border: border ?? this.border,
    );
  }

  // Called by AnimatedTheme when the theme changes, so these colors fade along with the ColorScheme.
  @override
  AppExtraColors lerp(AppExtraColors? other, double t) {
    if (other == null) return this;
    return AppExtraColors(
      verified: Color.lerp(verified, other.verified, t)!,
      verifiedSubtle: Color.lerp(verifiedSubtle, other.verifiedSubtle, t)!,
      verifiedForeground: Color.lerp(verifiedForeground, other.verifiedForeground, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      warningForeground: Color.lerp(warningForeground, other.warningForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
