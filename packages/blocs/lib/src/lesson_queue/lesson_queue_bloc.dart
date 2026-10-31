import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'lesson_queue_event.dart';
import 'lesson_queue_state.dart';

class LessonQueueBloc extends Bloc<LessonQueueEvent, LessonQueueState> {
  LessonQueueBloc(this._getQueue) : super(const LessonQueueInitial()) {
    on<QueueRequested>(_onRequested);
    on<QueueRetried>(_onRetried);
  }

  final GetLessonQueue _getQueue;

  Future<void> _onRequested(QueueRequested event, Emitter<LessonQueueState> emit) async {
    await _load(emit);
  }

  Future<void> _onRetried(QueueRetried event, Emitter<LessonQueueState> emit) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<LessonQueueState> emit) async {
    emit(const LessonQueueLoading());
    try {
      final lessons = await _getQueue();
      if (lessons.isEmpty) {
        emit(const LessonQueueEmpty());
      } else {
        final rows = lessons.map(_toRow).toList();
        emit(LessonQueueLoaded(rows, tab: QueueTab.pending, selectedId: _firstIn(rows, QueueTab.pending)));
      }
    } on RepositoryException catch (e) {
      emit(LessonQueueFailure(e.message));
    }
  }

  // Dugmad zavise samo od statusa. Da li je čas već počeo proverava domen tek kad se dugme pritisne.
  QueueRow _toRow(Lesson lesson) {
    final actions = switch (lesson.status) {
      Pending() => const [QueueAction.confirm, QueueAction.reject],
      Confirmed() => const [QueueAction.held, QueueAction.noShow],
      _ => const <QueueAction>[],
    };
    return QueueRow(lesson: lesson, actions: actions);
  }

  LessonId? _firstIn(List<QueueRow> rows, QueueTab tab) => rows.where((row) => row.tab == tab).firstOrNull?.lesson.id;
}
