import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

sealed class ProfessorsState extends Equatable {
  const ProfessorsState();

  @override
  List<Object?> get props => [];
}

class ProfessorsInitial extends ProfessorsState {
  const ProfessorsInitial();
}

class ProfessorsLoading extends ProfessorsState {
  const ProfessorsLoading();
}

class ProfessorsFailure extends ProfessorsState {
  const ProfessorsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ProfessorsEmpty extends ProfessorsState {
  const ProfessorsEmpty();
}

class ProfessorsLoaded extends ProfessorsState {
  const ProfessorsLoaded(this.professors);

  final List<ProfessorSummary> professors;

  @override
  List<Object?> get props => [professors];
}
