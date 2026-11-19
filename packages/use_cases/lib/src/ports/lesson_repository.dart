import 'package:domain/domain.dart';

abstract interface class LessonRepository {
  Future<List<Lesson>> lessonsOf(UserId student);

  Future<List<Lesson>> lessonsForSlot(SlotId slot);

  Future<List<Lesson>> lessonsOfProfessor(UserId professor);

  // Samo koji termini profesora već imaju potvrđen čas. Ne otkriva tuđe zahteve ni poruke.
  Future<Set<SlotId>> takenSlotsOf(UserId professor);

  Future<Lesson?> find(LessonId id);

  Future<LessonId> nextId();

  Future<Result<Lesson>> create(Lesson lesson);

  // from je status koji pozivalac misli da čas sada ima. Ako ga je u međuvremenu neko promenio,
  // upis ne prolazi: Failure(LessonChanged()). Na serveru je to UPDATE … WHERE status = from.
  Future<Result<Lesson>> save(Lesson lesson, {required LessonStatus from});

  // Potvrda i automatska odbijanja odjednom. Na serveru je to jedna transakcija.
  Future<Result<Confirmation>> saveConfirmation(Confirmation confirmation);
}
