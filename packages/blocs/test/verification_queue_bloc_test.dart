import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  final jelena = awaiting('jelena', submittedAt: now.subtract(const Duration(days: 3)));
  final petar = awaiting('petar', submittedAt: now.subtract(const Duration(days: 2)));
  final sara = awaiting('sara', submittedAt: now.subtract(const Duration(days: 1)));

  final reason = RejectionReason.parse('Diploma nije čitljiva.').valueOrNull!;

  late InMemoryVerificationRepository repository;

  setUp(() => repository = InMemoryVerificationRepository());

  VerificationQueueBloc buildBloc() {
    final clock = FixedClock(now);
    return VerificationQueueBloc(
      GetVerificationQueue(repository),
      VerifyProfessor(repository, clock, admin),
      RejectProfessor(repository, clock, admin),
    );
  }

  ProfessorProfile saved(ProfessorProfile profile) => repository.profiles.firstWhere((other) => other.id == profile.id);

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

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'verifying removes the profile and selects the next one',
    setUp: () => repository = InMemoryVerificationRepository([jelena, petar, sara]),
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
    act: (bloc) => bloc.add(VerifyPressed()),
    expect: () => [
      VerificationQueueLoaded([petar, sara], selectedId: petar.id),
    ],
    verify: (_) => expect(saved(jelena).verification, Verified(by: admin.id, at: now)),
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'deciding the last profile selects the one above',
    setUp: () => repository = InMemoryVerificationRepository([jelena, petar, sara]),
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: sara.id),
    act: (bloc) => bloc.add(VerifyPressed()),
    expect: () => [
      VerificationQueueLoaded([jelena, petar], selectedId: petar.id),
    ],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'deciding the only profile empties the queue',
    setUp: () => repository = InMemoryVerificationRepository([jelena]),
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena], selectedId: jelena.id),
    act: (bloc) => bloc.add(VerifyPressed()),
    expect: () => [const VerificationQueueEmpty()],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'rejecting with a reason saves it and removes the profile',
    setUp: () => repository = InMemoryVerificationRepository([jelena, petar, sara]),
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: petar.id),
    act: (bloc) => bloc.add(RejectProfessorPressed('Diploma nije čitljiva.')),
    expect: () => [
      VerificationQueueLoaded([jelena, sara], selectedId: sara.id),
    ],
    verify: (_) => expect(saved(petar).verification, VerificationRejected(by: admin.id, at: now, reason: reason)),
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'a too short reason shows an error and keeps the profile',
    setUp: () => repository = InMemoryVerificationRepository([jelena, petar, sara]),
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
    act: (bloc) => bloc.add(RejectProfessorPressed('Ne.')),
    expect: () => [
      VerificationQueueLoaded(
        [jelena, petar, sara],
        selectedId: jelena.id,
        actionError: const RejectionReasonTooShort(3),
      ),
    ],
    verify: (_) => expect(repository.profiles, [jelena, petar, sara]),
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'the same error shows again on the second press',
    setUp: () => repository = InMemoryVerificationRepository([jelena, petar, sara]),
    build: buildBloc,
    seed: () => VerificationQueueLoaded(
      [jelena, petar, sara],
      selectedId: jelena.id,
      actionError: const RejectionReasonTooShort(3),
    ),
    act: (bloc) => bloc.add(RejectProfessorPressed('Ne.')),
    expect: () => [
      VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
      VerificationQueueLoaded(
        [jelena, petar, sara],
        selectedId: jelena.id,
        actionError: const RejectionReasonTooShort(3),
      ),
    ],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'a second decision while the first one is saving is ignored',
    setUp: () => repository = InMemoryVerificationRepository([jelena, petar, sara])..gate = Completer(),
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
    act: (bloc) async {
      bloc
        ..add(VerifyPressed())
        ..add(RejectProfessorPressed('Diploma nije čitljiva.'));
      // Prvo čuvanje pustimo tek kad su oba pritiska stigla do Bloca.
      await Future<void>.delayed(Duration.zero);
      repository.gate!.complete();
    },
    expect: () => [
      VerificationQueueLoaded([petar, sara], selectedId: petar.id),
    ],
    verify: (_) {
      expect(saved(jelena).verification, Verified(by: admin.id, at: now));
      expect(saved(petar), petar);
    },
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'a profile picked while saving stays selected',
    setUp: () => repository = InMemoryVerificationRepository([jelena, petar, sara])..gate = Completer(),
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena, petar, sara], selectedId: jelena.id),
    act: (bloc) async {
      bloc
        ..add(VerifyPressed())
        ..add(ProfileSelected(sara.id));
      await Future<void>.delayed(Duration.zero);
      repository.gate!.complete();
    },
    expect: () => [
      VerificationQueueLoaded([jelena, petar, sara], selectedId: sara.id),
      VerificationQueueLoaded([petar, sara], selectedId: sara.id),
    ],
  );

  blocTest<VerificationQueueBloc, VerificationQueueState>(
    'a repository error during a decision shows a failure',
    setUp: () => repository = InMemoryVerificationRepository([jelena]),
    build: buildBloc,
    seed: () => VerificationQueueLoaded([jelena], selectedId: jelena.id),
    act: (bloc) {
      repository.fail = true;
      bloc.add(VerifyPressed());
    },
    expect: () => [const VerificationQueueFailure('Nema mreže')],
  );
}
