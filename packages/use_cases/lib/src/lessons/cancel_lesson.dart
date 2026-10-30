import 'package:domain/domain.dart';

import '../clock.dart';
import '../ports/lesson_repository.dart';

final class CancelLesson {
  CancelLesson(this._lessons, this._clock, this._me);

  final LessonRepository _lessons;
  final Clock _clock;
  final User _me;

  Future<Result<Lesson>> call(Lesson lesson) async {
    final result = cancelLesson(lesson, by: _me, now: _clock.now());

    if (result case Success(:final value)) {
      return Success(await _lessons.save(value));
    }
    return result;
  }
}
