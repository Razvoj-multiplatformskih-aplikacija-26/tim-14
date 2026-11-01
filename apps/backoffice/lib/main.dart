import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:use_cases/use_cases.dart';

import 'app.dart';
import 'data/demo_data.dart';
import 'data/fail_switch.dart';
import 'data/fake_lesson_repository.dart';
import 'data/fake_verification_repository.dart';
import 'router.dart';

// Ovde se svi objekti prave jednom. Ekrani ih dobijaju preko providera u BackofficeApp.
void main() {
  final failSwitch = FailSwitch();
  final now = DateTime.now();
  // Za prazan ekran na odbrani ovo se zameni sa const EmptyLessonRepository().
  final LessonRepository lessons = FakeLessonRepository(demoLessons(now), failSwitch);
  final VerificationRepository verifications = FakeVerificationRepository(demoProfessors(now), failSwitch);
  // Ulogovani korisnik. Do prijave u KT2 bira ga meni u dnu sidebara.
  // Ide kroz konstruktore, ne kroz provider: provider ne bi obavestio ekrane kad se promeni.
  final session = ValueNotifier<User>(milica);

  runApp(
    BackofficeApp(
      failSwitch: failSwitch,
      lessons: lessons,
      verifications: verifications,
      router: createRouter(session),
    ),
  );
}
