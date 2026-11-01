import 'package:backoffice/app.dart';
import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/empty_lesson_repository.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/data/fake_lesson_repository.dart';
import 'package:backoffice/data/fake_verification_repository.dart';
import 'package:backoffice/lessons/lesson_detail.dart';
import 'package:backoffice/lessons/queue_table.dart';
import 'package:backoffice/router.dart';
import 'package:backoffice/text/domain_errors.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

import 'helpers.dart';

void main() {
  late FailSwitch failSwitch;

  // Bez pumpAndSettle, da test može da vidi i stanje dok se učitava.
  Future<void> pumpApp(WidgetTester tester, {LessonRepository? lessons}) async {
    useDesktopSize(tester);
    final now = DateTime.now();
    await tester.pumpWidget(
      BackofficeApp(
        failSwitch: failSwitch,
        lessons: lessons ?? FakeLessonRepository(demoLessons(now), failSwitch, delay: Duration.zero),
        verifications: FakeVerificationRepository(demoProfessors(now), failSwitch, delay: Duration.zero),
        router: createRouter(ValueNotifier<User>(milica)),
      ),
    );
  }

  Finder inTable(String text) => find.descendant(of: find.byType(QueueTable), matching: find.text(text));
  Finder inDetail(String text) => find.descendant(of: find.byType(LessonDetail), matching: find.text(text));

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUp(() => failSwitch = FailSwitch());

  testWidgets('shows a spinner while loading, then the pending requests', (tester) async {
    final now = DateTime.now();
    await pumpApp(tester, lessons: FakeLessonRepository(demoLessons(now), failSwitch));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    for (final name in ['Ana Marković', 'Nikola Petrović', 'Marija Stojanović', 'Luka Ilić', 'Teodora Đorđević']) {
      expect(inTable(name), findsOneWidget);
    }
    // Prvi red je izabran, pa detalj odmah nešto pokazuje.
    expect(find.text('Izaberite čas iz tabele.'), findsNothing);
  });

  testWidgets('a tab shows only its own lessons', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tapAndSettle(tester, find.text('Potvrđeni'));

    expect(inTable('Stefan Popović'), findsOneWidget);
    expect(inTable('Vuk Lazić'), findsOneWidget);
    expect(inTable('Nikola Petrović'), findsNothing);
  });

  // Red zahteva je poređan po terminu, a demo termini se računaju od danas. Zato testovi sami biraju red.
  testWidgets('clicking a row shows its message in the detail', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    const luka = 'Osmi sam razred i spremam malu maturu. Najteži su mi zadaci sa procentima i površinama.';
    const teodora = 'Spremam prijemni na FTN u junu. Htela bih da radimo stare testove i vidimo gde gubim poene.';

    await tapAndSettle(tester, inTable('Luka Ilić'));
    expect(inDetail('Luka Ilić'), findsOneWidget);
    expect(find.text(luka), findsOneWidget);

    await tapAndSettle(tester, inTable('Teodora Đorđević'));
    expect(inDetail('Teodora Đorđević'), findsOneWidget);
    expect(find.text(teodora), findsOneWidget);
    expect(find.text(luka), findsNothing);
  });

  testWidgets('Potvrdi on Ana also takes the other two requests for that slot out of Na čekanju', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    await tapAndSettle(tester, inTable('Ana Marković'));

    await tapAndSettle(tester, find.text('Potvrdi'));

    expect(inTable('Ana Marković'), findsNothing);
    expect(inTable('Nikola Petrović'), findsNothing);
    expect(inTable('Marija Stojanović'), findsNothing);
    expect(inTable('Luka Ilić'), findsOneWidget);
  });

  testWidgets('a held lesson that has not started yet shows the Serbian error', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Potvrđeni'));
    await tapAndSettle(tester, inTable('Ana Marković'));

    await tapAndSettle(tester, find.text('Označi kao održan'));

    expect(find.text(const LessonNotStarted().message), findsOneWidget);
    // Čas ostaje potvrđen.
    expect(inTable('Ana Marković'), findsOneWidget);
  });

  testWidgets('a failed load offers Pokušaj ponovo, which loads again', (tester) async {
    failSwitch.failNext = true;
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.text('Časovi nisu učitani.'), findsOneWidget);

    await tapAndSettle(tester, find.text('Pokušaj ponovo'));

    expect(find.text('Časovi nisu učitani.'), findsNothing);
    expect(inTable('Ana Marković'), findsOneWidget);
  });

  testWidgets('a professor without lessons sees the empty state', (tester) async {
    await pumpApp(tester, lessons: const EmptyLessonRepository(delay: Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Još nema zahteva za časove.'), findsOneWidget);
    expect(find.byType(QueueTable), findsNothing);
  });
}
