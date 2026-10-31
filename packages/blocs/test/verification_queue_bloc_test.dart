import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  final jelena = awaiting('jelena', submittedAt: now.subtract(const Duration(days: 3)));
  final petar = awaiting('petar', submittedAt: now.subtract(const Duration(days: 2)));
  final sara = awaiting('sara', submittedAt: now.subtract(const Duration(days: 1)));

  late InMemoryVerificationRepository repository;

  setUp(() => repository = InMemoryVerificationRepository());

  VerificationQueueBloc buildBloc() => VerificationQueueBloc(GetVerificationQueue(repository));

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'shows the queue oldest first, with the first profile selected',
    setUp: () => repository = InMemoryVerificationRepository([sara, jelena, petar]),
    build: buildBloc,
    act: (bloc) => bloc.add(VerificationRequested()),
    expect: () => [
      const VerificationQueueLoading(),
      VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
    ],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'is empty when no profile is waiting',
    build: buildBloc,
    act: (bloc) => bloc.add(VerificationRequested()),
    expect: () => [const VerificationQueueLoading(), const VerificationQueueEmpty()],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'shows a failure when the repository throws',
    setUp: () => repository = InMemoryVerificationRepository([jelena])..fail = true,
    build: buildBloc,
    act: (bloc) => bloc.add(VerificationRequested()),
    expect: () => [const VerificationQueueLoading(), const VerificationQueueFailure('Nema mreže')],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'retry after a failure loads the queue',
    setUp: () => repository = InMemoryVerificationRepository([jelena]),
    build: buildBloc,
    seed: () => const VerificationQueueFailure('Nema mreže'),
    act: (bloc) => bloc.add(VerificationRetried()),
    expect: () => [
      const VerificationQueueLoading(),
      VerificationQueueLoaded([jelena], selectedId: jelena.id),
    ],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'moving down selects the next profile',
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
    act: (bloc) => bloc.add(ProfileSelectionMoved(1)),
    expect: () => [
      VerificationQueueLoaded([jelena, petar, sara], selectedId: petar.id),
    ],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'moving up on the first profile stays there',
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
    act: (bloc) => bloc.add(ProfileSelectionMoved(-1)),
    expect: () => <VerificationQueueState>[],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'moving down on the last profile stays there',
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: sara.id),
    act: (bloc) => bloc.add(ProfileSelectionMoved(1)),
    expect: () => <VerificationQueueState>[],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'clicking a profile selects it',
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
    act: (bloc) => bloc.add(ProfileSelected(sara.id)),
    expect: () => [
      VerificationQueueLoaded([jelena, petar, sara], selectedId: sara.id),
    ],
  );
}
