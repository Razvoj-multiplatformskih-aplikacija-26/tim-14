import 'package:flutter/material.dart';
import 'package:use_cases/use_cases.dart';

import 'app.dart';
import 'data/demo_data.dart';
import 'data/fail_switch.dart';
import 'data/fake_lesson_repository.dart';

void main() {
  const clock = SystemClock();
  final failSwitch = FailSwitch();

  final lessons = FakeLessonRepository(demoLessons(clock.now()), failSwitch);
  // Za odbranu: zameni red iznad ovim i vidi se prazan ekran.
  // const lessons = EmptyLessonRepository();

  runApp(App(lessons: lessons, clock: clock, me: ana, failSwitch: failSwitch));
}
