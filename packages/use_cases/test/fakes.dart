import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final now = DateTime.utc(2026, 11, 2, 10);

const student = User(id: UserId('ana'), name: 'Ana', role: Role.student);
const otherStudent = User(id: UserId('marko'), name: 'Marko', role: Role.student);
const professor = User(id: UserId('milica'), name: 'Milica', role: Role.professor);

const math = ListingId('l-math');
const physics = ListingId('l-physics');

final message = RequestMessage.parse('Treba mi pomoć oko integrala.').valueOrNull!;

Slot slotAt(DateTime start, {String id = 's-1', ListingId listingId = math}) => Slot(
  id: SlotId(id),
  listingId: listingId,
  professorId: professor.id,
  start: start,
  duration: LessonDuration.minutes60,
);

Lesson lessonAt(
  DateTime start, {
  String id = 'lesson-1',
  String slotId = 's-1',
  UserId? studentId,
  LessonStatus status = const Pending(),
}) => Lesson(
  id: LessonId(id),
  slotId: SlotId(slotId),
  listingId: math,
  professorId: professor.id,
  studentId: studentId ?? student.id,
  start: start,
  duration: LessonDuration.minutes60,
  message: message,
  createdAt: now.subtract(const Duration(days: 1)),
  status: status,
);

final class FixedClock implements Clock {
  FixedClock(this.time);

  final DateTime time;

  @override
  DateTime now() => time;
}

final class InMemoryLessonRepository implements LessonRepository {
  InMemoryLessonRepository([List<Lesson> lessons = const []]) : lessons = [...lessons];

  final List<Lesson> lessons;
  int saveCalls = 0;
  bool fail = false;
  int _nextId = 100;

  void _check() {
    if (fail) {
      throw const RepositoryException('Nema mreže');
    }
  }

  @override
  Future<List<Lesson>> lessonsOf(UserId student) async {
    _check();
    return lessons.where((lesson) => lesson.studentId == student).toList();
  }

  @override
  Future<List<Lesson>> lessonsForSlot(SlotId slot) async {
    _check();
    return lessons.where((lesson) => lesson.slotId == slot).toList();
  }

  @override
  Future<List<Lesson>> lessonsOfProfessor(UserId professor) async {
    _check();
    return lessons.where((lesson) => lesson.professorId == professor).toList();
  }

  @override
  Future<LessonId> nextId() async {
    _check();
    _nextId++;
    return LessonId('lesson-$_nextId');
  }

  @override
  Future<Lesson> save(Lesson lesson) async {
    _check();
    saveCalls++;
    lessons.removeWhere((other) => other.id == lesson.id);
    lessons.add(lesson);
    return lesson;
  }
}

final class InMemoryProfessorRepository implements ProfessorRepository {
  InMemoryProfessorRepository({required this.profiles, this.listings = const [], this.slots = const []});

  final List<ProfessorProfile> profiles;
  final List<Listing> listings;
  final List<Slot> slots;

  @override
  Future<List<ProfessorProfile>> professors() async => profiles;

  @override
  Future<ProfessorProfile> profile(UserId id) async {
    for (final profile in profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    throw RepositoryException('Nema profesora $id');
  }

  @override
  Future<List<Listing>> listingsOf(UserId professor) async =>
      listings.where((listing) => listing.professorId == professor).toList();

  @override
  Future<List<Slot>> slotsOf(UserId professor) async => slots.where((slot) => slot.professorId == professor).toList();
}
