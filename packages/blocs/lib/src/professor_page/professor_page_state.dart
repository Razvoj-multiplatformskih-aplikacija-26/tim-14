import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

sealed class ProfessorPageState extends Equatable {
  const ProfessorPageState();

  @override
  List<Object?> get props => [];
}

class ProfessorPageInitial extends ProfessorPageState {
  const ProfessorPageInitial();
}

class ProfessorPageLoading extends ProfessorPageState {
  const ProfessorPageLoading();
}

// Profil nije učitan. Nosi samo vrstu greške, a tekst za ekran pravi aplikacija.
class ProfessorPageFailure extends ProfessorPageState {
  const ProfessorPageFailure(this.failure);

  final RepositoryFailure failure;

  @override
  List<Object?> get props => [failure];
}

class ProfessorPageLoaded extends ProfessorPageState {
  const ProfessorPageLoaded(this.page, {this.refreshFailure});

  // Profil, oglasi i slobodni termini profesora.
  final ProfessorPage page;

  // Osvežavanje nije stiglo do servera. Stranica ostaje kakva je bila, a ekran to kaže u SnackBar-u.
  final RepositoryFailure? refreshFailure;

  @override
  List<Object?> get props => [page, refreshFailure];
}
