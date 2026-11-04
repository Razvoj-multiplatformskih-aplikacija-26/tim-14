import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';
import 'package:mobile/data/demo_data.dart';
import 'package:mobile/data/fail_switch.dart';
import 'package:mobile/data/fake_lesson_repository.dart';
import 'package:mobile/widgets/lesson_card.dart';
import 'package:use_cases/use_cases.dart';

import 'helpers.dart';

void main() {
  const clock = SystemClock();

  // Otvori profil Milice i klikne na prvi slobodan termin.
  Future<void> openForm(WidgetTester tester) async {
    // Visok ekran, da ListView nacrta sve kartice časova.
    tester.view.physicalSize = const Size(1200, 9000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final failSwitch = FailSwitch();
    await tester.pumpWidget(
      App(
        lessons: FakeLessonRepository(demoLessons(clock.now()), failSwitch),
        professors: demoProfessorRepository(failSwitch),
        clock: clock,
        me: ana,
        failSwitch: failSwitch,
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await tester.tap(find.text('Profesori').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Milica Jovanović'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byType(ActionChip).first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  Future<void> send(WidgetTester tester, String message) async {
    await tester.enterText(find.byType(TextField), message);
    await tester.pump();
    await tester.tap(find.text('Pošalji zahtev'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  testWidgets('a sent request shows up in Moji časovi as pending', (tester) async {
    await openForm(tester);
    expect(find.text('Zahtev za čas'), findsOneWidget);
    expect(find.text('0/300'), findsOneWidget);

    await send(tester, 'Treba mi pomoć oko integrala.');
    expect(find.text('Zahtev je poslat. Profesor će ga potvrditi ili odbiti.'), findsOneWidget);

    await tester.tap(find.text('Nazad na moje časove'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    // Ana je imala 10 časova, sada ima i novi zahtev.
    expect(find.byType(LessonCard), findsNWidgets(11));
  });

  testWidgets('a message over 300 characters shows an error and the button is disabled', (tester) async {
    await openForm(tester);

    await tester.enterText(find.byType(TextField), 'a' * 301);
    await tester.pump();

    expect(find.text('301/300'), findsOneWidget);
    expect(find.textContaining('najviše 300 znakova'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Pošalji zahtev'));
    expect(button.onPressed, isNull);
  });

  testWidgets('a fourth pending request shows the rule error', (tester) async {
    await openForm(tester);
    await send(tester, 'Prvi novi zahtev');
    await tester.tap(find.text('Nazad na moje časove'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Ana sada ima 3 zahteva na čekanju, pa četvrti ne prolazi.
    // Tab Profesori je ostao na Milicinom profilu.
    await tester.tap(find.text('Profesori').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Profil profesora'), findsOneWidget);
    await tester.tap(find.byType(ActionChip).last);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await send(tester, 'Četvrti zahtev');

    expect(find.textContaining('Već imaš 3 zahteva na čekanju'), findsOneWidget);
    // Posle greške tekst ostaje u polju, isti kao u brojaču.
    expect(find.widgetWithText(TextField, 'Četvrti zahtev'), findsOneWidget);
  });
}
