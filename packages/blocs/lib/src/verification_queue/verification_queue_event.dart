import 'package:domain/domain.dart';

sealed class VerificationQueueEvent {}

// Ekran sa verifikacijama je otvoren.
class VerificationRequested extends VerificationQueueEvent {}

// Administrator je kliknuo "Pokušaj ponovo" posle greške.
class VerificationRetried extends VerificationQueueEvent {}

// Klik na red.
class ProfileSelected extends VerificationQueueEvent {
  ProfileSelected(this.id);

  final UserId id;
}

// Strelica gore (-1) ili dole (+1).
class ProfileSelectionMoved extends VerificationQueueEvent {
  ProfileSelectionMoved(this.delta);

  final int delta;
}
