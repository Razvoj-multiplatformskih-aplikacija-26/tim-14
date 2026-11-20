import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/data/fake_lesson_repository.dart';
import 'package:backoffice/data/fake_session_repository.dart';
import 'package:backoffice/data/fake_verification_repository.dart';
import 'package:backoffice/dependencies.dart';
import 'package:backoffice/lessons/lesson_queue_page.dart';
import 'package:backoffice/router.dart';
import 'package:backoffice/shell/sidebar.dart';
import 'package:backoffice/text/session.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

void main() {
  late FakeSessionRepository sessions;
  late GoRouter router;

  // Bez failSwitch-a za prijavu, osim kad test hoće da provera sesije ne stigne do servera.
  Future<void> pumpApp(WidgetTester tester, {User? signedIn, FailSwitch? sessionFails}) async {
    useDesktopSize(tester);
    sessions = FakeSessionRepository(sessionFails ?? FailSwitch(), signedIn: signedIn, delay: Duration.zero);
    router = await pumpBackoffice(tester, fakeDependencies(sessions: sessions));
    await tester.pumpAndSettle();
  }

  Future<void> logIn(WidgetTester tester, String login, {String password = FakeSessionRepository.password}) async {
    await tester.enterText(find.widgetWithText(TextField, 'Korisničko ime'), login);
    await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), password);
    // Dugme se uključi tek kad se ekran ponovo nacrta sa unetim tekstom.
    await tester.pump();
    await tester.tap(find.text('Prijavi se'));
    await tester.pumpAndSettle();
  }

  Future<void> logOut(WidgetTester tester, User user) async {
    await tester.tap(find.text(user.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odjava'));
    await tester.pumpAndSettle();
  }

  Finder navItem(String label) => find.descendant(of: find.byType(Sidebar), matching: find.text(label));

  testWidgets('nobody signed in: the login page, with nothing to explain', (tester) async {
    await pumpApp(tester);

    expect(locationOf(router), Routes.login);
    expect(find.text('Prijavi se'), findsOneWidget);
    expect(find.text(wrongCredentialsText), findsNothing);
    expect(find.text(SignOutReason.expired.notice!), findsNothing);
  });

  testWidgets('a signed-in user from before goes straight to their section', (tester) async {
    await pumpApp(tester, signedIn: milica);

    expect(locationOf(router), Routes.lessons);
  });

  testWidgets('profesor1 lands on Časovi, admin1 on Verifikacija', (tester) async {
    await pumpApp(tester);
    await logIn(tester, 'profesor1');
    expect(locationOf(router), Routes.lessons);
    expect(find.text(milica.name), findsOneWidget);

    await logOut(tester, milica);
    await logIn(tester, 'admin1');

    expect(locationOf(router), Routes.verification);
    expect(navItem('Verifikacija'), findsOneWidget);
    expect(navItem('Časovi'), findsNothing);
  });

  testWidgets('a student is refused with the text, and the session is closed again', (tester) async {
    await pumpApp(tester);

    await logIn(tester, 'ucenik1');

    expect(locationOf(router), Routes.login);
    expect(find.text(SignOutReason.roleNotAllowed.notice!), findsOneWidget);
    // SessionBloc je odmah odjavio učenika, pa ne ostaje sesija koju niko ne koristi.
    expect(sessions.signedIn, isNull);
  });

  testWidgets('a wrong password shows the error and keeps the login typed', (tester) async {
    await pumpApp(tester);

    await logIn(tester, 'profesor1', password: 'pogresna');

    expect(locationOf(router), Routes.login);
    expect(find.text(wrongCredentialsText), findsOneWidget);
    expect(find.text('profesor1'), findsOneWidget);
  });

  testWidgets('Odjava goes to the login and closes the Bloc of that user', (tester) async {
    await pumpApp(tester, signedIn: milica);
    final queue = tester.element(find.byType(LessonQueuePage)).read<LessonQueueBloc>();

    await logOut(tester, milica);

    expect(locationOf(router), Routes.login);
    expect(sessions.signedIn, isNull);
    expect(queue.isClosed, isTrue);
    // Sam se odjavio, pa nema poruke.
    expect(find.text(SignOutReason.expired.notice!), findsNothing);
  });

  testWidgets('an expired session goes back to the login with the reason', (tester) async {
    await pumpApp(tester, signedIn: milica);

    sessions.expire();
    await tester.pumpAndSettle();

    expect(locationOf(router), Routes.login);
    expect(find.text(SignOutReason.expired.notice!), findsOneWidget);
  });

  testWidgets('a server that cannot be reached at startup is explained on the login page', (tester) async {
    await pumpApp(tester, signedIn: milica, sessionFails: FailSwitch()..failNext = true);

    expect(locationOf(router), Routes.login);
    expect(find.text(SignOutReason.unreachable.notice!), findsOneWidget);
  });

  testWidgets('without a fail switch (the real server) the menu has no Simuliraj grešku', (tester) async {
    useDesktopSize(tester);
    final now = DateTime.now();
    final fails = FailSwitch();
    final dependencies = BackofficeDependencies(
      lessons: FakeLessonRepository(demoLessons(now), fails, delay: Duration.zero),
      verifications: FakeVerificationRepository(demoProfessors(now), fails, delay: Duration.zero),
      sessions: FakeSessionRepository(fails, signedIn: milica, delay: Duration.zero),
    );
    await pumpBackoffice(tester, dependencies);
    await tester.pumpAndSettle();

    await tester.tap(find.text(milica.name));
    await tester.pumpAndSettle();

    expect(find.text('Odjava'), findsOneWidget);
    expect(find.text('Simuliraj grešku'), findsNothing);
  });
}
