import 'package:domain/domain.dart';
import 'package:server/src/http.dart' show RecordNotFound;
import 'package:use_cases/use_cases.dart';

/// Repositories in memory, for endpoint tests that run without a database (and so also in CI). They keep the
/// promises of the Postgres ones that the handlers rely on: an unknown professor throws [RecordNotFound], and a
/// save whose `from` is no longer the stored status changes nothing.

final class MemoryProfessors implements ProfessorRepository {
  MemoryProfessors(this.profiles, {this.listings = const [], this.slots = const []});

  /// In name order, like the Postgres repository.
  final List<ProfessorProfile> profiles;
  final List<Listing> listings;
  final List<Slot> slots;

  @override
  Future<ProfessorsPage> professors({int offset = 0, int limit = 20}) async {
    final page = profiles.skip(offset).take(limit).toList();
    return ProfessorsPage(
      items: [for (final profile in page) ProfessorSummary(profile: profile, listings: await listingsOf(profile.id))],
      nextOffset: offset + limit < profiles.length ? offset + limit : null,
    );
  }

  @override
  Future<ProfessorProfile> profile(UserId id) async =>
      profiles.where((profile) => profile.id == id).firstOrNull ?? (throw RecordNotFound('No professor $id'));

  @override
  Future<List<Listing>> listingsOf(UserId professor) async => [
    for (final listing in listings)
      if (listing.professorId == professor) listing,
  ];

  @override
  Future<List<Slot>> slotsOf(UserId professor) async => [
    for (final slot in slots)
      if (slot.professorId == professor) slot,
  ];

  @override
  Future<Slot?> findSlot(SlotId id) async => slots.where((slot) => slot.id == id).firstOrNull;
}

final class MemoryLessons implements LessonRepository {
  MemoryLessons([List<Lesson> lessons = const []]) : lessons = [...lessons];

  final List<Lesson> lessons;
  var _nextId = 0;

  Lesson? stored(LessonId id) => lessons.where((lesson) => lesson.id == id).firstOrNull;

  void _put(Lesson lesson) {
    lessons.removeWhere((other) => other.id == lesson.id);
    lessons.add(lesson);
  }

  @override
  Future<List<Lesson>> lessonsOf(UserId student) async => [
    for (final lesson in lessons)
      if (lesson.studentId == student) lesson,
  ];

  @override
  Future<List<Lesson>> lessonsOfProfessor(UserId professor) async => [
    for (final lesson in lessons)
      if (lesson.professorId == professor) lesson,
  ];

  @override
  Future<List<Lesson>> lessonsForSlot(SlotId slot) async => [
    for (final lesson in lessons)
      if (lesson.slotId == slot) lesson,
  ];

  @override
  Future<Set<SlotId>> takenSlotsOf(UserId professor) async => takenSlots(await lessonsOfProfessor(professor));

  @override
  Future<Lesson?> find(LessonId id) async => stored(id);

  @override
  Future<LessonId> nextId() async => LessonId('new-${++_nextId}');

  @override
  Future<Result<Lesson>> create(Lesson lesson) async {
    _put(lesson);
    return Success(lesson);
  }

  /// Like `UPDATE … WHERE status = @from`: if the stored lesson no longer has that status, nothing is written.
  @override
  Future<Result<Lesson>> save(Lesson lesson, {required LessonStatus from}) async {
    if (stored(lesson.id)?.status.runtimeType != from.runtimeType) {
      return const Failure(LessonChanged());
    }
    _put(lesson);
    return Success(lesson);
  }

  @override
  Future<Result<Confirmation>> saveConfirmation(Confirmation confirmation) =>
      throw StateError('The student endpoints never confirm');
}
