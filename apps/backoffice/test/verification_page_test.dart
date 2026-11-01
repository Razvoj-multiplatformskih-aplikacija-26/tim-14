import 'package:backoffice/app.dart';
import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/data/fake_lesson_repository.dart';
import 'package:backoffice/data/fake_verification_repository.dart';
import 'package:backoffice/router.dart';
import 'package:backoffice/text/domain_errors.dart';
import 'package:backoffice/verification/profile_detail.dart';
import 'package:backoffice/verification/verification_list.dart';
import 'package:backoffice/verification/verification_table.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

import 'helpers.dart';

void main() {
  late FailSwitch failSwitch;

  // Ulogovan je administrator, pa ruter odmah otvara Verifikaciju. Bez pumpAndSettle, da se vidi i učitavanje.
  Future<void> pumpApp(WidgetTester tester, {VerificationRepository? verifications}) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      BackofficeApp(
        failSwitch: failSwitch,
        lessons: FakeLessonRepository(demoLessons(now), failSwitch, delay: Duration.zero),
        verifications:
            verifications ?? FakeVerificationRepository(demoProfessors(now), failSwitch, delay: Duration.zero),
        router: createRouter(ValueNotifier<User>(admin)),
      ),
    );
  }

  Finder inTable(String text) => find.descendant(of: find.byType(VerificationTable), matching: find.text(text));
  Finder inList(String text) => find.descendant(of: find.byType(VerificationList), matching: find.text(text));
  Finder inDetail(String text) => find.descendant(of: find.byType(ProfileDetail), matching: find.text(text));

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> resize(WidgetTester tester, void Function(WidgetTester) useSize) async {
    useSize(tester);
    await tester.pumpAndSettle();
  }

  const waiting = ['Dragan Simić', 'Ana Kovačević', 'Milan Đurić', 'Jelena Marković'];

  setUp(() => failSwitch = FailSwitch());

  group('wide window', () {
    testWidgets('shows a spinner, then only the professors on review, oldest first and selected', (tester) async {
      useDesktopSize(tester);
      final now = DateTime.now();
      await pumpApp(tester, verifications: FakeVerificationRepository(demoProfessors(now), failSwitch));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      for (final name in waiting) {
        expect(inTable(name), findsOneWidget);
      }
      for (final name in ['Milica Jovanović', 'Ivana Pavlović', 'Bojan Stanković']) {
        expect(inTable(name), findsNothing);
      }
      expect(inDetail('Dragan Simić'), findsOneWidget);
      expect(inDetail('diploma-dragan-simic.pdf'), findsOneWidget);
    });

    testWidgets('clicking a row shows that professor with the diploma and LinkedIn', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tapAndSettle(tester, inTable('Jelena Marković'));

      expect(inDetail('Jelena Marković'), findsOneWidget);
      expect(inDetail('Novi Sad'), findsOneWidget);
      expect(inDetail('diploma-jelena-markovic.pdf'), findsOneWidget);
      expect(inDetail('https://www.linkedin.com/in/jelena-markovic'), findsOneWidget);
      expect(inDetail('Master matematičar'), findsOneWidget);
      expect(inDetail('2019 – danas'), findsOneWidget);
    });

    testWidgets('Verifikuj takes the professor out of the queue and selects the next one', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tapAndSettle(tester, find.text('Verifikuj'));

      expect(inTable('Dragan Simić'), findsNothing);
      expect(inDetail('Ana Kovačević'), findsOneWidget);
    });

    testWidgets('a short reason shows the Serbian error and keeps Odbij disabled', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Odbij uz razlog'));

      await tester.enterText(find.byType(TextField), 'Nečitko');
      await tester.pump();

      expect(find.text(const RejectionReasonTooShort(7).message), findsOneWidget);
      final reject = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Odbij'));
      expect(reject.onPressed, isNull);
    });

    testWidgets('a long enough reason rejects the professor', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Odbij uz razlog'));

      await tester.enterText(find.byType(TextField), 'Diploma nije čitka.');
      await tester.pump();
      await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Odbij'));

      expect(find.byType(AlertDialog), findsNothing);
      expect(inTable('Dragan Simić'), findsNothing);
      expect(inDetail('Ana Kovačević'), findsOneWidget);
    });

    testWidgets('Odustani closes the dialog and leaves the professor in the queue', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text('Odbij uz razlog'));

      await tapAndSettle(tester, find.text('Odustani'));

      expect(find.byType(AlertDialog), findsNothing);
      expect(inTable('Dragan Simić'), findsOneWidget);
    });

    testWidgets('a failed load offers Pokušaj ponovo, which loads again', (tester) async {
      useDesktopSize(tester);
      failSwitch.failNext = true;
      await pumpApp(tester);
      await tester.pumpAndSettle();
      expect(find.text('Red za verifikaciju nije učitan.'), findsOneWidget);

      await tapAndSettle(tester, find.text('Pokušaj ponovo'));

      expect(find.text('Red za verifikaciju nije učitan.'), findsNothing);
      expect(inTable('Dragan Simić'), findsOneWidget);
    });

    testWidgets('an empty queue shows the empty state', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester, verifications: FakeVerificationRepository([], failSwitch, delay: Duration.zero));
      await tester.pumpAndSettle();

      expect(find.text('Nema profesora koji čekaju proveru.'), findsOneWidget);
      expect(find.byType(VerificationTable), findsNothing);
    });
  });

  group('narrow window', () {
    testWidgets('shows the list instead of the table and the detail', (tester) async {
      useNarrowSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();

      expect(find.byType(VerificationTable), findsNothing);
      expect(find.byType(ProfileDetail), findsNothing);
      for (final name in waiting) {
        expect(inList(name), findsOneWidget);
      }
    });

    testWidgets('tapping a card opens its detail, and Nazad goes back to the list', (tester) async {
      useNarrowSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();

      await tapAndSettle(tester, inList('Jelena Marković'));
      expect(find.byType(VerificationList), findsNothing);
      expect(inDetail('diploma-jelena-markovic.pdf'), findsOneWidget);

      await tapAndSettle(tester, find.text('Nazad'));
      expect(find.byType(ProfileDetail), findsNothing);
      expect(inList('Jelena Marković'), findsOneWidget);
    });

    testWidgets('Verifikuj in the detail goes back to the list without that professor', (tester) async {
      useNarrowSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, inList('Milan Đurić'));

      await tapAndSettle(tester, find.text('Verifikuj'));

      expect(find.byType(ProfileDetail), findsNothing);
      expect(inList('Milan Đurić'), findsNothing);
      expect(inList('Jelena Marković'), findsOneWidget);
    });

    testWidgets('the selection stays when the window narrows and widens', (tester) async {
      useDesktopSize(tester);
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await tapAndSettle(tester, inTable('Jelena Marković'));

      await resize(tester, useNarrowSize);
      final card = tester.widget<Material>(
        find.ancestor(of: inList('Jelena Marković'), matching: find.byType(Material)).first,
      );
      expect(card.color, Theme.of(tester.element(find.byType(VerificationList))).colorScheme.primaryContainer);

      await resize(tester, useDesktopSize);
      expect(inDetail('Jelena Marković'), findsOneWidget);
    });
  });
}
