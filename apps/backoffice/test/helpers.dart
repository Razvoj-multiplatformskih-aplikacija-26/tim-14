import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Test inače crta na 800×600, a široki raspored sa tabelom i detaljem traži desktop prozor.
void useDesktopSize(WidgetTester tester) => _useSize(tester, const Size(1440, 900));

// Uzak prozor: sidebar je u fioki, a strana dobije oko 736 px, pa umesto tabele crta listu.
void useNarrowSize(WidgetTester tester) => _useSize(tester, const Size(800, 900));

void _useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
