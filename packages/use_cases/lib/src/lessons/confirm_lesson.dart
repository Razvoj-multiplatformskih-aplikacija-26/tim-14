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

    // Jedan poziv za sve upise: na serveru potvrda i odbijanja idu u jednoj transakciji.
    // Vraćena lista odbijenih može biti kraća ako je neki učenik u međuvremenu povukao zahtev.
    if (result is Success<Confirmation>) {
      final confirmation = result.value;
      return _lessons.saveConfirmation(confirmation);
    }
    return result;
  }
}
