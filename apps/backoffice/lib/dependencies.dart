import 'package:api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:use_cases/use_cases.dart';

import 'data/demo_data.dart';
import 'data/fail_switch.dart';
import 'data/fake_lesson_repository.dart';
import 'data/fake_session_repository.dart';
import 'data/fake_verification_repository.dart';
import 'data/secure_token_store.dart';

// Svi repozitorijumi aplikacije na jednom mestu, kao @Configuration u Springu.
// Ekrani i Blocovi vide samo portove (LessonRepository, …), pa ne znaju da li ispod radi server ili lažni podaci.
final class BackofficeDependencies {
  BackofficeDependencies({required this.lessons, required this.verifications, required this.sessions, this.failSwitch});

  // Pravi rad: sve ide preko jednog ApiClient-a na server.
  factory BackofficeDependencies.server(Uri baseUri) {
    // Na webu sesiju nosi HttpOnly kolačić, pa token ne čuvamo nigde. Na desktopu ide u sistemski sef.
    final api = ApiClient(baseUri: baseUri, tokens: kIsWeb ? MemoryTokenStore() : const SecureTokenStore());
    return BackofficeDependencies(
      lessons: HttpLessonRepository(api),
      verifications: HttpVerificationRepository(api),
      sessions: HttpSessionRepository(api),
    );
  }

  // Demo bez servera i testovi ekrana. Sva tri lažna repozitorijuma dele isti FailSwitch.
  factory BackofficeDependencies.fake(DateTime now, {Duration delay = const Duration(milliseconds: 800)}) {
    final failSwitch = FailSwitch();
    return BackofficeDependencies(
      // Za prazan ekran na odbrani ovo se zameni sa const EmptyLessonRepository().
      lessons: FakeLessonRepository(demoLessons(now), failSwitch, delay: delay),
      verifications: FakeVerificationRepository(demoProfessors(now), failSwitch, delay: delay),
      sessions: FakeSessionRepository(failSwitch, delay: delay ~/ 2),
      failSwitch: failSwitch,
    );
  }

  final LessonRepository lessons;
  final VerificationRepository verifications;
  final SessionRepository sessions;

  // Postoji samo uz lažne podatke. Po njemu meni zna da li da ponudi „Simuliraj grešku“.
  final FailSwitch? failSwitch;
}
