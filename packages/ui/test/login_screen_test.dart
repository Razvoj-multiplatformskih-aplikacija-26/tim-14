import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'helpers.dart';

void main() {
  final loginField = find.widgetWithText(TextField, 'Korisničko ime');
  final passwordField = find.widgetWithText(TextField, 'Lozinka');
  final button = find.byType(FilledButton);

  bool buttonEnabled(WidgetTester tester) => tester.widget<FilledButton>(button).onPressed != null;

  // Every call to onSubmit, as (login, password).
  late List<(String, String)> submitted;

  setUp(() => submitted = []);

  LoginScreen screen({bool busy = false, String? errorText, String? noticeText}) => LoginScreen(
    title: 'Prijava',
    subtitle: 'Backoffice za profesore i administratore',
    onSubmit: (login, password) => submitted.add((login, password)),
    busy: busy,
    errorText: errorText,
    noticeText: noticeText,
  );

  testWidgets('submits the login and password as typed', (tester) async {
    await pumpInApp(tester, screen());

    await tester.enterText(loginField, 'profesor1');
    await tester.enterText(passwordField, 'casovi-demo');
    await tester.pump();
    await tester.tap(button);

    expect(submitted, [('profesor1', 'casovi-demo')]);
    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
  });

  testWidgets('Enter in the password field submits', (tester) async {
    await pumpInApp(tester, screen());

    await tester.enterText(loginField, 'profesor1');
    await tester.enterText(passwordField, 'casovi-demo');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(submitted, [('profesor1', 'casovi-demo')]);
  });

  testWidgets('the button stays off until both fields have text', (tester) async {
    await pumpInApp(tester, screen());
    expect(buttonEnabled(tester), isFalse);

    await tester.enterText(loginField, '   ');
    await tester.enterText(passwordField, 'casovi-demo');
    await tester.pump();
    expect(buttonEnabled(tester), isFalse, reason: 'a login of only spaces is empty');

    await tester.enterText(loginField, 'profesor1');
    await tester.pump();
    expect(buttonEnabled(tester), isTrue);

    // Enter with an empty field does nothing either.
    await tester.enterText(passwordField, '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, isEmpty);
  });

  testWidgets('while busy the fields and the button are off and a spinner shows', (tester) async {
    await pumpInApp(tester, screen(busy: true));

    expect(tester.widget<TextField>(loginField).enabled, isFalse);
    expect(tester.widget<TextField>(passwordField).enabled, isFalse);
    expect(buttonEnabled(tester), isFalse);
    expect(find.bySemanticsLabel('Prijava u toku'), findsOneWidget);
    expect(find.text('Prijavi se'), findsNothing);
  });

  testWidgets('shows the notice and the error', (tester) async {
    await pumpInApp(
      tester,
      screen(noticeText: 'Prijava je istekla. Prijavi se ponovo.', errorText: 'Nema veze sa serverom.'),
    );

    expect(find.text('Prijava je istekla. Prijavi se ponovo.'), findsOneWidget);
    expect(find.text('Nema veze sa serverom.'), findsOneWidget);
  });

  testWidgets('the typed login stays after an error comes back', (tester) async {
    // The app rebuilds the screen with new inputs; the State, and with it the fields, must survive that.
    final errorText = ValueNotifier<String?>(null);
    addTearDown(errorText.dispose);
    await pumpInApp(
      tester,
      ValueListenableBuilder(
        valueListenable: errorText,
        builder: (_, text, _) => screen(errorText: text),
      ),
    );

    await tester.enterText(loginField, 'profesor1');
    await tester.enterText(passwordField, 'pogresna');
    errorText.value = 'Pogrešno korisničko ime ili lozinka.';
    await tester.pump();

    expect(find.text('Pogrešno korisničko ime ili lozinka.'), findsOneWidget);
    expect(tester.widget<TextField>(loginField).controller!.text, 'profesor1');
  });
}
