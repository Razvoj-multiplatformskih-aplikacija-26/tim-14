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
  Future<Set<SlotId>> takenSlotsOf(UserId professor) async {
    _failSwitch.check();
    return {
      for (final lesson in _lessons)
        if (lesson.professorId == professor && lesson.status is Confirmed) lesson.slotId,
    };
  }

  @override
  Future<Lesson?> find(LessonId id) async {
    _failSwitch.check();
    return _stored(id);
  }

  @override
  Future<LessonId> nextId() async {
    _failSwitch.check();
    _lastId++;
    return LessonId('new-$_lastId');
  }

  @override
  Future<Result<Lesson>> create(Lesson lesson) async {
    _failSwitch.check();
    _lessons.add(lesson);
    return Success(lesson);
  }

  // Kao baza na serveru: upis prolazi samo ako čas još ima status from. Inače ga je neko već promenio.
  @override
  Future<Result<Lesson>> save(Lesson lesson, {required LessonStatus from}) async {
    _failSwitch.check();
    final index = _lessons.indexWhere((other) => other.id == lesson.id);
    if (index == -1 || _lessons[index].status.runtimeType != from.runtimeType) {
      return const Failure(LessonChanged());
    }
    _lessons[index] = lesson;
    return Success(lesson);
  }

  // Kao transakcija na serveru: potvrda i odbijanja zajedno. Odbija samo zahteve koji još čekaju.
  @override
  Future<Result<Confirmation>> saveConfirmation(Confirmation confirmation) async {
    _failSwitch.check();
    final confirmed = confirmation.confirmed;
    if (_stored(confirmed.id)?.status is! Pending) {
      return const Failure(LessonChanged());
    }
    final slotTaken = _lessons.any(
      (other) => other.slotId == confirmed.slotId && other.id != confirmed.id && other.status is Confirmed,
    );
    if (slotTaken) {
      return const Failure(SlotTaken());
    }

    _replace(confirmed);
    final rejected = <Lesson>[];
    for (final other in confirmation.rejected) {
      if (_stored(other.id)?.status is Pending) {
        _replace(other);
        rejected.add(other);
      }
    }
    return Success(Confirmation(confirmed: confirmed, rejected: rejected));
  }

  Lesson? _stored(LessonId id) => _lessons.where((lesson) => lesson.id == id).firstOrNull;

  void _replace(Lesson lesson) {
    final index = _lessons.indexWhere((other) => other.id == lesson.id);
    _lessons[index] = lesson;
  }
}
