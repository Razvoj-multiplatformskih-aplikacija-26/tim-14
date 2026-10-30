import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

/// Widgets read AppExtraColors from the theme and throw without it, so every widget test goes through here.
Future<void> pumpInApp(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: buildAppTheme(),
    home: Center(child: child),
  ),
);
