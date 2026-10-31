import 'package:domain/domain.dart';

sealed class MyLessonsEvent {}

// Ekran "Moji časovi" je otvoren.
class MyLessonsRequested extends MyLessonsEvent {}

// Korisnik je kliknuo "Pokušaj ponovo" posle greške.
class MyLessonsRetried extends MyLessonsEvent {}

class LessonWithdrawn extends MyLessonsEvent {
  LessonWithdrawn(this.lesson);

  final Lesson lesson;
}

class LessonCancelled extends MyLessonsEvent {
  LessonCancelled(this.lesson);

  final Lesson lesson;
}
