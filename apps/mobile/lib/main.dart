import 'package:flutter/material.dart';
import 'package:use_cases/use_cases.dart';

import 'app.dart';
import 'data/demo_data.dart';
import 'data/empty_lesson_repository.dart';
import 'data/fail_switch.dart';
import 'data/fake_lesson_repository.dart';
import 'data/fake_professor_repository.dart';

// Za odbranu: true daje prazan ekran. Ekran ne zna koja je implementacija, vidi samo LessonRepository.
bool showEmpty = false;

void main() {
  const clock = SystemClock();
  final now = clock.now();
  final failSwitch = FailSwitch();

  final LessonRepository lessons = showEmpty
      ? const EmptyLessonRepository()
      : FakeLessonRepository(demoLessons(now), failSwitch);

  final professors = FakeProfessorRepository(
    profiles: demoProfessors,
    listings: demoListings,
    slots: demoSlots(now),
    failSwitch: failSwitch,
  );

  runApp(App(lessons: lessons, professors: professors, clock: clock, me: ana, failSwitch: failSwitch));
}
