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

  // Desktop gets compact density, picked when the theme is built, so this builds its own after the variant runs.
  testWidgets('text fields and dropdowns are 40 high', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Material(
          child: Column(
            children: [
              const TextField(),
              DropdownButtonFormField<int>(
                items: const [DropdownMenuItem(value: 1, child: Text('Zemun'))],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(TextField)).height, 40);
    expect(tester.getSize(find.byType(DropdownButtonFormField<int>)).height, 40);
  }, variant: TargetPlatformVariant({TargetPlatform.android, TargetPlatform.windows}));

  test('the input border follows the state, error beating focus', () {
    final border = theme.inputDecorationTheme.border! as WidgetStateInputBorder;
    BorderSide sideAt(Set<WidgetState> states) => border.resolve(states).borderSide;
    expect(sideAt({}), const BorderSide(color: AppColors.input));
    expect(sideAt({WidgetState.focused}), const BorderSide(color: AppColors.ring, width: 2));
    expect(sideAt({WidgetState.focused, WidgetState.error}), const BorderSide(color: AppColors.destructive, width: 2));
    expect(sideAt({WidgetState.disabled}), const BorderSide(color: AppColors.border));
  });

  test('DropdownMenu uses the same input theme', () {
    expect(theme.dropdownMenuTheme.inputDecorationTheme, same(theme.inputDecorationTheme));
  });

  test('a checkbox is a bordered white box, filled primary without a border when checked', () {
    final fill = theme.checkboxTheme.fillColor!;
    final side = theme.checkboxTheme.side! as WidgetStateBorderSide;
    expect(fill.resolve({}), AppColors.card);
    expect(side.resolve({}), const BorderSide(color: AppColors.input, width: 1.5));
    expect(fill.resolve({WidgetState.selected}), AppColors.primary);
    expect(side.resolve({WidgetState.selected}), BorderSide.none);
    expect(fill.resolve({WidgetState.disabled}), AppColors.muted);
    expect(side.resolve({WidgetState.disabled}), const BorderSide(color: AppColors.border, width: 1.5));
  });

  test('a switch has an input track off, a primary track on, and no outline', () {
    final s = theme.switchTheme;
    expect(s.trackColor!.resolve({}), AppColors.input);
    expect(s.trackColor!.resolve({WidgetState.selected}), AppColors.primary);
    expect(s.trackOutlineColor!.resolve({}), Colors.transparent);
    expect(s.thumbColor!.resolve({WidgetState.selected}), AppColors.card);
  });
}
