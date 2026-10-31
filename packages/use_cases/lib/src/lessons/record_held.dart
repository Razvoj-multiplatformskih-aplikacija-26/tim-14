import 'package:domain/domain.dart';

import '../clock.dart';
import '../ports/lesson_repository.dart';

final class RecordHeld {
  RecordHeld(this._lessons, this._clock, this._me);

  final LessonRepository _lessons;
  final Clock _clock;
  final User _me;

  Future<Result<Lesson>> call(Lesson lesson, {LessonNote? note}) async {
    final result = recordHeld(lesson, by: _me, now: _clock.now(), note: note);

    if (result is Success<Lesson>) {
      final value = result.value;
      return Success(await _lessons.save(value));
    }
    return result;
  }
}
