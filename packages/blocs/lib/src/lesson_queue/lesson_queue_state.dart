import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

// Na čekanju, Potvrđeni, Održani, Arhiva.
enum QueueTab { pending, confirmed, held, archive }

enum QueueAction { confirm, reject, held, noShow }

// Jedan red u redu zahteva.
class QueueRow extends Equatable {
  const QueueRow({required this.lesson, required this.actions});

  final Lesson lesson;

  // Dugmad koja red nudi. Zavise samo od statusa.
  final List<QueueAction> actions;

  QueueTab get tab => switch (lesson.status) {
    Pending() => QueueTab.pending,
    Confirmed() => QueueTab.confirmed,
    Held() => QueueTab.held,
    Rejected() || Cancelled() || NoShow() => QueueTab.archive,
  };

  @override
  List<Object?> get props => [lesson, actions];
}

sealed class LessonQueueState extends Equatable {
  const LessonQueueState();

  @override
  List<Object?> get props => [];
}

class LessonQueueInitial extends LessonQueueState {
  const LessonQueueInitial();
}

class LessonQueueLoading extends LessonQueueState {
  const LessonQueueLoading();
}

class LessonQueueFailure extends LessonQueueState {
  const LessonQueueFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class LessonQueueEmpty extends LessonQueueState {
  const LessonQueueEmpty();
}

class LessonQueueLoaded extends LessonQueueState {
  const LessonQueueLoaded(this.rows, {required this.tab, this.selectedId, this.actionError});

  // Svi časovi iz svih tabova, pa promena taba ne učitava ništa ponovo.
  final List<QueueRow> rows;
  final QueueTab tab;

  // Izabrani red. Drži ga Bloc, pa ostaje izabran i kad se tabela pretvori u listu.
  final LessonId? selectedId;

  // Greška poslednje akcije, ekran je prikaže kao SnackBar.
  final DomainError? actionError;

  List<QueueRow> get visibleRows => rows.where((row) => row.tab == tab).toList();

  QueueRow? get selected => rows.where((row) => row.lesson.id == selectedId).firstOrNull;

  @override
  List<Object?> get props => [rows, tab, selectedId, actionError];
}
