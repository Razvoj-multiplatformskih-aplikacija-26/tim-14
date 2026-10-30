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

  test('GetProfessors returns all professors', () async {
    final repository = InMemoryProfessorRepository(profiles: [milica, nikola]);

    expect(await GetProfessors(repository)(), [milica, nikola]);
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
