import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

// Deo detalja sa naslovom velikim slovima iznad, kao „TOK“ ili „PRILOZI“.
class DetailSection extends StatelessWidget {
  const DetailSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.px12,
      children: [
        Text(title, style: AppTextStyles.captionXs.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        child,
      ],
    );
  }
}
