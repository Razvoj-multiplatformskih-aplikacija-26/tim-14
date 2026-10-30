import 'package:flutter/painting.dart';

/// Shadows from Figma Foundations › Elevation › Shadows, tinted with foreground #241F1A instead of black.
/// Figma writes colors as #RRGGBBAA and Flutter as 0xAARRGGBB: Figma's #241F1A0D is `Color(0x0D241F1A)`.
/// Figma's blur maps directly to `blurRadius`.
abstract final class AppShadows {
  // Shadow/sm
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D241F1A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x14241F1A), offset: Offset(0, 1), blurRadius: 3),
  ];

  // Shadow/md
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0D241F1A), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -1),
    BoxShadow(color: Color(0x14241F1A), offset: Offset(0, 4), blurRadius: 8, spreadRadius: -1),
  ];

  // Shadow/lg
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x0D241F1A), offset: Offset(0, 4), blurRadius: 6, spreadRadius: -2),
    BoxShadow(color: Color(0x1A241F1A), offset: Offset(0, 12), blurRadius: 20, spreadRadius: -4),
  ];
}
