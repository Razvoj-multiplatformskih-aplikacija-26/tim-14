import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final now = DateTime.utc(2026, 11, 2, 10);

const student = User(id: UserId('ana'), name: 'Ana', role: Role.student);
const professor = User(id: UserId('milica'), name: 'Milica', role: Role.professor);

final message = RequestMessage.parse('Treba mi pomoć oko integrala.').valueOrNull!;

Lesson lessonAt(DateTime start, {required String id, LessonStatus status = const Pending()}) => Lesson(
  id: LessonId(id),
  slotId: SlotId('s-$id'),
  listingId: const ListingId('l-math'),
  professorId: professor.id,
  studentId: student.id,
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
  bool fail = false;

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
  Future<LessonId> nextId() async => LessonId('lesson-${lessons.length + 1}');

  @override
  Future<Lesson> save(Lesson lesson) async {
    _check();
    lessons.removeWhere((other) => other.id == lesson.id);
    lessons.add(lesson);
    return lesson;
  }
}
