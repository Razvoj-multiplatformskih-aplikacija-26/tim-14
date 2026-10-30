import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Figma Components › Button: Variant (Primary, Secondary, Ghost, Destructive) × Size (sm, md, lg).
/// The theme already makes FilledButton Primary, OutlinedButton Secondary and TextButton Ghost, all at md.
/// Each style sets only its own fields and the theme fills in the rest, so pass one as `style:` or merge two:
/// `FilledButton(style: AppButtonStyles.destructive.merge(AppButtonStyles.lg), …)`.
abstract final class AppButtonStyles {
  // Size: height, padding, corner radius and label.
  static final ButtonStyle sm = _size(32, AppSpacing.px12, AppSpacing.px6, AppRadius.md, AppTextStyles.bodySmMedium);
  static final ButtonStyle md = _size(40, AppSpacing.px16, AppSpacing.px8, AppRadius.md, AppTextStyles.bodyBaseMedium);
  // Figma pads lg 12px, but 12 + 28 + 12 is 52; its fixed 48px height wins, so the padding here is 10.
  static final ButtonStyle lg = _size(48, AppSpacing.px20, 10, AppRadius.lg, AppTextStyles.bodyLg);

  // Variant: colors. Figma keeps hover in the *-hover tokens, so hover and press swap the fill.
  static final ButtonStyle primary = _variant(
    fill: AppColors.primary,
    hover: AppColors.primaryHover,
    label: AppColors.primaryForeground,
  );
  static final ButtonStyle secondary = _variant(
    fill: AppColors.secondary,
    hover: AppColors.secondaryHover,
    label: AppColors.secondaryForeground,
    border: AppColors.border,
  );
  // No hover token: accent is the shadcn ghost hover, and its foreground is the same clay/700 as the label.
  static final ButtonStyle ghost = _variant(
    fill: Colors.transparent,
    hover: AppColors.accent,
    label: AppColors.primaryText,
  );
  // No hover token: red/700 is one step darker, the way primaryHover is for clay.
  static final ButtonStyle destructive = _variant(
    fill: AppColors.destructive,
    hover: AppColors.destructiveText,
    label: AppColors.destructiveForeground,
  );

  static const double _disabledOpacity = 0.45;

  static ButtonStyle _size(double height, double padH, double padV, double radius, TextStyle label) {
    return ButtonStyle(
      // Width 0 so the button hugs its label like in Figma; Material's minimum is 64.
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: padH, vertical: padV)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius)))),
      textStyle: WidgetStatePropertyAll(label),
      // Desktop defaults to compact density, which takes 8px off the height and the vertical padding.
      visualDensity: VisualDensity.standard,
    );
  }

  static ButtonStyle _variant({required Color fill, required Color hover, required Color label, Color? border}) {
    // Figma fades the whole disabled button to 45%. Material colors each part separately, so the fill and border get
    // 45% alpha and the label gets the color it ends up as on the page: 45% white over the faded fill would turn pink.
    final WidgetStateProperty<Color> labelColor = WidgetStateProperty.fromMap({
      WidgetState.disabled: Color.alphaBlend(label.withValues(alpha: _disabledOpacity), AppColors.background),
      WidgetState.any: label,
    });
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.fromMap({
        WidgetState.disabled: fill.withValues(alpha: _disabledOpacity),
        WidgetState.hovered | WidgetState.pressed: hover,
        WidgetState.any: fill,
      }),
      foregroundColor: labelColor,
      // Material colors outlined and text button icons primary unless told otherwise.
      iconColor: labelColor,
      // No ripple or tint on top of the fill; the hover fill is the whole state change.
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      // Material's FilledButton lifts on hover.
      elevation: const WidgetStatePropertyAll(0),
      // Keyboard focus used to show through the overlay, so it draws a ring instead.
      side: WidgetStateProperty.fromMap({
        WidgetState.focused: const BorderSide(color: AppColors.ring, width: 2),
        WidgetState.disabled: border == null ? null : BorderSide(color: border.withValues(alpha: _disabledOpacity)),
        WidgetState.any: border == null ? null : BorderSide(color: border),
      }),
    );
  }
}
