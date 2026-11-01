import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'fail_switch.dart';

class FakeLessonRepository implements LessonRepository {
  FakeLessonRepository(List<Lesson> lessons, this._failSwitch, {this.delay = const Duration(milliseconds: 800)})
    : _lessons = [...lessons];

  final List<Lesson> _lessons;
  final FailSwitch _failSwitch;
  final Duration delay;
  int _lastId = 0;

  // Kasni samo učitavanje liste, da se na ekranu vidi da se učitava.
  Future<void> _load() async {
    await Future<void>.delayed(delay);
    _failSwitch.check();
  }

  @override
  Future<List<Lesson>> lessonsOf(UserId student) async {
    await _load();
    return _lessons.where((lesson) => lesson.studentId == student).toList();
  }

  @override
  Future<List<Lesson>> lessonsForSlot(SlotId slot) async {
    _failSwitch.check();
    return _lessons.where((lesson) => lesson.slotId == slot).toList();
  }

  @override
  Future<List<Lesson>> lessonsOfProfessor(UserId professor) async {
    await _load();
    return _lessons.where((lesson) => lesson.professorId == professor).toList();
  }

  @override
  Future<LessonId> nextId() async {
    _failSwitch.check();
    _lastId++;
    return LessonId('new-$_lastId');
  }

  @override
  Future<Lesson> save(Lesson lesson) async {
    _failSwitch.check();
    _lessons.removeWhere((other) => other.id == lesson.id);
    _lessons.add(lesson);
    return lesson;
  }
}
