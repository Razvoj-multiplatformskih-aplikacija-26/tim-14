import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/demo_data.dart';
import 'package:mobile/data/fail_switch.dart';
import 'package:mobile/data/fake_lesson_repository.dart';
import 'package:mobile/data/fake_session_repository.dart';
import 'package:mobile/router.dart';
import 'package:use_cases/use_cases.dart';

import 'helpers.dart';

void main() {
  const clock = SystemClock();

  Future<FakeSessionRepository> openApp(WidgetTester tester, {User? signedIn}) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final failSwitch = FailSwitch();
    final sessions = FakeSessionRepository(signedIn: signedIn);
    await tester.pumpWidget(
      testApp(
        lessons: FakeLessonRepository(demoLessons(clock.now()), failSwitch),
        failSwitch: failSwitch,
        sessions: sessions,
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    return sessions;
  }

  Future<void> logIn(WidgetTester tester, String login, {String password = FakeSessionRepository.password}) async {
    await tester.enterText(find.widgetWithText(TextField, 'Korisničko ime'), login);
    await tester.enterText(find.widgetWithText(TextField, 'Lozinka'), password);
    // Dugme se uključi tek kad se ekran ponovo nacrta sa oba popunjena polja.
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Prijavi se'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('a visitor starts on Profesori, and Časovi asks for a login', (tester) async {
    await openApp(tester);
    expect(find.text('Milica Jovanović'), findsOneWidget);

    await tester.tap(find.text('Časovi'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.widgetWithText(FilledButton, 'Prijavi se'), findsOneWidget);
  });

  testWidgets('a student logs in and lands back on Moji časovi', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Časovi'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await logIn(tester, 'ucenik1');

    expect(find.text('Moji časovi'), findsOneWidget);
    expect(find.text('Predstojeći'), findsOneWidget);
  });

  testWidgets('a wrong password keeps the login screen with the reason', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Časovi'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await logIn(tester, 'ucenik1', password: 'pogresna');

    expect(find.text('Pogrešno korisničko ime ili lozinka.'), findsOneWidget);
  });

  testWidgets('a professor is refused and told to use the backoffice', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Časovi'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await logIn(tester, 'profesor1');

    expect(
      find.text('Mobilna aplikacija je za učenike. Profesori i administratori rade u backoffice-u.'),
      findsOneWidget,
    );
    expect(find.text('Moji časovi'), findsNothing);
  });

  testWidgets('an expired session goes back to the login and says why', (tester) async {
    final sessions = await openApp(tester, signedIn: ana);
    expect(find.text('Predstojeći'), findsOneWidget);

    sessions.expire();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('Prijava je istekla. Prijavi se ponovo.'), findsOneWidget);
  });

  testWidgets('logout closes the lessons, and the next student sees only their own', (tester) async {
    await openApp(tester, signedIn: ana);
    expect(find.text('Predstojeći'), findsOneWidget);

    await tester.tap(find.byTooltip('Odjava'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.widgetWithText(FilledButton, 'Prijavi se'), findsOneWidget);

    // U demo podacima svi časovi su Anini, pa Nikola posle nje ne vidi nijedan.
    await logIn(tester, 'ucenik2');
    expect(find.text('Još nemaš nijedan čas.'), findsOneWidget);
  });

  testWidgets('pulling Moji časovi down reloads and the spinner goes away', (tester) async {
    await openApp(tester, signedIn: ana);

    await tester.fling(find.text('Predstojeći'), const Offset(0, 400), 1000);
    await tester.pump();
    expect(find.byType(RefreshProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byType(RefreshProgressIndicator), findsNothing);
    expect(find.text('Predstojeći'), findsOneWidget);
  });

  group('signInRedirect', () {
    const signedIn = SignedIn(ana);
    const signedOut = SignedOut();

    test('waits on the splash while the session is unknown', () {
      expect(signInRedirect(const SessionUnknown(), Uri.parse('/casovi')), '/start');
      expect(signInRedirect(const SessionUnknown(), Uri.parse('/start')), isNull);
    });

    test('starts a visitor on Profesori and a student on Moji časovi', () {
      expect(signInRedirect(signedOut, Uri.parse('/start')), '/profesori');
      expect(signInRedirect(signedIn, Uri.parse('/start')), '/casovi');
    });

    test('lets a visitor see professors but not lessons or the request form', () {
      expect(signInRedirect(signedOut, Uri.parse('/profesori/milica-jovanovic')), isNull);
      expect(signInRedirect(signedOut, Uri.parse('/casovi/l-1')), '/prijava?posle=%2Fcasovi%2Fl-1');
      expect(
        signInRedirect(signedOut, Uri.parse('/profesori/milica-jovanovic/zahtev?termin=s-1')),
        '/prijava?posle=%2Fprofesori%2Fmilica-jovanovic%2Fzahtev%3Ftermin%3Ds-1',
      );
    });

    test('after the login goes back where the student was sent from, only inside the app', () {
      expect(signInRedirect(signedIn, Uri.parse('/prijava?posle=%2Fcasovi%2Fl-1')), '/casovi/l-1');
      expect(signInRedirect(signedIn, Uri.parse('/prijava')), '/casovi');
      expect(signInRedirect(signedIn, Uri.parse('/prijava?posle=https://example.com')), '/casovi');
    });
  });
}
