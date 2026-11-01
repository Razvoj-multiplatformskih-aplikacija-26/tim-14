import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/data/demo_data.dart';
import 'package:mobile/data/empty_lesson_repository.dart';
import 'package:mobile/data/fail_switch.dart';
import 'package:mobile/data/fake_lesson_repository.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  const clock = SystemClock();

  testWidgets('shows a spinner, then the lessons grouped by state', (tester) async {
    final failSwitch = FailSwitch();
    final lessons = FakeLessonRepository(demoLessons(clock.now()), failSwitch);

    await tester.pumpWidget(App(lessons: lessons, clock: clock, me: ana, failSwitch: failSwitch));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Predstojeći'), findsOneWidget);
    // Najraniji predstojeći čas je onaj za deset sati, kod Ane Kovačević.
    expect(find.text('Ana Kovačević'), findsOneWidget);
  });

  testWidgets('simulated error shows "Pokušaj ponovo", and retry loads the lessons', (tester) async {
    final failSwitch = FailSwitch()..failNext = true;
    final lessons = FakeLessonRepository(demoLessons(clock.now()), failSwitch);

    await tester.pumpWidget(App(lessons: lessons, clock: clock, me: ana, failSwitch: failSwitch));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Pokušaj ponovo'), findsOneWidget);

    await tester.tap(find.text('Pokušaj ponovo'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Predstojeći'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no lessons', (tester) async {
    await tester.pumpWidget(
      App(lessons: const EmptyLessonRepository(), clock: clock, me: ana, failSwitch: FailSwitch()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Još nemaš nijedan čas.'), findsOneWidget);
  });
}
