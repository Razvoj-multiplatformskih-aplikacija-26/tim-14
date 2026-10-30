import 'package:flutter/painting.dart';

/// Text styles from Figma Foundations › Typography › Ramp, in frame order.
/// `height` is written as line height / font size, so `44 / 36` is Figma's "36/44".
/// Every style has letter spacing 0, which is Flutter's default.
/// Styles carry no color; Figma text styles don't either.
abstract final class AppTextStyles {
  static const String _family = 'Figtree';
  static const String _package = 'ui';

  // Figma centers the line height around the text; Flutter's default leading would shift it vertically.
  static const TextLeadingDistribution _leading = TextLeadingDistribution.even;

  // Display/4xl
  static const TextStyle display4xl = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 44 / 36,
    leadingDistribution: _leading,
  );

  // Heading/3xl
  static const TextStyle heading3xl = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 38 / 30,
    leadingDistribution: _leading,
  );

  // Heading/2xl
  static const TextStyle heading2xl = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    leadingDistribution: _leading,
  );

  // Heading/xl
  static const TextStyle headingXl = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    leadingDistribution: _leading,
  );

  // Heading/lg
  static const TextStyle headingLg = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 28 / 18,
    leadingDistribution: _leading,
  );

  // Body/lg
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    leadingDistribution: _leading,
  );

  // Body/base
  static const TextStyle bodyBase = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    leadingDistribution: _leading,
  );

  // Body/base Medium
  static const TextStyle bodyBaseMedium = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 24 / 16,
    leadingDistribution: _leading,
  );

  // Body/sm
  static const TextStyle bodySm = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    leadingDistribution: _leading,
  );

  // Body/sm Medium
  static const TextStyle bodySmMedium = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    leadingDistribution: _leading,
  );

  // Label/sm
  static const TextStyle labelSm = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    leadingDistribution: _leading,
  );

  // Caption/xs
  static const TextStyle captionXs = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    leadingDistribution: _leading,
  );

  // Price/2xl
  static const TextStyle price2xl = TextStyle(
    fontFamily: _family,
    package: _package,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 32 / 24,
    leadingDistribution: _leading,
  );
}
