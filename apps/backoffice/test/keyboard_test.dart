import 'package:backoffice/app.dart';
import 'package:backoffice/data/demo_data.dart';
import 'package:backoffice/data/fail_switch.dart';
import 'package:backoffice/data/fake_lesson_repository.dart';
import 'package:backoffice/data/fake_verification_repository.dart';
import 'package:backoffice/lessons/queue_table.dart';
import 'package:backoffice/router.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/ui.dart';

import 'helpers.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    useDesktopSize(tester);
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

  Finder inTable(String text) => find.descendant(of: find.byType(QueueTable), matching: find.text(text));

  // Redosled redova zavisi od današnjeg datuma, pa ga testovi čitaju iz Bloca umesto da ga pogađaju.
  LessonQueueLoaded queueState(WidgetTester tester) =>
      tester.element(find.byType(QueueTable)).read<LessonQueueBloc>().state as LessonQueueLoaded;

  Color tableBorderColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(QueueTable), matching: find.byType(DecoratedBox)).first,
    );
    return ((box.decoration as BoxDecoration).border! as Border).top.color;
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> pressAndSettle(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  testWidgets('right after loading the table has the focus ring, and the arrows move the selection', (tester) async {
    await pumpApp(tester);
    final rows = queueState(tester).visibleRows;

    // Bez ijednog klika: autofocus je već dao fokus tabeli.
    expect(tableBorderColor(tester), AppColors.ring);
    expect(queueState(tester).selectedId, rows[0].lesson.id);

    await pressAndSettle(tester, LogicalKeyboardKey.arrowDown);
    expect(queueState(tester).selectedId, rows[1].lesson.id);

    await pressAndSettle(tester, LogicalKeyboardKey.arrowUp);
    expect(queueState(tester).selectedId, rows[0].lesson.id);
  });

  testWidgets('P on Ana also takes the other two requests for that slot out of Na čekanju', (tester) async {
    await pumpApp(tester);
    // Klik bira red, ali ne uzima fokus, pa P i dalje stiže do prečica.
    await tapAndSettle(tester, inTable('Ana Marković'));

    await pressAndSettle(tester, LogicalKeyboardKey.keyP);

    expect(inTable('Ana Marković'), findsNothing);
    expect(inTable('Nikola Petrović'), findsNothing);
    expect(inTable('Marija Stojanović'), findsNothing);
    expect(inTable('Luka Ilić'), findsOneWidget);
  });

  testWidgets('O rejects only the selected request', (tester) async {
    await pumpApp(tester);
    await tapAndSettle(tester, inTable('Luka Ilić'));

    await pressAndSettle(tester, LogicalKeyboardKey.keyO);

    expect(inTable('Luka Ilić'), findsNothing);
    expect(inTable('Ana Marković'), findsOneWidget);
  });

  testWidgets('holding P confirms only the selected request, not the next one too', (tester) async {
    await pumpApp(tester);
    final pendingBefore = queueState(tester).visibleRows.length;
    // Lukin termin se ne preklapa ni sa čijim, pa potvrda menja tačno jedan red.
    await tapAndSettle(tester, inTable('Luka Ilić'));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
    await tester.pumpAndSettle();

    expect(inTable('Luka Ilić'), findsNothing);
    expect(queueState(tester).visibleRows.length, pendingBefore - 1);
  });
}
