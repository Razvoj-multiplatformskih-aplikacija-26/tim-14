import 'package:flutter/material.dart';
import 'package:use_cases/use_cases.dart';

import 'app.dart';
import 'data/demo_data.dart';
import 'data/fail_switch.dart';
import 'data/fake_lesson_repository.dart';
import 'data/fake_professor_repository.dart';

void main() {
  const clock = SystemClock();
  final now = clock.now();
  final failSwitch = FailSwitch();

  final lessons = FakeLessonRepository(demoLessons(now), failSwitch);
  // Za odbranu: zameni red iznad ovim i vidi se prazan ekran.
  // const lessons = EmptyLessonRepository();

  final professors = FakeProfessorRepository(
    profiles: demoProfessors,
    listings: demoListings,
    slots: demoSlots(now),
    failSwitch: failSwitch,
  );

  runApp(App(lessons: lessons, professors: professors, clock: clock, me: ana, failSwitch: failSwitch));
}
