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
        LessonItem(lesson: tooLate, action: LessonAction.cancel, blockedBy: const CancellationTooLate()),
        LessonItem(lesson: confirmed, action: LessonAction.cancel),
        LessonItem(lesson: pending, action: LessonAction.withdraw),
      ]),
    ],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'is empty when I have no lessons',
    setUp: () => repository = InMemoryLessonRepository(),
    build: buildBloc,
    act: (bloc) => bloc.add(MyLessonsRequested()),
    expect: () => [const MyLessonsLoading(), const MyLessonsEmpty()],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'shows a failure when the repository throws',
    setUp: () => repository = InMemoryLessonRepository([pending])..fail = true,
    build: buildBloc,
    act: (bloc) => bloc.add(MyLessonsRequested()),
    expect: () => [const MyLessonsLoading(), const MyLessonsFailure('Nema mreže')],
  );

  blocTest<MyLessonsBloc, MyLessonsState>(
    'retry after a failure loads the lessons',
    setUp: () => repository = InMemoryLessonRepository([pending]),
    build: buildBloc,
    seed: () => const MyLessonsFailure('Nema mreže'),
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
    'cancelling a lesson in ten hours shows an error',
    setUp: () => repository = InMemoryLessonRepository([tooLate]),
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: tooLate, action: LessonAction.cancel)]),
    act: (bloc) => bloc.add(LessonCancelled(tooLate)),
    expect: () => [
      MyLessonsLoaded([
        LessonItem(lesson: tooLate, action: LessonAction.cancel),
      ], actionError: const CancellationTooLate()),
    ],
    verify: (_) => expect(repository.lessons.single.status, isA<Confirmed>()),
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
    'a repository error during cancelling shows a failure',
    setUp: () => repository = InMemoryLessonRepository([confirmed]),
    build: buildBloc,
    seed: () => MyLessonsLoaded([LessonItem(lesson: confirmed, action: LessonAction.cancel)]),
    act: (bloc) {
      repository.fail = true;
      bloc.add(LessonCancelled(confirmed));
    },
    expect: () => [const MyLessonsFailure('Nema mreže')],
  );
}
