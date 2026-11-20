import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/lessons/lesson_queue_page.dart';
import 'package:backoffice/router.dart';
import 'package:backoffice/shell/sidebar.dart';
import 'package:backoffice/verification/verification_page.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers.dart';

void main() {
  late FailSwitch failSwitch;
  late GoRouter router;

  Future<void> pumpApp(WidgetTester tester, {User user = milica}) async {
    useDesktopSize(tester);
    failSwitch = FailSwitch();
    router = await pumpBackoffice(tester, fakeDependencies(signedIn: user, failSwitch: failSwitch));
    await tester.pumpAndSettle();
  }

  // Naslov strane i stavka sidebara imaju isti tekst, pa se stavka traži samo u sidebaru.
  Finder navItem(String label) => find.descendant(of: find.byType(Sidebar), matching: find.text(label));

  Future<void> openMenuAndTap(WidgetTester tester, Finder item) async {
    await tester.tap(find.text(milica.name));
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  testWidgets('starts on Časovi as the professor', (tester) async {
    await pumpApp(tester);

    expect(locationOf(router), Routes.lessons);
    expect(navItem('Časovi'), findsOneWidget);
    expect(navItem('Verifikacija'), findsNothing);
    expect(find.text(milica.name), findsOneWidget);
  });

  testWidgets('the admin starts on Verifikacija and does not see Časovi', (tester) async {
    await pumpApp(tester, user: admin);

    expect(locationOf(router), Routes.verification);
    expect(navItem('Verifikacija'), findsOneWidget);
    expect(navItem('Časovi'), findsNothing);
    expect(find.text(admin.name), findsOneWidget);
  });

  testWidgets('a professor is sent back from the admin URL, the login URL and an unknown one', (tester) async {
    await pumpApp(tester);

    for (final address in [Routes.verification, Routes.login, '/nepostoji']) {
      router.go(address);
      await tester.pumpAndSettle();
      expect(locationOf(router), Routes.lessons, reason: address);
    }
  });

  testWidgets('Simuliraj grešku arms the fail switch and says so', (tester) async {
    await pumpApp(tester);

    await openMenuAndTap(tester, find.text('Simuliraj grešku'));

    expect(failSwitch.failNext, isTrue);
    expect(find.text('Sledeći zahtev će vratiti grešku.'), findsOneWidget);
  });

  testWidgets('a narrow window hides the sidebar behind the menu button', (tester) async {
    await pumpApp(tester);
    useNarrowSize(tester);
    await tester.pumpAndSettle();
    expect(find.byType(Sidebar), findsNothing);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(navItem('Časovi'), findsOneWidget);
    expect(find.text(milica.name), findsOneWidget);
  });

  testWidgets('tapping Časovi in the drawer closes the drawer', (tester) async {
    await pumpApp(tester);
    useNarrowSize(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(navItem('Časovi'));
    await tester.pumpAndSettle();

    expect(find.byType(Sidebar), findsNothing);
    expect(locationOf(router), Routes.lessons);
  });

  // Svaka uloga dobija samo Bloc za svoj deo. Tuđi Bloc ne postoji, pa ne može ni da se pročita.
  testWidgets('the professor gets only the lesson queue Bloc', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(LessonQueuePage));

    expect(context.read<LessonQueueBloc>().state, isA<LessonQueueLoaded>());
    expect(() => context.read<VerificationQueueBloc>(), throwsA(isA<Exception>()));
  });

  testWidgets('the admin gets only the verification queue Bloc', (tester) async {
    await pumpApp(tester, user: admin);
    final context = tester.element(find.byType(VerificationPage));

    expect(context.read<VerificationQueueBloc>().state, isA<VerificationQueueLoaded>());
    expect(() => context.read<LessonQueueBloc>(), throwsA(isA<Exception>()));
  });
}
