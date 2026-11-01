import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

// Za odbranu: u main.dart se FakeLessonRepository zameni ovim i vidi se prazan ekran.
class EmptyLessonRepository implements LessonRepository {
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
  Future<LessonId> nextId() async => const LessonId('new-1');

  @override
  Future<Lesson> save(Lesson lesson) async => lesson;
}
