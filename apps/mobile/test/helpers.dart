import 'package:mobile/app.dart';
import 'package:mobile/data/demo_data.dart';
import 'package:mobile/data/fail_switch.dart';
import 'package:mobile/data/fake_professor_repository.dart';
import 'package:mobile/data/fake_session_repository.dart';
import 'package:mobile/dependencies.dart';
import 'package:use_cases/use_cases.dart';

// Isti demo profesori kao u AppDependencies.fake.
FakeProfessorRepository demoProfessorRepository(FailSwitch failSwitch) => FakeProfessorRepository(
  profiles: demoProfessors,
  listings: demoListings,
  slots: demoSlots(DateTime.now()),
  failSwitch: failSwitch,
);

// Aplikacija nad lažnim repozitorijumima. Ana je podrazumevano već prijavljena, kao posle ponovnog pokretanja.
App testApp({
  required LessonRepository lessons,
  required FailSwitch failSwitch,
  Clock clock = const SystemClock(),
  FakeSessionRepository? sessions,
}) => App(
  dependencies: AppDependencies(
    clock: clock,
    lessons: lessons,
    professors: demoProfessorRepository(failSwitch),
    sessions: sessions ?? FakeSessionRepository(signedIn: ana),
    failSwitch: failSwitch,
  ),
);
