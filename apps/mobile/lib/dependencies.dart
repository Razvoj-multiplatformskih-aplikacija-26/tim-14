import 'package:api_client/api_client.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/demo_data.dart';
import 'data/fail_switch.dart';
import 'data/fake_lesson_repository.dart';
import 'data/fake_professor_repository.dart';
import 'data/fake_session_repository.dart';

// Sve što aplikacija dobija spolja, na jednom mestu. Ekrani i Bloc-ovi vide samo portove iz use_cases,
// pa ne znaju da li podaci dolaze sa servera ili iz lažnih repozitorijuma.
final class AppDependencies {
  AppDependencies({
    required this.clock,
    required this.lessons,
    required this.professors,
    required SessionRepository sessions,
    this.failSwitch,
  }) : logIn = LogIn(sessions),
       restoreSession = RestoreSession(sessions),
       logOut = LogOut(sessions),
       sessionExpirations = sessions.expirations;

  // Prava aplikacija: svi repozitorijumi idu preko istog ApiClient-a, a token je u bezbednom skladištu.
  factory AppDependencies.server({
    required Uri baseUri,
    required TokenStore tokens,
    Clock clock = const SystemClock(),
  }) {
    final api = ApiClient(baseUri: baseUri, tokens: tokens);
    return AppDependencies(
      clock: clock,
      lessons: HttpLessonRepository(api),
      professors: HttpProfessorRepository(api),
      sessions: HttpSessionRepository(api),
    );
  }

  // Demo podaci bez servera. Prijava radi sa istim nalozima kao na serveru, a „Simuliraj grešku“ postoji samo ovde.
  factory AppDependencies.fake({Clock clock = const SystemClock(), User? signedIn}) {
    final now = clock.now();
    final failSwitch = FailSwitch();
    return AppDependencies(
      clock: clock,
      lessons: FakeLessonRepository(demoLessons(now), failSwitch),
      professors: FakeProfessorRepository(
        profiles: demoProfessors,
        listings: demoListings,
        slots: demoSlots(now),
        failSwitch: failSwitch,
      ),
      sessions: FakeSessionRepository(signedIn: signedIn),
      failSwitch: failSwitch,
    );
  }

  final Clock clock;
  final LessonRepository lessons;
  final ProfessorRepository professors;
  final LogIn logIn;
  final RestoreSession restoreSession;
  final LogOut logOut;
  final Stream<void> sessionExpirations;

  // null nad serverom: grešku tada pravi pravi server (npr. docker compose stop server).
  final FailSwitch? failSwitch;
}
