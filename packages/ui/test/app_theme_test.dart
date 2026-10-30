import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  final theme = buildAppTheme();

  // Widgets see the theme through Theme.of, which merges Material's text geometry in; buildAppTheme() alone doesn't.
  Future<BuildContext> pumpApp(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  test('colors come from the tokens', () {
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.surface, AppColors.card);
    expect(theme.colorScheme.outlineVariant, AppColors.border);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });

  testWidgets("Material's text geometry doesn't leak into the text theme", (tester) async {
    final t = Theme.of(await pumpApp(tester)).textTheme;
    final styles = [
      t.displayLarge, t.displayMedium, t.displaySmall, //
      t.headlineLarge, t.headlineMedium, t.headlineSmall,
      t.titleLarge, t.titleMedium, t.titleSmall,
      t.bodyLarge, t.bodyMedium, t.bodySmall,
      t.labelLarge, t.labelMedium, t.labelSmall,
    ];
    for (final style in styles) {
      expect(style!.letterSpacing, 0);
      expect(style.fontFamily, 'packages/ui/Figtree');
      expect(style.color, AppColors.foreground);
    }
  });

  testWidgets('AppExtraColors.of reads the extension from the theme', (tester) async {
    expect(AppExtraColors.of(await pumpApp(tester)).verified, AppColors.verified);
  });

  test('lerp returns the endpoints at 0 and 1', () {
    const other = AppExtraColors(
      verified: Colors.black,
      verifiedSubtle: Colors.black,
      verifiedForeground: Colors.black,
      warning: Colors.black,
      warningSubtle: Colors.black,
      warningForeground: Colors.black,
      muted: Colors.black,
      border: Colors.black,
    );
    expect(AppExtraColors.light.lerp(other, 0).verified, AppColors.verified);
    expect(AppExtraColors.light.lerp(other, 1).verified, Colors.black);
  });
}
