import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  const milica = ProfessorProfile(id: UserId('milica'), fullName: 'Milica Jovanović', city: City.belgrade, bio: '');
  const nikola = ProfessorProfile(id: UserId('nikola'), fullName: 'Nikola Petrović', city: City.noviSad, bio: '');

  final mathListing = Listing(
    id: const ListingId('l-math'),
    professorId: milica.id,
    subject: Subject.mathematics,
    level: Level.highSchool,
    city: City.belgrade,
    description: 'Matematika za srednju školu',
    price: Price.parse(2000).valueOrNull!,
    duration: LessonDuration.minutes60,
  );

  late InMemoryProfessorRepository repository;

  ProfessorsBloc buildBloc() => ProfessorsBloc(GetProfessors(repository));

  blocTest<ProfessorsBloc, ProfessorsState>(
    'shows the professors with their listings',
    setUp: () => repository = InMemoryProfessorRepository(profiles: [milica, nikola], listings: [mathListing]),
    build: buildBloc,
    act: (bloc) => bloc.add(ProfessorsRequested()),
    expect: () => [
      const ProfessorsLoading(),
      isA<ProfessorsLoaded>()
          .having((state) => state.professors.map((p) => p.profile), 'profiles', [milica, nikola])
          .having((state) => state.professors.first.listings, 'listings of Milica', [mathListing]),
    ],
  );

  blocTest<ProfessorsBloc, ProfessorsState>(
    'is empty when there are no professors',
    setUp: () => repository = InMemoryProfessorRepository(),
    build: buildBloc,
    act: (bloc) => bloc.add(ProfessorsRequested()),
    expect: () => [const ProfessorsLoading(), const ProfessorsEmpty()],
  );

  blocTest<ProfessorsBloc, ProfessorsState>(
    'shows a failure when the repository throws',
    setUp: () => repository = InMemoryProfessorRepository(profiles: [milica])..fail = true,
    build: buildBloc,
    act: (bloc) => bloc.add(ProfessorsRequested()),
    expect: () => [const ProfessorsLoading(), const ProfessorsFailure(RepositoryFailure.unavailable)],
  );

  blocTest<ProfessorsBloc, ProfessorsState>(
    'retry after a failure loads the professors',
    setUp: () => repository = InMemoryProfessorRepository(profiles: [milica]),
    build: buildBloc,
    seed: () => const ProfessorsFailure(RepositoryFailure.unavailable),
    act: (bloc) => bloc.add(ProfessorsRetried()),
    expect: () => [const ProfessorsLoading(), isA<ProfessorsLoaded>()],
  );

  group('pages', () {
    // 25 profesora: prva strana ima 20, druga 5 i nema sledeće.
    final many = [
      for (var i = 0; i < 25; i++)
        ProfessorProfile(id: UserId('p-$i'), fullName: 'Profesor $i', city: City.belgrade, bio: ''),
    ];

    List<UserId> idsOf(ProfessorsState state) => [
      for (final item in (state as ProfessorsLoaded).professors) item.profile.id,
    ];

    blocTest<ProfessorsBloc, ProfessorsState>(
      'the first page says where the next one starts',
      setUp: () => repository = InMemoryProfessorRepository(profiles: many),
      build: buildBloc,
      act: (bloc) => bloc.add(ProfessorsRequested()),
      expect: () => [
        const ProfessorsLoading(),
        isA<ProfessorsLoaded>()
            .having((state) => state.professors, 'professors', hasLength(20))
            .having((state) => state.nextOffset, 'nextOffset', 20),
      ],
    );

    blocTest<ProfessorsBloc, ProfessorsState>(
      'the second page is added after the first, and the last one has no next offset',
      setUp: () => repository = InMemoryProfessorRepository(profiles: many),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(ProfessorsRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(ProfessorsNextPageRequested());
      },
      skip: 1,
      expect: () => [
        isA<ProfessorsLoaded>().having((state) => state.loadingMore, 'loadingMore', false),
        isA<ProfessorsLoaded>().having((state) => state.loadingMore, 'loadingMore', true),
        isA<ProfessorsLoaded>()
            .having(idsOf, 'ids', [for (final profile in many) profile.id])
            .having((state) => state.nextOffset, 'nextOffset', isNull)
            .having((state) => state.hasMore, 'hasMore', false),
      ],
    );

    blocTest<ProfessorsBloc, ProfessorsState>(
      'reaching the end twice while a page loads asks for it only once',
      setUp: () => repository = InMemoryProfessorRepository(profiles: many),
      build: buildBloc,
      seed: () => ProfessorsLoaded(const [], nextOffset: 20),
      act: (bloc) => bloc
        ..add(ProfessorsNextPageRequested())
        ..add(ProfessorsNextPageRequested()),
      expect: () => [
        isA<ProfessorsLoaded>().having((state) => state.loadingMore, 'loadingMore', true),
        isA<ProfessorsLoaded>().having((state) => state.professors, 'professors', hasLength(5)),
      ],
    );

    blocTest<ProfessorsBloc, ProfessorsState>(
      'on the last page the end of the list asks for nothing',
      setUp: () => repository = InMemoryProfessorRepository(profiles: many),
      build: buildBloc,
      seed: () => const ProfessorsLoaded([]),
      act: (bloc) => bloc.add(ProfessorsNextPageRequested()),
      expect: () => <ProfessorsState>[],
    );

    blocTest<ProfessorsBloc, ProfessorsState>(
      'a next page that cannot be loaded keeps the list and says so at its end',
      setUp: () => repository = InMemoryProfessorRepository(profiles: many)..fail = true,
      build: buildBloc,
      seed: () => ProfessorsLoaded(const [], nextOffset: 20),
      act: (bloc) => bloc.add(ProfessorsNextPageRequested()),
      expect: () => [
        ProfessorsLoaded(const [], nextOffset: 20, loadingMore: true),
        ProfessorsLoaded(const [], nextOffset: 20, moreFailure: RepositoryFailure.unavailable),
      ],
    );

    blocTest<ProfessorsBloc, ProfessorsState>(
      'refreshing starts again from the first page, quietly',
      setUp: () => repository = InMemoryProfessorRepository(profiles: many),
      build: buildBloc,
      seed: () => const ProfessorsLoaded([]),
      act: (bloc) => bloc.add(ProfessorsRefreshed()),
      expect: () => [
        isA<ProfessorsLoaded>()
            .having((state) => state.professors, 'professors', hasLength(20))
            .having((state) => state.nextOffset, 'nextOffset', 20),
      ],
    );

    late Completer<void> done;

    blocTest<ProfessorsBloc, ProfessorsState>(
      'a refresh that cannot reach the server keeps the list, says why, and is still done',
      setUp: () {
        repository = InMemoryProfessorRepository(profiles: many)..fail = true;
        done = Completer<void>();
      },
      build: buildBloc,
      seed: () => ProfessorsLoaded(const [], nextOffset: 20),
      act: (bloc) => bloc.add(ProfessorsRefreshed(done: done)),
      expect: () => [ProfessorsLoaded(const [], nextOffset: 20, refreshFailure: RepositoryFailure.unavailable)],
      verify: (_) => expect(done.isCompleted, isTrue),
    );
  });
}
