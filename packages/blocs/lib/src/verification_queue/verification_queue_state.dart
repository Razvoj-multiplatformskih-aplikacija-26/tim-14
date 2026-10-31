import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

sealed class VerificationQueueState extends Equatable {
  const VerificationQueueState();

  @override
  List<Object?> get props => [];
}

class VerificationQueueInitial extends VerificationQueueState {
  const VerificationQueueInitial();
}

class VerificationQueueLoading extends VerificationQueueState {
  const VerificationQueueLoading();
}

class VerificationQueueFailure extends VerificationQueueState {
  const VerificationQueueFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class VerificationQueueEmpty extends VerificationQueueState {
  const VerificationQueueEmpty();
}

class VerificationQueueLoaded extends VerificationQueueState {
  const VerificationQueueLoaded(this.profiles, {this.selectedId, this.actionError});

  // Samo profili na proveri, najstariji prvi. Oba dugmeta važe za svaki, pa nema tabova ni liste akcija.
  final List<ProfessorProfile> profiles;

  // Izabrani profil. Drži ga Bloc, pa ostaje izabran i kad se tabela pretvori u listu.
  final UserId? selectedId;

  // Greška poslednje akcije, ekran je prikaže kao SnackBar.
  final DomainError? actionError;

  ProfessorProfile? get selected => profiles.where((profile) => profile.id == selectedId).firstOrNull;

  @override
  List<Object?> get props => [profiles, selectedId, actionError];
}
