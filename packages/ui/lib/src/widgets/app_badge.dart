import 'package:flutter/material.dart';

import '../theme/app_extra_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// The five tones of Figma Components › Badge.
enum BadgeTone { neutral, accent, verified, warning, destructive }

/// A pill with a subtle background and colored Caption/xs text.
/// Named `AppBadge` because material.dart already exports a `Badge`.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, required this.tone});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extra = AppExtraColors.of(context);
    final (background, foreground) = switch (tone) {
      BadgeTone.neutral => (extra.muted, scheme.onSurfaceVariant),
      BadgeTone.accent => (scheme.primaryContainer, scheme.onPrimaryContainer),
      BadgeTone.verified => (extra.verifiedSubtle, extra.verifiedForeground),
      BadgeTone.warning => (extra.warningSubtle, extra.warningForeground),
      BadgeTone.destructive => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.px8, vertical: AppSpacing.px4),
        child: Text(label, style: AppTextStyles.captionXs.copyWith(color: foreground)),
      ),
    );
  }
}
