import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  const pendingActions = [QueueAction.confirm, QueueAction.reject];
  const confirmedActions = [QueueAction.held, QueueAction.noShow];

  final held = lessonAt(
    now.subtract(const Duration(days: 7)),
    id: 'held',
    status: Held(at: now),
  );
  final first = lessonAt(now.add(const Duration(days: 2)), id: 'first');
  final second = lessonAt(now.add(const Duration(days: 3)), id: 'second');
  final confirmed = lessonAt(
    now.add(const Duration(days: 4)),
    id: 'confirmed',
    status: Confirmed(at: now),
  );

  late InMemoryLessonRepository repository;

  LessonQueueBloc buildBloc() => LessonQueueBloc(GetLessonQueue(repository, professor));

  blocTest<LessonQueueBloc, LessonQueueState>(
    'shows the queue sorted, with the first pending request selected',
    setUp: () => repository = InMemoryLessonRepository([second, held, confirmed, first]),
    build: buildBloc,
    act: (bloc) => bloc.add(QueueRequested()),
    expect: () => [
      const LessonQueueLoading(),
      LessonQueueLoaded(
        [
          QueueRow(lesson: held, actions: const []),
          QueueRow(lesson: first, actions: pendingActions),
          QueueRow(lesson: second, actions: pendingActions),
          QueueRow(lesson: confirmed, actions: confirmedActions),
        ],
        tab: QueueTab.pending,
        selectedId: first.id,
      ),
    ],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'is empty when there are no lessons',
    setUp: () => repository = InMemoryLessonRepository(),
    build: buildBloc,
    act: (bloc) => bloc.add(QueueRequested()),
    expect: () => [const LessonQueueLoading(), const LessonQueueEmpty()],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'shows a failure when the repository throws',
    setUp: () => repository = InMemoryLessonRepository([first])..fail = true,
    build: buildBloc,
    act: (bloc) => bloc.add(QueueRequested()),
    expect: () => [const LessonQueueLoading(), const LessonQueueFailure('Nema mreže')],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'retry after a failure loads the queue',
    setUp: () => repository = InMemoryLessonRepository([first]),
    build: buildBloc,
    seed: () => const LessonQueueFailure('Nema mreže'),
    act: (bloc) => bloc.add(QueueRetried()),
    expect: () => [
      const LessonQueueLoading(),
      LessonQueueLoaded(
        [QueueRow(lesson: first, actions: pendingActions)],
        tab: QueueTab.pending,
        selectedId: first.id,
      ),
    ],
  );
}
