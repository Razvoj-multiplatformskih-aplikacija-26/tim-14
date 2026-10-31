sealed class VerificationQueueEvent {}

// Ekran sa verifikacijama je otvoren.
class VerificationRequested extends VerificationQueueEvent {}

// Administrator je kliknuo "Pokušaj ponovo" posle greške.
class VerificationRetried extends VerificationQueueEvent {}
