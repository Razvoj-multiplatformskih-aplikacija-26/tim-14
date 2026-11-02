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

  Future<FailSwitch> openProfessorsTab(WidgetTester tester) async {
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
    await tester.pump();
    return failSwitch;
  }

  testWidgets('shows a spinner, then the professors with badge, city and price', (tester) async {
    await openProfessorsTab(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Milica Jovanović'), findsOneWidget);
    expect(find.text('Beograd'), findsOneWidget);
    expect(find.text('od 2.000 din'), findsOneWidget);
    // Milica, Ana Kovačević i Jelena su verifikovane.
    expect(find.text('Diploma potvrđena'), findsNWidgets(3));
  });

  testWidgets('simulated error shows "Pokušaj ponovo", and retry loads the professors', (tester) async {
    final failSwitch = await openProfessorsTab(tester);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    failSwitch.failNext = true;
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simuliraj grešku'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Milica Jovanović'), findsOneWidget);
  });
}
