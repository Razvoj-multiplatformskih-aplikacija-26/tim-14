import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Test inače crta na 800×600, a široki raspored sa tabelom i detaljem traži desktop prozor.
void useDesktopSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
