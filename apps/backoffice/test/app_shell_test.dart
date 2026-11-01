import 'package:backoffice/app.dart';
import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/data/fake_lesson_repository.dart';
import 'package:backoffice/data/fake_verification_repository.dart';
import 'package:backoffice/lessons/lesson_queue_page.dart';
import 'package:backoffice/router.dart';
import 'package:backoffice/shell/sidebar.dart';
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

  Future<void> pumpApp(WidgetTester tester) async {
    useDesktopSize(tester);
    final now = DateTime.now();
    failSwitch = FailSwitch();
    router = createRouter(ValueNotifier<User>(milica));
    await tester.pumpWidget(
      BackofficeApp(
        failSwitch: failSwitch,
        lessons: FakeLessonRepository(demoLessons(now), failSwitch, delay: Duration.zero),
        verifications: FakeVerificationRepository(demoProfessors(now), failSwitch, delay: Duration.zero),
        router: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.path;

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

    expect(location(), Routes.lessons);
    expect(navItem('Časovi'), findsOneWidget);
    expect(navItem('Verifikacija'), findsNothing);
    expect(find.text(milica.name), findsOneWidget);
  });

  testWidgets('switching to the admin opens Verifikacija and hides Časovi', (tester) async {
    await pumpApp(tester);

    await openMenuAndTap(tester, find.textContaining('Pređi na'));

    expect(location(), Routes.verification);
    expect(navItem('Verifikacija'), findsOneWidget);
    expect(navItem('Časovi'), findsNothing);
    expect(find.text(admin.name), findsOneWidget);
  });

  testWidgets('a professor is sent back from the admin URL and from an unknown one', (tester) async {
    await pumpApp(tester);

    router.go(Routes.verification);
    await tester.pumpAndSettle();
    expect(location(), Routes.lessons);

    router.go('/nepostoji');
    await tester.pumpAndSettle();
    expect(location(), Routes.lessons);
  });

  testWidgets('Simuliraj grešku arms the fail switch and says so', (tester) async {
    await pumpApp(tester);

    await openMenuAndTap(tester, find.text('Simuliraj grešku'));

    expect(failSwitch.failNext, isTrue);
    expect(find.text('Sledeći zahtev će vratiti grešku.'), findsOneWidget);
  });

  testWidgets('both Blocs are provided and load from the fake repositories', (tester) async {
    await pumpApp(tester);
    final context = tester.element(find.byType(LessonQueuePage));

    final lessons = context.read<LessonQueueBloc>();
    final verification = context.read<VerificationQueueBloc>();
    await tester.pumpAndSettle();

    expect(lessons.state, isA<LessonQueueLoaded>());
    expect(verification.state, isA<VerificationQueueLoaded>());
  });
}
