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

class ProfessorPageFailure extends ProfessorPageState {
  const ProfessorPageFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ProfessorPageLoaded extends ProfessorPageState {
  const ProfessorPageLoaded(this.page);

  // Profil, oglasi i slobodni termini profesora.
  final ProfessorPage page;

  @override
  List<Object?> get props => [page];
}
