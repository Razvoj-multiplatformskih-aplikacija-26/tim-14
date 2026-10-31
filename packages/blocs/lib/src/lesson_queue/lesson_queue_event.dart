import 'package:domain/domain.dart';

import 'lesson_queue_state.dart';

sealed class LessonQueueEvent {}

// Ekran sa zahtevima je otvoren.
class QueueRequested extends LessonQueueEvent {}

// Profesor je kliknuo "Pokušaj ponovo" posle greške.
class QueueRetried extends LessonQueueEvent {}

class TabChanged extends LessonQueueEvent {
  TabChanged(this.tab);

  final QueueTab tab;
}

// Klik na red.
class RowSelected extends LessonQueueEvent {
  RowSelected(this.id);

  final LessonId id;
}

// Strelica gore (-1) ili dole (+1).
class SelectionMoved extends LessonQueueEvent {
  SelectionMoved(this.delta);

  final int delta;
}

// Akcije nemaju čas, rade nad izabranim redom. Zato dugme i taster šalju isti događaj.
class ConfirmPressed extends LessonQueueEvent {}

class RejectPressed extends LessonQueueEvent {}

class HeldPressed extends LessonQueueEvent {}

class NoShowPressed extends LessonQueueEvent {}
