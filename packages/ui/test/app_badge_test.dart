import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'helpers.dart';

void main() {
  // The Figma token pair for each tone; the widget reaches them through the theme.
  const colors = {
    BadgeTone.neutral: (AppColors.muted, AppColors.mutedForeground),
    BadgeTone.accent: (AppColors.accent, AppColors.accentForeground),
    BadgeTone.verified: (AppColors.verifiedSubtle, AppColors.verifiedForeground),
    BadgeTone.warning: (AppColors.warningSubtle, AppColors.warningForeground),
    BadgeTone.destructive: (AppColors.destructiveSubtle, AppColors.destructiveText),
  };

  for (final MapEntry(key: tone, value: (background, foreground)) in colors.entries) {
    testWidgets('${tone.name} uses its subtle background and text color', (tester) async {
      await pumpInApp(tester, AppBadge(label: 'Matematika', tone: tone));

      final box = tester.widget<DecoratedBox>(
        find.descendant(of: find.byType(AppBadge), matching: find.byType(DecoratedBox)),
      );
      expect((box.decoration as BoxDecoration).color, background);
      expect(tester.widget<Text>(find.text('Matematika')).style!.color, foreground);
    });
  }

  testWidgets('text is Caption/xs and the pill is 24 high', (tester) async {
    await pumpInApp(tester, const AppBadge(label: 'Matematika', tone: BadgeTone.neutral));

    final style = tester.widget<Text>(find.text('Matematika')).style!;
    expect(style.fontSize, 12);
    expect(style.fontWeight, FontWeight.w500);
    expect(tester.getSize(find.byType(AppBadge)).height, 24);
  });
}
