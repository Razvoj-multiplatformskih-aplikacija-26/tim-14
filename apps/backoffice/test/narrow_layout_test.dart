import 'package:backoffice/app.dart';
import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/data/fake_lesson_repository.dart';
import 'package:backoffice/data/fake_verification_repository.dart';
import 'package:backoffice/lessons/lesson_detail.dart';
import 'package:backoffice/lessons/queue_list.dart';
import 'package:backoffice/lessons/queue_table.dart';
import 'package:backoffice/router.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    useNarrowSize(tester);
    final now = DateTime.now();
    final failSwitch = FailSwitch();
    await tester.pumpWidget(
      BackofficeApp(
        failSwitch: failSwitch,
        lessons: FakeLessonRepository(demoLessons(now), failSwitch, delay: Duration.zero),
        verifications: FakeVerificationRepository(demoProfessors(now), failSwitch, delay: Duration.zero),
        router: createRouter(ValueNotifier<User>(milica)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inList(String text) => find.descendant(of: find.byType(QueueList), matching: find.text(text));
  Finder inTable(String text) => find.descendant(of: find.byType(QueueTable), matching: find.text(text));
  Finder inDetail(String text) => find.descendant(of: find.byType(LessonDetail), matching: find.text(text));

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> resize(WidgetTester tester, void Function(WidgetTester) useSize) async {
    useSize(tester);
    await tester.pumpAndSettle();
  }

  const luka = 'Osmi sam razred i spremam malu maturu. Najteži su mi zadaci sa procentima i površinama.';
  const teodora = 'Spremam prijemni na FTN u junu. Htela bih da radimo stare testove i vidimo gde gubim poene.';

  testWidgets('a narrow window shows the list instead of the table and the detail', (tester) async {
    await pumpApp(tester);

    expect(find.byType(QueueList), findsOneWidget);
    expect(find.byType(QueueTable), findsNothing);
    expect(find.byType(LessonDetail), findsNothing);
    for (final name in ['Ana Marković', 'Nikola Petrović', 'Marija Stojanović', 'Luka Ilić', 'Teodora Đorđević']) {
      expect(inList(name), findsOneWidget);
    }
  });

  testWidgets('tapping a card opens its detail, and Nazad goes back to the list', (tester) async {
    await pumpApp(tester);

    await tapAndSettle(tester, inList('Luka Ilić'));
    expect(find.byType(QueueList), findsNothing);
    expect(inDetail('Luka Ilić'), findsOneWidget);
    expect(inDetail(luka), findsOneWidget);

    await tapAndSettle(tester, find.text('Nazad'));
    expect(find.byType(LessonDetail), findsNothing);
    expect(inList('Luka Ilić'), findsOneWidget);
  });

  testWidgets('Enter on a focused card opens its detail', (tester) async {
    await pumpApp(tester);

    // Fokus je na InkWell-u kartice, kao posle Tab-a.
    Focus.of(tester.element(inList('Teodora Đorđević'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(inDetail('Teodora Đorđević'), findsOneWidget);
    expect(inDetail(teodora), findsOneWidget);
  });

  testWidgets('the selection stays when the window widens and narrows', (tester) async {
    await pumpApp(tester);

    // Otvoren u uskom, vidi se i u širokom.
    await tapAndSettle(tester, inList('Luka Ilić'));
    await resize(tester, useDesktopSize);
    expect(find.byType(QueueTable), findsOneWidget);
    expect(inDetail('Luka Ilić'), findsOneWidget);

    // Izabran u širokom, istaknut u uskom, pa opet u detalju širokog.
    await tapAndSettle(tester, inTable('Teodora Đorđević'));
    await resize(tester, useNarrowSize);
    expect(find.byType(LessonDetail), findsNothing);
    final card = tester.widget<Material>(
      find.ancestor(of: inList('Teodora Đorđević'), matching: find.byType(Material)).first,
    );
    expect(card.color, Theme.of(tester.element(find.byType(QueueList))).colorScheme.primaryContainer);

    await resize(tester, useDesktopSize);
    expect(inDetail('Teodora Đorđević'), findsOneWidget);
  });

  testWidgets('Potvrdi in the narrow detail goes back to the list without the other requests for that slot', (
    tester,
  ) async {
    await pumpApp(tester);
    await tapAndSettle(tester, inList('Ana Marković'));

    await tapAndSettle(tester, find.text('Potvrdi'));

    expect(find.byType(LessonDetail), findsNothing);
    expect(inList('Ana Marković'), findsNothing);
    expect(inList('Nikola Petrović'), findsNothing);
    expect(inList('Marija Stojanović'), findsNothing);
    expect(inList('Luka Ilić'), findsOneWidget);
  });
}
