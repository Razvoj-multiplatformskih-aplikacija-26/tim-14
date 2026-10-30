import 'package:flutter/material.dart';

import '../theme/app_extra_colors.dart';
import '../tokens/app_text_styles.dart';

/// The four sizes of Figma Components › Avatar, each with its own text style.
enum AvatarSize {
  sm(32, AppTextStyles.captionXs),
  md(48, AppTextStyles.bodySmMedium),
  lg(64, AppTextStyles.headingLg),
  xl(96, AppTextStyles.heading2xl);

  const AvatarSize(this.dimension, this.textStyle);

  final double dimension;
  final TextStyle textStyle;
}

/// A circle with the person's initials. Figma shows a photo with initials as the fallback; photos come with storage.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = AvatarSize.md});

  final String name;
  final AvatarSize size;

  @override
  Widget build(BuildContext context) {
    final extra = AppExtraColors.of(context);
    return Container(
      width: size.dimension,
      height: size.dimension,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: extra.muted,
        shape: BoxShape.circle,
        border: Border.all(color: extra.border),
      ),
      child: Text(
        _initials(name),
        style: size.textStyle.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// First letter of the first and the last word, so "Ana Marija Petrović" is "AP".
/// `characters` takes a whole letter even when it's written as several code units, e.g. "Č" stored as C + caron.
String _initials(String name) {
  final words = name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return '';
  final first = words.first.characters.first;
  if (words.length == 1) return first.toUpperCase();
  return (first + words.last.characters.first).toUpperCase();
}
