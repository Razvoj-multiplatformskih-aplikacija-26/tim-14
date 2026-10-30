import 'package:domain/domain.dart';

import '../clock.dart';
import '../ports/lesson_repository.dart';

final class RequestLesson {
  RequestLesson(this._lessons, this._clock, this._me);

  final LessonRepository _lessons;
  final Clock _clock;
  final User _me;

  Future<Result<Lesson>> call({required Slot slot, required String text}) async {
    final message = RequestMessage.parse(text);
    if (message case Failure(:final error)) {
      return Failure(error);
    }

    final result = requestLesson(
      id: await _lessons.nextId(),
      slot: slot,
      by: _me,
      message: message.valueOrNull!,
      studentLessons: await _lessons.lessonsOf(_me.id),
      slotLessons: await _lessons.lessonsForSlot(slot.id),
      now: _clock.now(),
    );

    if (result case Success(:final value)) {
      return Success(await _lessons.save(value));
    }
    return result;
  }
}
