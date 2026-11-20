import 'package:backoffice/app.dart';
import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/data/fake_lesson_repository.dart';
import 'package:backoffice/data/fake_session_repository.dart';
import 'package:backoffice/data/fake_verification_repository.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/router.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:use_cases/use_cases.dart';

// Test inače crta na 800×600, a široki raspored sa tabelom i detaljem traži desktop prozor.
void useDesktopSize(WidgetTester tester) => _useSize(tester, const Size(1440, 900));

// Uzak prozor: sidebar je u fioki, a strana dobije oko 736 px, pa umesto tabele crta listu.
void useNarrowSize(WidgetTester tester) => _useSize(tester, const Size(800, 900));

void _useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// Lažni podaci bez kašnjenja. signedIn je korisnik koji je već prijavljen kad aplikacija krene (null: niko).
// Prijava ima svoj FailSwitch, pa failNext koji test postavi pre pokretanja pogodi učitavanje liste, a ne proveru sesije.
BackofficeDependencies fakeDependencies({
  User? signedIn = milica,
  FailSwitch? failSwitch,
  LessonRepository? lessons,
  VerificationRepository? verifications,
  FakeSessionRepository? sessions,
}) {
  final now = DateTime.now();
  final fails = failSwitch ?? FailSwitch();
  return BackofficeDependencies(
    lessons: lessons ?? FakeLessonRepository(demoLessons(now), fails, delay: Duration.zero),
    verifications: verifications ?? FakeVerificationRepository(demoProfessors(now), fails, delay: Duration.zero),
    sessions: sessions ?? FakeSessionRepository(FailSwitch(), signedIn: signedIn, delay: Duration.zero),
    failSwitch: fails,
  );
}

// Cela aplikacija, kao u main.dart. Vraća ruter, da test može da pita na kojoj je adresi.
// Bez pumpAndSettle, da test vidi i stanje dok se učitava. Drugi pump pusti proveru sesije,
// pa je posle njega strana prijavljenog korisnika već na ekranu.
Future<GoRouter> pumpBackoffice(WidgetTester tester, BackofficeDependencies dependencies) async {
  final session = createSessionBloc(dependencies.sessions)..add(const SessionRestoreRequested());
  addTearDown(session.close);
  final router = createRouter(session);
  await tester.pumpWidget(BackofficeApp(dependencies: dependencies, session: session, router: router));
  await tester.pump();
  return router;
}

String locationOf(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;
