import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/data/demo_data.dart';
import 'package:mobile/data/fail_switch.dart';
import 'package:mobile/data/fake_lesson_repository.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  const clock = SystemClock();

  Future<void> openApp(WidgetTester tester) async {
    // Ekran visok kao telefon (400 x 1000), da ceo detalj stane bez skrolovanja.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final failSwitch = FailSwitch();
    final lessons = FakeLessonRepository(demoLessons(clock.now()), failSwitch);
    await tester.pumpWidget(App(lessons: lessons, clock: clock, me: ana, failSwitch: failSwitch));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('a lesson in ten hours cannot be cancelled', (tester) async {
    await openApp(tester);

    // Prvi predstojeći čas je onaj za deset sati, kod Ane Kovačević.
    await tester.tap(find.text('Ana Kovačević').first);
    await tester.pumpAndSettle();

    expect(find.text('Detalj časa'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Otkaži čas'));
    expect(button.onPressed, isNull);
    expect(find.text('Čas može da se otkaže najkasnije 24 sata pre početka.'), findsOneWidget);
  });

  testWidgets('a lesson in two days is cancelled after confirming the dialog', (tester) async {
    await openApp(tester);

    // Drugi predstojeći čas je onaj za dva dana, kod Milice Jovanović.
    await tester.tap(find.text('Milica Jovanović').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Otkaži čas'));
    await tester.pumpAndSettle();
    expect(find.text('Otkazati čas?'), findsOneWidget);

    await tester.tap(find.text('Da, otkaži'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Otkazano'), findsOneWidget);
    expect(find.text('Čas je otkazan'), findsOneWidget);
    expect(find.text('Otkaži čas'), findsNothing);
  });

  testWidgets('choosing "Odustani" in the dialog changes nothing', (tester) async {
    await openApp(tester);

    await tester.tap(find.text('Milica Jovanović').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Otkaži čas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odustani'));
    await tester.pumpAndSettle();

    expect(find.text('Potvrđeno'), findsOneWidget);
    expect(find.text('Otkaži čas'), findsOneWidget);
  });
}
