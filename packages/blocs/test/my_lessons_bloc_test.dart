import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  final pending = lessonAt(now.add(const Duration(days: 3)), id: 'pending');
  final confirmed = lessonAt(
    now.add(const Duration(days: 2)),
    id: 'confirmed',
    status: Confirmed(at: now),
  );
  final tooLate = lessonAt(
    now.add(const Duration(hours: 10)),
    id: 'too-late',
    status: Confirmed(at: now),
  );
  final held = lessonAt(
    now.subtract(const Duration(days: 7)),
    id: 'held',
    status: Held(at: now),
  );

  late InMemoryLessonRepository repository;

  MyLessonsBloc buildBloc() {
    final clock = FixedClock(now);
    return MyLessonsBloc(
      GetMyLessons(repository, student),
      WithdrawRequest(repository, clock, student),
      CancelLesson(repository, clock, student),
      clock,
      student,
    );
  }

  blocTest<MyLessonsBloc, MyLessonsState>(
    'shows my lessons sorted, with the action for each one',
    setUp: () => repository = InMemoryLessonRepository([pending, held, tooLate, confirmed]),
    build: buildBloc,
    act: (bloc) => bloc.add(MyLessonsRequested()),
    expect: () => [
      const MyLessonsLoading(),
      MyLessonsLoaded([
        LessonItem(lesson: held, action: LessonAction.none),
        LessonItem(
          lesson: tooLate,
          action: LessonAction.cancel,
          blockedBy: const CancellationTooLate(notice: cancellationNotice),
        ),
        LessonItem(lesson: confirmed, action: LessonAction.cancel),
        LessonItem(lesson: pending, action: LessonAction.withdraw),
      ]),
    ],
  );

  test('groups the lessons into upcoming, pending and history', () {
    final cancelled = lessonAt(
      now.subtract(const Duration(days: 2)),
      id: 'cancelled',
      status: Cancelled(by: student.id, at: now),
    );
    final state = MyLessonsLoaded([
      LessonItem(lesson: held, action: LessonAction.none),
      LessonItem(lesson: cancelled, action: LessonAction.none),
      LessonItem(lesson: confirmed, action: LessonAction.cancel),
      LessonItem(lesson: pending, action: LessonAction.withdraw),
    ]);

    expect(state.upcoming.map((item) => item.lesson), [confirmed]);
    expect(state.pending.map((item) => item.lesson), [pending]);
    // U istoriji su najnoviji prvi.
    expect(state.history.map((item) => item.lesson), [cancelled, held]);
  });

  blocTest<MyLessonsBloc, MyLessonsState>(
    'is empty when I have no lessons',
    setUp: () => repository = InMemoryLessonRepository(),
    build: buildBloc,
    act: (bloc) => bloc.add(MyLessonsRequested()),
    expect: () => [const MyLessonsLoading(), const MyLessonsEmpty()],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'shows a failure with its kind when the repository throws',
    setUp: () => repository = InMemoryLessonRepository([pending])..fail = true,
    build: buildBloc,
    act: (bloc) => bloc.add(MyLessonsRequested()),
    expect: () => [const MyLessonsLoading(), const MyLessonsFailure(RepositoryFailure.unavailable)],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'retry after a failure loads the lessons',
    setUp: () => repository = InMemoryLessonRepository([pending]),
    build: buildBloc,
    seed: () => const MyLessonsFailure(RepositoryFailure.unreachable),
    act: (bloc) => bloc.add(MyLessonsRetried()),
    expect: () => [
      const MyLessonsLoading(),
      MyLessonsLoaded([LessonItem(lesson: pending, action: LessonAction.withdraw)]),
    ],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'cancelling a lesson in two days saves it',
    setUp: () => repository = InMemoryLessonRepository([confirmed]),
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: confirmed, action: LessonAction.cancel)]),
    act: (bloc) => bloc.add(LessonCancelled(confirmed)),
    expect: () => [
      MyLessonsLoaded([
        LessonItem(
          lesson: confirmed.copyWith(
            status: Cancelled(by: student.id, at: now),
          ),
          action: LessonAction.none,
        ),
      ]),
    ],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'cancelling a lesson in ten hours shows the reason, then reloads quietly',
    setUp: () => repository = InMemoryLessonRepository([tooLate]),
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: tooLate, action: LessonAction.cancel)]),
    act: (bloc) => bloc.add(LessonCancelled(tooLate)),
    expect: () => [
      MyLessonsLoaded([
        LessonItem(lesson: tooLate, action: LessonAction.cancel),
      ], notice: const ActionRejected(CancellationTooLate(notice: cancellationNotice))),
      // Ponovo učitano, bez spinera i bez poruke. Sada stavka zna i zašto otkazivanje ne može.
      MyLessonsLoaded([
        LessonItem(
          lesson: tooLate,
          action: LessonAction.cancel,
          blockedBy: const CancellationTooLate(notice: cancellationNotice),
        ),
      ]),
    ],
    verify: (_) => expect(repository.lessons.single.status, isA<Confirmed>()),
  );

  // Kasni klijent: profesor je potvrdio zahtev dok je lista na ekranu još pokazivala "na čekanju".
  blocTest<MyLessonsBloc, MyLessonsState>(
    'a withdrawal the server refuses because the lesson changed meanwhile shows why and reloads the list',
    setUp: () => repository = InMemoryLessonRepository([pending.copyWith(status: Confirmed(at: now))]),
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: pending, action: LessonAction.withdraw)]),
    act: (bloc) => bloc.add(LessonWithdrawn(pending)),
    expect: () => [
      MyLessonsLoaded([
        LessonItem(lesson: pending, action: LessonAction.withdraw),
      ], notice: const ActionRejected(LessonChanged())),
      MyLessonsLoaded([
        LessonItem(
          lesson: pending.copyWith(status: Confirmed(at: now)),
          action: LessonAction.cancel,
        ),
      ]),
    ],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'withdrawing a pending request saves it',
    setUp: () => repository = InMemoryLessonRepository([pending]),
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: pending, action: LessonAction.withdraw)]),
    act: (bloc) => bloc.add(LessonWithdrawn(pending)),
    expect: () => [
      MyLessonsLoaded([
        LessonItem(
          lesson: pending.copyWith(
            status: Cancelled(by: student.id, at: now),
          ),
          action: LessonAction.none,
        ),
      ]),
    ],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'a repository error during cancelling keeps the list and says what happened',
    setUp: () => repository = InMemoryLessonRepository([confirmed]),
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: confirmed, action: LessonAction.cancel)]),
    act: (bloc) {
      repository.fail = true;
      bloc.add(LessonCancelled(confirmed));
    },
    expect: () => [
      MyLessonsLoaded([
        LessonItem(lesson: confirmed, action: LessonAction.cancel),
      ], notice: const ActionFailed(RepositoryFailure.unavailable)),
    ],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'the same failure twice in a row still reaches the screen both times',
    setUp: () => repository = InMemoryLessonRepository([confirmed])..fail = true,
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: confirmed, action: LessonAction.cancel)]),
    act: (bloc) async {
      bloc.add(LessonCancelled(confirmed));
      await Future<void>.delayed(Duration.zero);
      bloc.add(LessonCancelled(confirmed));
    },
    expect: () {
      final items = [LessonItem(lesson: confirmed, action: LessonAction.cancel)];
      final failed = MyLessonsLoaded(items, notice: const ActionFailed(RepositoryFailure.unavailable));
      return [failed, MyLessonsLoaded(items), failed];
    },
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'refreshing with the list on screen reloads quietly, without a spinner',
    setUp: () => repository = InMemoryLessonRepository([pending, confirmed]),
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: pending, action: LessonAction.withdraw)]),
    act: (bloc) => bloc.add(MyLessonsRefreshed()),
    expect: () => [
      MyLessonsLoaded([
        LessonItem(lesson: confirmed, action: LessonAction.cancel),
        LessonItem(lesson: pending, action: LessonAction.withdraw),
      ]),
    ],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'refreshing before anything is loaded loads with a spinner',
    setUp: () => repository = InMemoryLessonRepository([pending]),
    build: buildBloc,
    act: (bloc) => bloc.add(MyLessonsRefreshed()),
    expect: () => [
      const MyLessonsLoading(),
      MyLessonsLoaded([LessonItem(lesson: pending, action: LessonAction.withdraw)]),
    ],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'a refresh that cannot reach the server keeps the list on screen',
    setUp: () => repository = InMemoryLessonRepository([pending])..fail = true,
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: pending, action: LessonAction.withdraw)]),
    act: (bloc) => bloc.add(MyLessonsRefreshed()),
    expect: () => [
      MyLessonsLoaded([
        LessonItem(lesson: pending, action: LessonAction.withdraw),
      ], notice: const ActionFailed(RepositoryFailure.unavailable)),
    ],
  );
}
