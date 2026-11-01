import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// Zajednički izgled za grešku i prazan ekran, u časovima i u verifikaciji.
class CenteredMessage extends StatelessWidget {
  const CenteredMessage({super.key, required this.icon, required this.title, required this.text, this.action});

  final IconData icon;
  final String title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.px12,
        children: [
          Icon(icon, size: 40, color: colors.onSurfaceVariant),
          Text(title, style: AppTextStyles.headingLg.copyWith(color: colors.onSurface)),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: colors.onSurfaceVariant),
          ),
          ?action,
        ],
      ),
    );
  }
}
