import 'package:bloc_test/bloc_test.dart';
import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  const milica = ProfessorProfile(id: UserId('milica'), fullName: 'Milica Jovanović', city: City.belgrade, bio: '');

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

  Slot slotAt(DateTime start, String id) => Slot(
    id: SlotId(id),
    listingId: mathListing.id,
    professorId: milica.id,
    start: start,
    duration: LessonDuration.minutes60,
  );

  final freeSlot = slotAt(now.add(const Duration(days: 2)), 's-free');
  final takenSlot = slotAt(now.add(const Duration(days: 3)), 's-taken');
  final pastSlot = slotAt(now.subtract(const Duration(days: 1)), 's-past');

  late InMemoryProfessorRepository professors;
  late InMemoryLessonRepository lessons;

  ProfessorPageBloc buildBloc() => ProfessorPageBloc(GetProfessorPage(professors, lessons, FixedClock(now)), milica.id);

  setUp(() {
    professors = InMemoryProfessorRepository(
      profiles: [milica],
      listings: [mathListing],
      slots: [freeSlot, takenSlot, pastSlot],
    );
    // Čas u takenSlot je potvrđen, pa taj termin više nije slobodan.
    lessons = InMemoryLessonRepository([
      lessonAt(
        takenSlot.start,
        id: 'c-1',
        slot: 's-taken',
        status: Confirmed(at: now),
      ),
    ]);
  });

  blocTest<ProfessorPageBloc, ProfessorPageState>(
    'shows the profile, listings and only the free slots',
    build: buildBloc,
    act: (bloc) => bloc.add(ProfessorPageRequested()),
    expect: () => [
      const ProfessorPageLoading(),
      isA<ProfessorPageLoaded>()
          .having((state) => state.page.profile, 'profile', milica)
          .having((state) => state.page.listings, 'listings', [mathListing])
          .having((state) => state.page.freeSlots, 'free slots', [freeSlot]),
    ],
  );

  blocTest<ProfessorPageBloc, ProfessorPageState>(
    'shows a failure when the repository throws',
    build: () {
      professors.fail = true;
      return buildBloc();
    },
    act: (bloc) => bloc.add(ProfessorPageRequested()),
    expect: () => [const ProfessorPageLoading(), const ProfessorPageFailure('Nema mreže')],
  );

  blocTest<ProfessorPageBloc, ProfessorPageState>(
    'retry after a failure loads the page',
    build: buildBloc,
    seed: () => const ProfessorPageFailure('Nema mreže'),
    act: (bloc) => bloc.add(ProfessorPageRetried()),
    expect: () => [const ProfessorPageLoading(), isA<ProfessorPageLoaded>()],
  );
}
