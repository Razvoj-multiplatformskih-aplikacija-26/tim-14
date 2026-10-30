import 'package:domain/domain.dart';

abstract interface class LessonRepository {
  Future<List<Lesson>> lessonsOf(UserId student);

  Future<List<Lesson>> lessonsForSlot(SlotId slot);

  Future<List<Lesson>> lessonsOfProfessor(UserId professor);

  Future<LessonId> nextId();

  Future<Lesson> save(Lesson lesson);
}
