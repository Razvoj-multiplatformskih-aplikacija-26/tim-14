import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

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

class MyLessonsFailure extends MyLessonsState {
  const MyLessonsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class MyLessonsEmpty extends MyLessonsState {
  const MyLessonsEmpty();
}

class MyLessonsLoaded extends MyLessonsState {
  const MyLessonsLoaded(this.items, {this.actionError});

  final List<LessonItem> items;

  // Greška poslednje akcije, ekran je prikaže kao SnackBar.
  final DomainError? actionError;

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
  List<Object?> get props => [items, actionError];
}
