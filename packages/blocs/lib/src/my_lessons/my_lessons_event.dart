import 'dart:async';

import 'package:domain/domain.dart';

sealed class MyLessonsEvent {}

// Ekran "Moji časovi" je otvoren.
class MyLessonsRequested extends MyLessonsEvent {}

// Korisnik je kliknuo "Pokušaj ponovo" posle greške.
class MyLessonsRetried extends MyLessonsEvent {}

// Osvežavanje bez spinera: povuci nadole, otvoren tab, ili posle akcije koju je server odbio.
// Lista ostaje na ekranu dok stižu novi podaci.
class MyLessonsRefreshed extends MyLessonsEvent {
  MyLessonsRefreshed({this.done});

  // Završi se kad osvežavanje stigne do kraja, uspešno ili ne. RefreshIndicator do tada drži svoj spiner.
  final Completer<void>? done;
}

class LessonWithdrawn extends MyLessonsEvent {
  LessonWithdrawn(this.lesson);

  final Lesson lesson;
}

class LessonCancelled extends MyLessonsEvent {
  LessonCancelled(this.lesson);

  final Lesson lesson;
}
