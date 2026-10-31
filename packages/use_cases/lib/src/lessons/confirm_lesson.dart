import 'package:domain/domain.dart';

import '../clock.dart';
import '../ports/lesson_repository.dart';

final class ConfirmLesson {
  ConfirmLesson(this._lessons, this._clock, this._me);

  final LessonRepository _lessons;
  final Clock _clock;
  final User _me;

  Future<Result<Confirmation>> call(Lesson lesson) async {
    final result = confirmLesson(
      lesson,
      by: _me,
      competing: await _lessons.lessonsForSlot(lesson.slotId),
      now: _clock.now(),
    );

    if (result is Success<Confirmation>) {
      final confirmation = result.value;
      final confirmed = await _lessons.save(confirmation.confirmed);
      final rejected = <Lesson>[];
      for (final other in confirmation.rejected) {
        rejected.add(await _lessons.save(other));
      }
      return Success(Confirmation(confirmed: confirmed, rejected: rejected));
    }
    return result;
  }
}
