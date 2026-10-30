import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'helpers.dart';

void main() {
  final sizes = <(AvatarSize, double, TextStyle)>[
    (AvatarSize.sm, 32, AppTextStyles.captionXs),
    (AvatarSize.md, 48, AppTextStyles.bodySmMedium),
    (AvatarSize.lg, 64, AppTextStyles.headingLg),
    (AvatarSize.xl, 96, AppTextStyles.heading2xl),
  ];

  for (final (size, dimension, textStyle) in sizes) {
    testWidgets('${size.name} is $dimension wide with ${textStyle.fontSize} text', (tester) async {
      await pumpInApp(tester, Avatar(name: 'Marko Đorđević', size: size));

      expect(tester.getSize(find.byType(Avatar)), Size.square(dimension));
      final style = tester.widget<Text>(find.text('MĐ')).style!;
      expect(style.fontSize, textStyle.fontSize);
      expect(style.fontWeight, textStyle.fontWeight);
    });
  }

  final initials = {
    'Marko Đorđević': 'MĐ',
    'Ana Marija Petrović': 'AP',
    '  marko  ': 'M',
    'milica   jovanović': 'MJ',
    '': '',
  };

  for (final MapEntry(key: name, value: expected) in initials.entries) {
    testWidgets('"$name" shows "$expected"', (tester) async {
      await pumpInApp(tester, Avatar(name: name));

      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets('muted circle with a border and muted text', (tester) async {
    await pumpInApp(tester, const Avatar(name: 'Marko Đorđević'));

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(Avatar), matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.muted);
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.border, Border.all(color: AppColors.border));
    expect(tester.widget<Text>(find.text('MĐ')).style!.color, AppColors.mutedForeground);
  });
}
