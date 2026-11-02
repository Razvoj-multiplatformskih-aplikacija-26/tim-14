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
    expect: () => [const ProfessorsLoading(), const ProfessorsFailure('Nema mreže')],
  );

  blocTest<ProfessorsBloc, ProfessorsState>(
    'retry after a failure loads the professors',
    setUp: () => repository = InMemoryProfessorRepository(profiles: [milica]),
    build: buildBloc,
    seed: () => const ProfessorsFailure('Nema mreže'),
    act: (bloc) => bloc.add(ProfessorsRetried()),
    expect: () => [const ProfessorsLoading(), isA<ProfessorsLoaded>()],
  );
}
