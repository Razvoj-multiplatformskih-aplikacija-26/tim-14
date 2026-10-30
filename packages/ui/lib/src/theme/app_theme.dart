import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';
import 'app_button_styles.dart';
import 'app_extra_colors.dart';

/// The light theme both apps pass to `MaterialApp(theme: buildAppTheme())`.
/// Covers colors, text, page background, cards, dividers and focus, plus the Figma components that map onto
/// Material widgets: buttons, inputs (Input, Textarea, Select), checkbox and switch.
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
    // strength in the ring color. Buttons ignore it and draw a ring border instead, see AppButtonStyles.
    focusColor: AppColors.ring.withValues(alpha: 0.12),
    filledButtonTheme: FilledButtonThemeData(style: AppButtonStyles.primary.merge(AppButtonStyles.md)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtonStyles.secondary.merge(AppButtonStyles.md)),
    textButtonTheme: TextButtonThemeData(style: AppButtonStyles.ghost.merge(AppButtonStyles.md)),
    inputDecorationTheme: _inputDecorationTheme,
    // DropdownMenu falls back to its own OutlineInputBorder, not to inputDecorationTheme.
    dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: _inputDecorationTheme),
    checkboxTheme: _checkboxTheme,
    switchTheme: _switchTheme,
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
  labelLarge: AppTextStyles.labelSm, // chips, tabs; buttons take theirs from AppButtonStyles
  labelMedium: AppTextStyles.captionXs,
  labelSmall: AppTextStyles.captionXs,
);

// Figma's disabled Input and Checkbox are at 60%.
const double _disabledOpacity = 0.6;

/// Figma Components › Input, also used by Textarea and Select. Fields are 40 high: 8 + 24 (Body/base) + 8.
/// Hint, error and counter text keep Material's defaults, which already map to tokens.
final InputDecorationThemeData _inputDecorationTheme = InputDecorationThemeData(
  // isDense drops Material's 48px minimum height; standard density stops desktop taking another 8px off.
  isDense: true,
  visualDensity: VisualDensity.standard,
  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.px12, vertical: AppSpacing.px8),
  filled: true,
  fillColor: WidgetStateColor.resolveWith(
    (states) => states.contains(WidgetState.disabled) ? AppColors.muted : AppColors.card,
  ),
  // Figma has no hover state; Material would tint filled fields gray.
  hoverColor: Colors.transparent,
  // One border for every state rather than enabledBorder, focusedBorder and so on: a theme enabledBorder would
  // override a field's own `border: InputBorder.none`.
  // resolveWith, not fromMap, here and for the checkbox side: fromMap only acts as a WidgetStateProperty, and
  // DropdownButton reads `isOutline` straight off this border. resolveWith returns a real OutlineInputBorder.
  border: WidgetStateInputBorder.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return _inputBorder(AppColors.border);
    if (states.contains(WidgetState.error)) return _inputBorder(AppColors.destructive, width: 2);
    if (states.contains(WidgetState.focused)) return _inputBorder(AppColors.ring, width: 2);
    return _inputBorder(AppColors.input);
  }),
);

OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
    borderSide: BorderSide(color: color, width: width),
  );
}

/// Figma Components › Checkbox. Material's box is 18px against Figma's 20px, and a theme can't resize it.
final CheckboxThemeData _checkboxTheme = CheckboxThemeData(
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm))),
  fillColor: WidgetStateProperty.fromMap({
    WidgetState.disabled & WidgetState.selected: AppColors.primary.withValues(alpha: _disabledOpacity),
    WidgetState.disabled: AppColors.muted,
    WidgetState.selected: AppColors.primary,
    WidgetState.any: AppColors.card,
  }),
  // The side is drawn in every state, so a checked box clears it; otherwise the gray stroke would sit on the fill.
  side: WidgetStateBorderSide.resolveWith((states) {
    if (states.contains(WidgetState.selected)) return BorderSide.none;
    if (states.contains(WidgetState.disabled)) return const BorderSide(color: AppColors.border, width: 1.5);
    if (states.contains(WidgetState.error)) return const BorderSide(color: AppColors.destructive, width: 1.5);
    return const BorderSide(color: AppColors.input, width: 1.5);
  }),
);

/// Figma Components › Switch. Figma's is 44×24; Material's track is a fixed 52×32, so this matches colors only.
final SwitchThemeData _switchTheme = SwitchThemeData(
  trackColor: WidgetStateProperty.fromMap({
    WidgetState.disabled & WidgetState.selected: AppColors.primary.withValues(alpha: _disabledOpacity),
    WidgetState.disabled: AppColors.input.withValues(alpha: _disabledOpacity),
    WidgetState.selected: AppColors.primary,
    WidgetState.any: AppColors.input,
  }),
  thumbColor: const WidgetStatePropertyAll(AppColors.card),
  trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
  // Material shrinks the off thumb to 16px unless it has an icon. An empty icon keeps it at 24 in both states,
  // like Figma's same-size thumb, and draws nothing.
  thumbIcon: const WidgetStatePropertyAll(Icon(null)),
);
