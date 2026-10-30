import 'package:flutter/painting.dart';

/// Semantic colors from Figma Foundations › Color › Semantic, in frame order.
/// The trailing comment is the primitive each token points to.
abstract final class AppColors {
  // Površine
  static const Color background = Color(0xFFFAF8F5); // neutral/50
  static const Color foreground = Color(0xFF241F1A); // neutral/900
  static const Color card = Color(0xFFFFFFFF); // neutral/0
  static const Color cardForeground = Color(0xFF241F1A); // neutral/900
  static const Color muted = Color(0xFFF4F1EC); // neutral/100
  static const Color mutedForeground = Color(0xFF6B6255); // neutral/600

  // Linije
  static const Color border = Color(0xFFE8E3DB); // neutral/200
  static const Color input = Color(0xFFD5CEC3); // neutral/300
  static const Color ring = Color(0xFFC85F33); // clay/500

  // Primary
  static const Color primary = Color(0xFFB4522A); // clay/600
  static const Color primaryHover = Color(0xFF94411F); // clay/700
  static const Color primaryForeground = Color(0xFFFFFFFF); // neutral/0
  static const Color primaryText = Color(0xFF94411F); // clay/700

  // Secondary / Accent
  static const Color secondary = Color(0xFFF4F1EC); // neutral/100
  static const Color secondaryHover = Color(0xFFE8E3DB); // neutral/200
  static const Color secondaryForeground = Color(0xFF38332C); // neutral/800
  static const Color accent = Color(0xFFFAE9E0); // clay/50
  static const Color accentForeground = Color(0xFF94411F); // clay/700

  // Feedback
  static const Color destructive = Color(0xFFB42318); // red/600
  static const Color destructiveSubtle = Color(0xFFFEE4E2); // red/50
  static const Color destructiveForeground = Color(0xFFFFFFFF); // neutral/0
  static const Color destructiveText = Color(0xFF912018); // red/700
  static const Color success = Color(0xFF2F7D57); // pine/500
  static const Color successSubtle = Color(0xFFD5E8DE); // pine/50
  static const Color successForeground = Color(0xFF1C4D34); // pine/700
  static const Color warning = Color(0xFFB87A0E); // amber/500
  static const Color warningSubtle = Color(0xFFF8E4BE); // amber/50
  static const Color warningForeground = Color(0xFF97620A); // amber/600

  // Proizvod
  static const Color verified = Color(0xFF256545); // pine/600
  static const Color verifiedSubtle = Color(0xFFD5E8DE); // pine/50
  static const Color verifiedForeground = Color(0xFF1C4D34); // pine/700
  static const Color price = Color(0xFF241F1A); // neutral/900
}
