import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  const milica = ProfessorProfile(id: UserId('milica'), fullName: 'Milica Jovanović', city: City.belgrade, bio: '');
  const nikola = ProfessorProfile(id: UserId('nikola'), fullName: 'Nikola Petrović', city: City.noviSad, bio: '');

  final mathListing = Listing(
    id: math,
    professorId: professor.id,
    subject: Subject.mathematics,
    level: Level.highSchool,
    city: City.belgrade,
    description: 'Matematika za srednju školu',
    price: Price.parse(2000).valueOrNull!,
    duration: LessonDuration.minutes60,
  );

  final inThreeDays = now.add(const Duration(days: 3));
  final inFourDays = now.add(const Duration(days: 4));

  test('GetProfessors returns every professor with their own listings', () async {
    final repository = InMemoryProfessorRepository(profiles: [milica, nikola], listings: [mathListing]);

    final page = await GetProfessors(repository)();

    expect(page.items.map((summary) => summary.profile), [milica, nikola]);
    expect(page.items[0].listings, [mathListing]);
    expect(page.items[1].listings, isEmpty);
    expect(page.nextOffset, isNull);
  });

  test('GetProfessors returns 20 per page, and the last page has no nextOffset', () async {
    final many = [
      for (var i = 0; i < 21; i++) ProfessorProfile(id: UserId('p-$i'), fullName: 'P $i', city: City.belgrade, bio: ''),
    ];
    final getProfessors = GetProfessors(InMemoryProfessorRepository(profiles: many));

    final first = await getProfessors();
    final second = await getProfessors(offset: first.nextOffset!);

    expect(first.items, hasLength(20));
    expect(first.nextOffset, 20);
    expect(second.items.single.profile, many.last);
    expect(second.nextOffset, isNull);
  });

  test('GetProfessors asks for the page at the given offset', () async {
    final repository = InMemoryProfessorRepository(profiles: [milica, nikola]);

    final page = await GetProfessors(repository)(offset: 1);

    expect(page.items.map((summary) => summary.profile), [nikola]);
  });

  test('lowestPrice is the price of the cheapest listing', () {
    final physicsListing = Listing(
      id: physics,
      professorId: professor.id,
      subject: Subject.physics,
      level: Level.highSchool,
      city: City.belgrade,
      description: 'Fizika za srednju školu',
      price: Price.parse(1800).valueOrNull!,
      duration: LessonDuration.minutes60,
    );

    expect(ProfessorSummary(profile: milica, listings: [mathListing, physicsListing]).lowestPrice?.dinars, 1800);
    expect(const ProfessorSummary(profile: nikola, listings: []).lowestPrice, isNull);
  });

  test('GetProfessorPage hides slots that already have a confirmed lesson', () async {
    final taken = slotAt(inThreeDays, id: 's-taken');
    final free = slotAt(inFourDays, id: 's-free');
    final professors = InMemoryProfessorRepository(profiles: [milica], listings: [mathListing], slots: [free, taken]);
    final lessons = InMemoryLessonRepository([
      lessonAt(
        inThreeDays,
        slotId: 's-taken',
        studentId: otherStudent.id,
        status: Confirmed(at: now),
      ),
    ]);

    final page = await GetProfessorPage(professors, lessons, FixedClock(now))(professor.id);

    expect(page.profile, milica);
    expect(page.listings, [mathListing]);
    expect(page.freeSlots, [free]);
  });

  test('freeSlotsOf returns only the slots of one listing', () async {
    final mathSlot = slotAt(inThreeDays, id: 's-math');
    final physicsSlot = slotAt(inFourDays, id: 's-physics', listingId: physics);
    final professors = InMemoryProfessorRepository(profiles: [milica], slots: [mathSlot, physicsSlot]);

    final page = await GetProfessorPage(professors, InMemoryLessonRepository(), FixedClock(now))(professor.id);

    expect(page.freeSlotsOf(math), [mathSlot]);
    expect(page.freeSlotsOf(physics), [physicsSlot]);
  });
}
