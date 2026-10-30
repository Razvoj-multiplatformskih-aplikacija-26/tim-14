import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_text_styles.dart';
import 'app_extra_colors.dart';

/// The light theme both apps pass to `MaterialApp(theme: buildAppTheme())`.
/// Covers colors, text, page background, cards, dividers and focus; component themes come separately.
ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: _colorScheme,
    textTheme: _textTheme,
    // Material defaults this to colorScheme.surface, which is the white card color here.
    scaffoldBackgroundColor: AppColors.background,
    // Flat on purpose: Material's elevation can't draw Shadow/sm, so cards that need it add AppShadows.sm.
    cardTheme: const CardThemeData(
      color: AppColors.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    // Divider reads dividerTheme; ExpansionTile and other older widgets read dividerColor, which defaults to outline.
    dividerTheme: const DividerThemeData(color: AppColors.border),
    dividerColor: AppColors.border,
    // The keyboard-focus highlight on InkWell and ListTile. Material's default is black at 12%; this keeps the
    // strength in the ring color. M3 buttons draw their own focus overlay and ignore it.
    focusColor: AppColors.ring.withValues(alpha: 0.12),
    extensions: const [AppExtraColors.light],
  );
}

/// Every slot is a Figma token. Slots left out fall back as follows:
/// secondaryContainer to secondary and every surfaceContainer* to surface.
const ColorScheme _colorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: AppColors.primaryForeground,
  primaryContainer: AppColors.accent,
  onPrimaryContainer: AppColors.accentForeground,
  // M3 reads secondaryContainer for tonal buttons, selected chips and the nav indicator: the Figma Secondary look.
  secondary: AppColors.secondary,
  onSecondary: AppColors.secondaryForeground,
  error: AppColors.destructive,
  onError: AppColors.destructiveForeground,
  errorContainer: AppColors.destructiveSubtle,
  onErrorContainer: AppColors.destructiveText,
  // Surface is the card color, so dialogs, menus and sheets match cards; the page itself is scaffoldBackgroundColor.
  surface: AppColors.card,
  onSurface: AppColors.foreground,
  onSurfaceVariant: AppColors.mutedForeground,
  // Both fall back to onSurface when left out, which would draw near-black borders.
  outline: AppColors.input,
  outlineVariant: AppColors.border,
  shadow: AppColors.foreground, // tinted like AppShadows
);

/// Each Figma heading fills one slot; body and label sizes line up with Material's own ramp.
/// Body/lg and Price/2xl have no slot and are used through [AppTextStyles] directly.
const TextTheme _textTheme = TextTheme(
  // The design has one display size.
  displayLarge: AppTextStyles.display4xl,
  displayMedium: AppTextStyles.display4xl,
  displaySmall: AppTextStyles.display4xl,
  headlineLarge: AppTextStyles.heading3xl,
  headlineMedium: AppTextStyles.heading2xl,
  headlineSmall: AppTextStyles.headingXl, // dialog titles
  titleLarge: AppTextStyles.headingLg, // app bar titles
  titleMedium: AppTextStyles.bodyBaseMedium,
  titleSmall: AppTextStyles.bodySmMedium,
  bodyLarge: AppTextStyles.bodyBase, // text fields, list tile titles
  bodyMedium: AppTextStyles.bodySm, // default for Text
  bodySmall: AppTextStyles.captionXs,
  labelLarge: AppTextStyles.labelSm, // buttons
  labelMedium: AppTextStyles.captionXs,
  labelSmall: AppTextStyles.captionXs,
);
