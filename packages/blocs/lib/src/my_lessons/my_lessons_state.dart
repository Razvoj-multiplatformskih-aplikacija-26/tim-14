import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

import '../action_notice.dart';

enum LessonAction { withdraw, cancel, none }

// Jedan red u listi časova.
class LessonItem extends Equatable {
  const LessonItem({required this.lesson, required this.action, this.blockedBy});

  final Lesson lesson;
  final LessonAction action;

  // Ako akcija trenutno nije dozvoljena, ovde piše zašto (npr. CancellationTooLate).
  final DomainError? blockedBy;

  @override
  List<Object?> get props => [lesson, action, blockedBy];
}

sealed class MyLessonsState extends Equatable {
  const MyLessonsState();

  @override
  List<Object?> get props => [];
}

class MyLessonsInitial extends MyLessonsState {
  const MyLessonsInitial();
}

class MyLessonsLoading extends MyLessonsState {
  const MyLessonsLoading();
}

// Časovi nisu učitani. Nosi samo vrstu greške, a tekst za ekran pravi aplikacija.
class MyLessonsFailure extends MyLessonsState {
  const MyLessonsFailure(this.failure);

  final RepositoryFailure failure;

  @override
  List<Object?> get props => [failure];
}

class MyLessonsEmpty extends MyLessonsState {
  const MyLessonsEmpty();
}

class MyLessonsLoaded extends MyLessonsState {
  const MyLessonsLoaded(this.items, {this.notice});

  final List<LessonItem> items;

  // Ishod poslednje akcije koji ekran prikaže kao SnackBar: pravilo koje nije prošlo (i u aplikaciji i na
  // serveru) ili akcija koja nije stigla do servera. Lista ostaje na ekranu u oba slučaja.
  final ActionNotice? notice;

  // Grupe za ekran: potvrđeni su predstojeći, na čekanju čekaju profesora, ostalo je istorija.
  // Grupiše se po stanju, ne po vremenu: otkazan čas za tri dana je završen, pa je u istoriji.
  List<LessonItem> get upcoming => items.where((item) => item.lesson.status is Confirmed).toList();

  List<LessonItem> get pending => items.where((item) => item.lesson.status is Pending).toList();

  // U istoriji su najnoviji prvi.
  List<LessonItem> get history => items
      .where((item) => item.lesson.status is! Confirmed && item.lesson.status is! Pending)
      .toList()
      .reversed
      .toList();

  @override
  List<Object?> get props => [items, notice];
}
