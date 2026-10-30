import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

import 'fakes.dart';

void main() {
  test('returns only my lessons, sorted by start', () async {
    final later = lessonAt(now.add(const Duration(days: 5)), id: 'later');
    final sooner = lessonAt(now.add(const Duration(days: 1)), id: 'sooner');
    final notMine = lessonAt(now.add(const Duration(days: 2)), id: 'not-mine', studentId: otherStudent.id);
    final repository = InMemoryLessonRepository([later, notMine, sooner]);

    final lessons = await GetMyLessons(repository, student)();

    expect(lessons, [sooner, later]);
  });

  test('returns an empty list when I have no lessons', () async {
    final lessons = await GetMyLessons(InMemoryLessonRepository(), student)();

    expect(lessons, isEmpty);
  });

  test('a repository error is passed on', () async {
    final repository = InMemoryLessonRepository()..fail = true;

    expect(() => GetMyLessons(repository, student)(), throwsA(isA<RepositoryException>()));
  });
}
