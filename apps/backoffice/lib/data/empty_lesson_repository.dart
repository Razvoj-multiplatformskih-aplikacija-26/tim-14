import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

// Za odbranu: u main.dart se FakeLessonRepository zameni ovim i vidi se prazan ekran. Ekrani se ne menjaju.
final class EmptyLessonRepository implements LessonRepository {
  const EmptyLessonRepository({this.delay = const Duration(milliseconds: 800)});

  final Duration delay;

  @override
  Future<List<Lesson>> lessonsOf(UserId student) async {
    await Future<void>.delayed(delay);
    return [];
  }

  @override
  Future<List<Lesson>> lessonsForSlot(SlotId slot) async => [];

  @override
  Future<List<Lesson>> lessonsOfProfessor(UserId professor) async {
    await Future<void>.delayed(delay);
    return [];
  }

  @override
  Future<Set<SlotId>> takenSlotsOf(UserId professor) async => {};

  @override
  Future<Lesson?> find(LessonId id) async => null;

  @override
  Future<LessonId> nextId() async => const LessonId('new-1');

  @override
  Future<Result<Lesson>> create(Lesson lesson) async => Success(lesson);

  @override
  Future<Result<Lesson>> save(Lesson lesson, {required LessonStatus from}) async => Success(lesson);

  @override
  Future<Result<Confirmation>> saveConfirmation(Confirmation confirmation) async => Success(confirmation);
}
