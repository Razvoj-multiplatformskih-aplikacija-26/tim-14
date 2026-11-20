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
    expect: () => [const ProfessorPageLoading(), const ProfessorPageFailure(RepositoryFailure.unavailable)],
  );

  blocTest<ProfessorPageBloc, ProfessorPageState>(
    'retry after a failure loads the page',
    build: buildBloc,
    seed: () => const ProfessorPageFailure(RepositoryFailure.unavailable),
    act: (bloc) => bloc.add(ProfessorPageRetried()),
    expect: () => [const ProfessorPageLoading(), isA<ProfessorPageLoaded>()],
  );

  // Dok je profil bio otvoren, profesor je potvrdio tuđi zahtev za slobodan termin.
  blocTest<ProfessorPageBloc, ProfessorPageState>(
    'refreshing reloads quietly and drops a slot that was taken meanwhile',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(ProfessorPageRequested());
      await Future<void>.delayed(Duration.zero);
      lessons.lessons.add(
        lessonAt(
          freeSlot.start,
          id: 'c-2',
          slot: 's-free',
          status: Confirmed(at: now),
        ),
      );
      bloc.add(ProfessorPageRefreshed());
    },
    expect: () => [
      const ProfessorPageLoading(),
      isA<ProfessorPageLoaded>().having((state) => state.page.freeSlots, 'free slots', [freeSlot]),
      isA<ProfessorPageLoaded>().having((state) => state.page.freeSlots, 'free slots after refresh', isEmpty),
    ],
  );

  blocTest<ProfessorPageBloc, ProfessorPageState>(
    'a refresh that cannot reach the server keeps the page and says why',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(ProfessorPageRequested());
      await Future<void>.delayed(Duration.zero);
      professors.fail = true;
      bloc.add(ProfessorPageRefreshed());
    },
    expect: () => [
      const ProfessorPageLoading(),
      isA<ProfessorPageLoaded>().having((state) => state.refreshFailure, 'refreshFailure', isNull),
      isA<ProfessorPageLoaded>()
          .having((state) => state.page.freeSlots, 'free slots', [freeSlot])
          .having((state) => state.refreshFailure, 'refreshFailure', RepositoryFailure.unavailable),
    ],
  );
}
