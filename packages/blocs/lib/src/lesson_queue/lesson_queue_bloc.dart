import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'lesson_queue_event.dart';
import 'lesson_queue_state.dart';

class LessonQueueBloc extends Bloc<LessonQueueEvent, LessonQueueState> {
  LessonQueueBloc(this._getQueue) : super(const LessonQueueInitial()) {
    on<QueueRequested>(_onRequested);
    on<QueueRetried>(_onRetried);
    on<TabChanged>(_onTabChanged);
    on<RowSelected>(_onRowSelected);
    on<SelectionMoved>(_onSelectionMoved);
  }

  final GetLessonQueue _getQueue;

  Future<void> _onRequested(QueueRequested event, Emitter<LessonQueueState> emit) async {
    await _load(emit);
  }

  Future<void> _onRetried(QueueRetried event, Emitter<LessonQueueState> emit) async {
    await _load(emit);
  }

  // Novo stanje se pravi bez actionError, inače bi se SnackBar ponovo pokazao na svaku strelicu.
  void _onTabChanged(TabChanged event, Emitter<LessonQueueState> emit) {
    final current = state;
    if (current is! LessonQueueLoaded) return;
    emit(LessonQueueLoaded(current.rows, tab: event.tab, selectedId: _firstIn(current.rows, event.tab)));
  }

  void _onRowSelected(RowSelected event, Emitter<LessonQueueState> emit) {
    final current = state;
    if (current is! LessonQueueLoaded) return;
    emit(LessonQueueLoaded(current.rows, tab: current.tab, selectedId: event.id));
  }

  // Na prvom i poslednjem redu izbor ostaje gde je.
  void _onSelectionMoved(SelectionMoved event, Emitter<LessonQueueState> emit) {
    final current = state;
    if (current is! LessonQueueLoaded) return;
    final visible = current.visibleRows;
    if (visible.isEmpty) return;
    final index = visible.indexWhere((row) => row.lesson.id == current.selectedId);
    final next = (index + event.delta).clamp(0, visible.length - 1);
    emit(LessonQueueLoaded(current.rows, tab: current.tab, selectedId: visible[next].lesson.id));
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
