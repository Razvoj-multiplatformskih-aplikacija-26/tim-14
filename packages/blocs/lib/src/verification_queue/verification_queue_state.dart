import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

import '../action_notice.dart';

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

// Učitavanje nije uspelo. Nosi samo vrstu greške, a tekst za ekran pravi aplikacija.
class VerificationQueueFailure extends VerificationQueueState {
  const VerificationQueueFailure(this.failure);

  final RepositoryFailure failure;

  @override
  List<Object?> get props => [failure];
}

class VerificationQueueEmpty extends VerificationQueueState {
  const VerificationQueueEmpty();
}

class VerificationQueueLoaded extends VerificationQueueState {
  const VerificationQueueLoaded(this.profiles, {this.selectedId, this.notice});

  // Samo profili na proveri, najstariji prvi. Oba dugmeta važe za svaki, pa nema tabova ni liste akcija.
  final List<ProfessorProfile> profiles;

  // Izabrani profil. Drži ga Bloc, pa ostaje izabran i kad se tabela pretvori u listu.
  final UserId? selectedId;

  // Ishod poslednje odluke koji ekran prikaže kao SnackBar: odbijeno pravilo ili greška veze.
  final ActionNotice? notice;

  ProfessorProfile? get selected => profiles.where((profile) => profile.id == selectedId).firstOrNull;

  @override
  List<Object?> get props => [profiles, selectedId, notice];
}
