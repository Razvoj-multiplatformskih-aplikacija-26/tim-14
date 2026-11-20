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

  // Tri zahteva za isti termin i jedan za kasniji.
  final chosen = lessonAt(now.add(const Duration(days: 5)), id: 'chosen', slot: 'thu-17');
  final rivalA = lessonAt(now.add(const Duration(days: 5)), id: 'rival-a', slot: 'thu-17');
  final rivalB = lessonAt(now.add(const Duration(days: 5)), id: 'rival-b', slot: 'thu-17');
  final nextRequest = lessonAt(now.add(const Duration(days: 6)), id: 'next');

  late InMemoryLessonRepository repository;

  setUp(() => repository = InMemoryLessonRepository());

  LessonQueueBloc buildBloc() {
    final clock = FixedClock(now);
    return LessonQueueBloc(
      GetLessonQueue(repository, professor),
      ConfirmLesson(repository, clock, professor),
      RejectLesson(repository, clock, professor),
      RecordHeld(repository, clock, professor),
      RecordNoShow(repository, clock, professor),
    );
  }

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
    expect: () => [const LessonQueueLoading(), const LessonQueueFailure(RepositoryFailure.unavailable)],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'retry after a failure loads the queue',
    setUp: () => repository = InMemoryLessonRepository([first]),
    build: buildBloc,
    seed: () => const LessonQueueFailure(RepositoryFailure.unavailable),
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

  blocTest<LessonQueueBloc, LessonQueueState>(
    'confirming a request rejects the others for that slot and selects the next request',
    setUp: () => repository = InMemoryLessonRepository([chosen, rivalA, rivalB, nextRequest]),
    build: buildBloc,
    seed: () => LessonQueueLoaded(
      [
        QueueRow(lesson: chosen, actions: pendingActions),
        QueueRow(lesson: rivalA, actions: pendingActions),
        QueueRow(lesson: rivalB, actions: pendingActions),
        QueueRow(lesson: nextRequest, actions: pendingActions),
      ],
      tab: QueueTab.pending,
      selectedId: chosen.id,
    ),
    act: (bloc) => bloc.add(ConfirmPressed()),
    expect: () => [
      LessonQueueLoaded(
        [
          QueueRow(
            lesson: chosen.copyWith(status: Confirmed(at: now)),
            actions: confirmedActions,
          ),
          QueueRow(
            lesson: rivalA.copyWith(
              status: Rejected(cause: RejectionCause.slotTaken, at: now),
            ),
            actions: const [],
          ),
          QueueRow(
            lesson: rivalB.copyWith(
              status: Rejected(cause: RejectionCause.slotTaken, at: now),
            ),
            actions: const [],
          ),
          QueueRow(lesson: nextRequest, actions: pendingActions),
        ],
        tab: QueueTab.pending,
        selectedId: nextRequest.id,
      ),
    ],
    verify: (_) => expect(
      {for (final lesson in repository.lessons) lesson.id: lesson.status},
      {
        chosen.id: Confirmed(at: now),
        rivalA.id: Rejected(cause: RejectionCause.slotTaken, at: now),
        rivalB.id: Rejected(cause: RejectionCause.slotTaken, at: now),
        nextRequest.id: const Pending(),
      },
    ),
  );

  // Posle svakog odbijanja lista se tiho osveži. Ovde je u repozitorijumu samo potvrđeni čas.
  final reloadedConfirmed = [QueueRow(lesson: confirmed, actions: confirmedActions)];

  blocTest<LessonQueueBloc, LessonQueueState>(
    'marking a future lesson as held shows an error, then reloads',
    setUp: () => repository = InMemoryLessonRepository([confirmed]),
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.confirmed, selectedId: confirmed.id),
    act: (bloc) => bloc.add(HeldPressed()),
    expect: () => [
      LessonQueueLoaded(
        rows,
        tab: QueueTab.confirmed,
        selectedId: confirmed.id,
        notice: const ActionRejected(LessonNotStarted()),
      ),
      LessonQueueLoaded(reloadedConfirmed, tab: QueueTab.confirmed, selectedId: confirmed.id),
    ],
    verify: (_) => expect(repository.lessons.single.status, isA<Confirmed>()),
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'the same error shows again on the second press',
    setUp: () => repository = InMemoryLessonRepository([confirmed]),
    build: buildBloc,
    seed: () => LessonQueueLoaded(
      rows,
      tab: QueueTab.confirmed,
      selectedId: confirmed.id,
      notice: const ActionRejected(LessonNotStarted()),
    ),
    act: (bloc) => bloc.add(HeldPressed()),
    expect: () => [
      LessonQueueLoaded(rows, tab: QueueTab.confirmed, selectedId: confirmed.id),
      LessonQueueLoaded(
        rows,
        tab: QueueTab.confirmed,
        selectedId: confirmed.id,
        notice: const ActionRejected(LessonNotStarted()),
      ),
      LessonQueueLoaded(reloadedConfirmed, tab: QueueTab.confirmed, selectedId: confirmed.id),
    ],
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'a second action while the first one is saving is ignored',
    setUp: () => repository = InMemoryLessonRepository([held, first, second, confirmed]),
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
    act: (bloc) => bloc
      ..add(ConfirmPressed())
      ..add(RejectPressed()),
    expect: () => [
      LessonQueueLoaded(
        [
          QueueRow(lesson: held, actions: const []),
          QueueRow(
            lesson: first.copyWith(status: Confirmed(at: now)),
            actions: confirmedActions,
          ),
          QueueRow(lesson: second, actions: pendingActions),
          QueueRow(lesson: confirmed, actions: confirmedActions),
        ],
        tab: QueueTab.pending,
        selectedId: second.id,
      ),
    ],
    verify: (_) => expect(repository.lessons.firstWhere((lesson) => lesson.id == first.id).status, isA<Confirmed>()),
  );

  blocTest<LessonQueueBloc, LessonQueueState>(
    'a repository error during an action keeps the list and shows the failure',
    setUp: () => repository = InMemoryLessonRepository([first]),
    build: buildBloc,
    seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
    act: (bloc) {
      repository.fail = true;
      bloc.add(ConfirmPressed());
    },
    expect: () => [
      LessonQueueLoaded(
        rows,
        tab: QueueTab.pending,
        selectedId: first.id,
        notice: const ActionFailed(RepositoryFailure.unavailable),
      ),
    ],
  );

  group('late client', () {
    // Učenik je povukao zahtev, a profesor još gleda staru listu u kojoj je zahtev na čekanju.
    final withdrawn = first.copyWith(
      status: Cancelled(by: student.id, at: now),
    );

    blocTest<LessonQueueBloc, LessonQueueState>(
      'a refused action shows the reason, then reloads without a spinner',
      setUp: () => repository = InMemoryLessonRepository([held, withdrawn, second, confirmed]),
      build: buildBloc,
      seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
      act: (bloc) => bloc.add(ConfirmPressed()),
      expect: () => [
        LessonQueueLoaded(
          rows,
          tab: QueueTab.pending,
          selectedId: first.id,
          notice: const ActionRejected(LessonChanged()),
        ),
        // Povučen zahtev je sad u arhivi, pa izbor prelazi na red koji je na njegovom mestu.
        LessonQueueLoaded(
          [
            QueueRow(lesson: held, actions: const []),
            QueueRow(lesson: withdrawn, actions: const []),
            QueueRow(lesson: second, actions: pendingActions),
            QueueRow(lesson: confirmed, actions: confirmedActions),
          ],
          tab: QueueTab.pending,
          selectedId: second.id,
        ),
      ],
      verify: (_) => expect(repository.lessons.firstWhere((lesson) => lesson.id == first.id), withdrawn),
    );
  });

  group('refresh', () {
    blocTest<LessonQueueBloc, LessonQueueState>(
      'reloads without a spinner and keeps the selection',
      setUp: () => repository = InMemoryLessonRepository([held, first, second, confirmed, nextRequest]),
      build: buildBloc,
      seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: second.id),
      act: (bloc) => bloc.add(QueueRefreshed()),
      expect: () => [
        LessonQueueLoaded(
          [...rows, QueueRow(lesson: nextRequest, actions: pendingActions)],
          tab: QueueTab.pending,
          selectedId: second.id,
        ),
      ],
    );

    blocTest<LessonQueueBloc, LessonQueueState>(
      'a failed refresh keeps the list and shows the failure',
      setUp: () => repository = InMemoryLessonRepository([first])..fail = true,
      build: buildBloc,
      seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
      act: (bloc) => bloc.add(QueueRefreshed()),
      expect: () => [
        LessonQueueLoaded(
          rows,
          tab: QueueTab.pending,
          selectedId: first.id,
          notice: const ActionFailed(RepositoryFailure.unavailable),
        ),
      ],
    );

    // Ugašen server: umesto stare liste ekran „Nema veze sa serverom“. Pokušaj ponovo je test ispod.
    blocTest<LessonQueueBloc, LessonQueueState>(
      'a refresh that cannot reach the server shows the failure instead of the list',
      setUp: () => repository = InMemoryLessonRepository([first])
        ..fail = true
        ..failure = RepositoryFailure.unreachable,
      build: buildBloc,
      seed: () => LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: first.id),
      act: (bloc) => bloc.add(QueueRefreshed()),
      expect: () => [const LessonQueueFailure(RepositoryFailure.unreachable)],
    );

    blocTest<LessonQueueBloc, LessonQueueState>(
      'is ignored while the queue is loading',
      setUp: () => repository = InMemoryLessonRepository([first]),
      build: buildBloc,
      seed: () => const LessonQueueLoading(),
      act: (bloc) => bloc.add(QueueRefreshed()),
      expect: () => <LessonQueueState>[],
    );

    blocTest<LessonQueueBloc, LessonQueueState>(
      'after a failure loads normally, with a spinner',
      setUp: () => repository = InMemoryLessonRepository([first]),
      build: buildBloc,
      seed: () => const LessonQueueFailure(RepositoryFailure.unreachable),
      act: (bloc) => bloc.add(QueueRefreshed()),
      expect: () => [
        const LessonQueueLoading(),
        LessonQueueLoaded(
          [QueueRow(lesson: first, actions: pendingActions)],
          tab: QueueTab.pending,
          selectedId: first.id,
        ),
      ],
    );
  });
}
