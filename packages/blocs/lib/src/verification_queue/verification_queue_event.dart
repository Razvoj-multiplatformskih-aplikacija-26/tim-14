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

// Akcije nemaju profil, rade nad izabranim redom. Zato dugme i taster šalju isti događaj.
class VerifyPressed extends VerificationQueueEvent {}

// Razlog stiže iz dijaloga. Prekratak razlog odbije use case, pa se vrati kao greška.
class RejectProfessorPressed extends VerificationQueueEvent {
  RejectProfessorPressed(this.reason);

  final String reason;
}
