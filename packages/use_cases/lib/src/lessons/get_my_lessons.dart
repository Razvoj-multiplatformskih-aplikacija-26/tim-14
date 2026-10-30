import 'package:domain/domain.dart';

import '../ports/lesson_repository.dart';

final class GetMyLessons {
  GetMyLessons(this._lessons, this._me);

  final LessonRepository _lessons;
  final User _me;

  Future<List<Lesson>> call() async {
    final lessons = [...await _lessons.lessonsOf(_me.id)];
    lessons.sort((a, b) => a.start.compareTo(b.start));
    return lessons;
  }
}
