import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/data/demo_data.dart';
import 'package:mobile/data/fail_switch.dart';
import 'package:mobile/data/fake_lesson_repository.dart';
import 'package:use_cases/use_cases.dart';

import 'helpers.dart';

void main() {
  const clock = SystemClock();

  // Otvori tab Profesori i klikne na Milicu.
  Future<FailSwitch> openMilica(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final failSwitch = FailSwitch();
    await tester.pumpWidget(
      App(
        lessons: FakeLessonRepository(demoLessons(clock.now()), failSwitch),
        professors: demoProfessorRepository(failSwitch),
        clock: clock,
        me: ana,
        failSwitch: failSwitch,
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Profesori').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Milica Jovanović'));
    await tester.pump();
    return failSwitch;
  }

  testWidgets('tapping a professor opens the profile with listings and free slots', (tester) async {
    await openMilica(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Profil profesora'), findsOneWidget);
    expect(find.text('Diploma potvrđena'), findsOneWidget);
    expect(find.text('Matematika · Srednja škola · Beograd'), findsOneWidget);
    expect(find.text('Matematika · Fakultet · Beograd'), findsOneWidget);
    expect(find.text('2.000 din / 60 min'), findsOneWidget);
    // Svaki Milicin oglas ima bar po tri slobodna termina.
    expect(find.byType(ActionChip).evaluate().length, greaterThanOrEqualTo(6));
  });

  testWidgets('simulated error shows "Pokušaj ponovo", and retry loads the profile', (tester) async {
    final failSwitch = await openMilica(tester);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    failSwitch.failNext = true;
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simuliraj grešku'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Matematika · Srednja škola · Beograd'), findsOneWidget);
  });
}
