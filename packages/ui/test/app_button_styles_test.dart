import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

void main() {
  // Desktop gets compact density, picked when the theme is built, so each test builds it after the variant sets the
  // platform.
  final platforms = TargetPlatformVariant({TargetPlatform.android, TargetPlatform.windows});

  // The Material inside is the visible button; on phones the button's own box is padded to a 48px tap target.
  Future<Material> pumpButton(WidgetTester tester, Widget button) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Center(child: button),
      ),
    );
    return tester.widget<Material>(find.descendant(of: find.byWidget(button), matching: find.byType(Material)));
  }

  Size sizeOf(WidgetTester tester, Material material) => tester.getSize(find.byWidget(material));

  testWidgets('the themed buttons are md, 40 high, in their variant colors', (tester) async {
    final buttons = {
      FilledButton(onPressed: () {}, child: const Text('Pošalji')): AppColors.primary,
      OutlinedButton(onPressed: () {}, child: const Text('Pošalji')): AppColors.secondary,
      TextButton(onPressed: () {}, child: const Text('Pošalji')): Colors.transparent,
    };
    for (final MapEntry(key: button, value: fill) in buttons.entries) {
      final material = await pumpButton(tester, button);
      expect(sizeOf(tester, material).height, 40);
      expect(material.color, fill);
    }
  }, variant: platforms);

  testWidgets('sm and lg are 32 and 48 high', (tester) async {
    final sm = await pumpButton(
      tester,
      FilledButton(style: AppButtonStyles.sm, onPressed: () {}, child: const Text('a')),
    );
    expect(sizeOf(tester, sm).height, 32);
    final lg = await pumpButton(
      tester,
      FilledButton(style: AppButtonStyles.lg, onPressed: () {}, child: const Text('a')),
    );
    expect(sizeOf(tester, lg).height, 48);
  }, variant: platforms);

  testWidgets('destructive merges with a size', (tester) async {
    final style = AppButtonStyles.destructive.merge(AppButtonStyles.lg);
    final material = await pumpButton(
      tester,
      FilledButton(style: style, onPressed: () {}, child: const Text('Obriši')),
    );
    expect(material.color, AppColors.destructive);
    expect(sizeOf(tester, material).height, 48);
  });

  test('primary swaps its fill on hover and press, and fades when disabled', () {
    final fill = AppButtonStyles.primary.backgroundColor!;
    expect(fill.resolve({}), AppColors.primary);
    expect(fill.resolve({WidgetState.hovered}), AppColors.primaryHover);
    expect(fill.resolve({WidgetState.pressed}), AppColors.primaryHover);
    expect(fill.resolve({WidgetState.disabled}), AppColors.primary.withValues(alpha: 0.45));
  });

  test('a disabled white label stays opaque and near white', () {
    final label = AppButtonStyles.primary.foregroundColor!.resolve({WidgetState.disabled})!;
    expect(label.a, 1);
    expect(label.computeLuminance(), greaterThan(0.9));
  });

  test('secondary has a border, and keyboard focus draws the ring', () {
    final side = AppButtonStyles.secondary.side!;
    expect(side.resolve({}), const BorderSide(color: AppColors.border));
    expect(side.resolve({WidgetState.focused}), const BorderSide(color: AppColors.ring, width: 2));
    expect(AppButtonStyles.primary.side!.resolve({}), isNull);
  });

  test('ghost hovers to accent', () {
    expect(AppButtonStyles.ghost.backgroundColor!.resolve({WidgetState.hovered}), AppColors.accent);
  });
}
