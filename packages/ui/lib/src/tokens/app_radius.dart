/// Corner radii from Figma Foundations › Spacing & Radius › Radius.
/// Wrap in `Radius.circular` or `BorderRadius.circular` at the call site.
abstract final class AppRadius {
  static const double sm = 6; // radius/sm
  static const double md = 10; // radius/md, the --radius default
  static const double lg = 14; // radius/lg
  static const double xl = 20; // radius/xl
  static const double xxl = 28; // radius/2xl
  // Flutter shrinks radii that don't fit the box, so this gives a pill shape.
  static const double full = 9999; // radius/full
}
