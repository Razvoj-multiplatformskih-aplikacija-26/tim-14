import 'package:domain/domain.dart';

import '../clock.dart';
import '../ports/lesson_repository.dart';
import '../ports/professor_repository.dart';

final class RequestLesson {
  RequestLesson(this._lessons, this._professors, this._clock, this._me);

  final LessonRepository _lessons;
  final ProfessorRepository _professors;
  final Clock _clock;
  final User _me;

  Future<Result<Lesson>> call({required Slot slot, required String text}) async {
    final message = RequestMessage.parse(text);
    if (message case Failure(:final error)) {
      return Failure(error);
    }

    // Ime profesora se čita iz repozitorijuma, a ne od pozivaoca. Na serveru to znači iz baze,
    // pa klijent ne može da podmetne drugo ime na čas.
    final professor = await _professors.profile(slot.professorId);

    final result = requestLesson(
      id: await _lessons.nextId(),
      slot: slot,
      professorName: professor.fullName,
      by: _me,
      message: message.valueOrNull!,
      studentLessons: await _lessons.lessonsOf(_me.id),
      slotLessons: await _lessons.lessonsForSlot(slot.id),
      now: _clock.now(),
    );

    if (result case Success(:final value)) {
      return _lessons.create(value);
    }
    return result;
  }
}
