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

// Prva strana nije učitana. Nosi samo vrstu greške, a tekst za ekran pravi aplikacija.
class ProfessorsFailure extends ProfessorsState {
  const ProfessorsFailure(this.failure);

  final RepositoryFailure failure;

  @override
  List<Object?> get props => [failure];
}

class ProfessorsEmpty extends ProfessorsState {
  const ProfessorsEmpty();
}

// Učitane strane, jedna za drugom. Lista profesora je jedina koja raste bez granice, pa stiže u stranama.
class ProfessorsLoaded extends ProfessorsState {
  const ProfessorsLoaded(
    this.professors, {
    this.nextOffset,
    this.loadingMore = false,
    this.moreFailure,
    this.refreshFailure,
  });

  final List<ProfessorSummary> professors;

  // Odakle počinje sledeća strana, ili null kad je ova bila poslednja.
  final int? nextOffset;

  // Sledeća strana se upravo učitava; ekran na dnu pokaže spiner.
  final bool loadingMore;

  // Sledeća strana nije stigla. Lista ostaje, a na dnu su poruka i "Pokušaj ponovo".
  final RepositoryFailure? moreFailure;

  // Osvežavanje nije stiglo do servera. Lista ostaje kakva je bila, a ekran to kaže u SnackBar-u.
  final RepositoryFailure? refreshFailure;

  bool get hasMore => nextOffset != null;

  @override
  List<Object?> get props => [professors, nextOffset, loadingMore, moreFailure, refreshFailure];
}
