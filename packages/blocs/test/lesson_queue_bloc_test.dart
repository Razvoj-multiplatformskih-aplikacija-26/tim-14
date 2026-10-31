import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
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

  final rows = [
    QueueRow(lesson: held, actions: const []),
    QueueRow(lesson: first, actions: pendingActions),
    QueueRow(lesson: second, actions: pendingActions),
    QueueRow(lesson: confirmed, actions: confirmedActions),
  ];

  late InMemoryLessonRepository repository;

  setUp(() => repository = InMemoryLessonRepository());

  LessonQueueBloc buildBloc() => LessonQueueBloc(GetLessonQueue(repository, professor));

  blocTest<LessonQueueBloc, LessonQueueState>(
    'shows the queue sorted, with the first pending request selected',
    setUp: () => repository = InMemoryLessonRepository([second, held, confirmed, first]),
    build: buildBloc,
    act: (bloc) => bloc.add(QueueRequested()),
    expect: () => [const LessonQueueLoading(), LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id)],
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

  blocTest<LessonQueueBloc, LessonQueueState>(
    'moving down selects the next row',
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
    act: (bloc) => bloc.add(SelectionMoved(1)),
    expect: () => [LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: second.id)],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'moving up on the first row stays there',
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
    act: (bloc) => bloc.add(SelectionMoved(-1)),
    expect: () => <LessonQueueState>[],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'moving down on the last row stays there',
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: second.id),
    act: (bloc) => bloc.add(SelectionMoved(1)),
    expect: () => <LessonQueueState>[],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'clicking a row selects it',
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
    act: (bloc) => bloc.add(RowSelected(second.id)),
    expect: () => [LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: second.id)],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'changing the tab shows its rows and selects the first one',
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
    act: (bloc) => bloc.add(TabChanged(QueueTab.confirmed)),
    expect: () => [LessonQueueLoaded(rows, tab: QueueTab.confirmed, selectedId: confirmed.id)],
    verify: (bloc) {
      final state = bloc.state as LessonQueueLoaded;
      expect(state.visibleRows, [QueueRow(lesson: confirmed, actions: confirmedActions)]);
    },
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'changing to an empty tab selects nothing',
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
    act: (bloc) => bloc.add(TabChanged(QueueTab.archive)),
    expect: () => [LessonQueueLoaded(rows, tab: QueueTab.archive)],
  );
}
