sealed class LessonQueueEvent {}

// Ekran sa zahtevima je otvoren.
class QueueRequested extends LessonQueueEvent {}

// Profesor je kliknuo "Pokušaj ponovo" posle greške.
class QueueRetried extends LessonQueueEvent {}
