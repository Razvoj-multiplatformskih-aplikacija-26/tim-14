import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'lesson_queue_event.dart';
import 'lesson_queue_state.dart';

class LessonQueueBloc extends Bloc<LessonQueueEvent, LessonQueueState> {
  LessonQueueBloc(this._getQueue, this._confirm, this._reject, this._held, this._noShow)
    : super(const LessonQueueInitial()) {
    on<QueueRequested>(_onRequested);
    on<QueueRetried>(_onRetried);
    on<TabChanged>(_onTabChanged);
    on<RowSelected>(_onRowSelected);
    on<SelectionMoved>(_onSelectionMoved);
    on<ConfirmPressed>(_onConfirmPressed);
    on<RejectPressed>(_onRejectPressed);
    on<HeldPressed>(_onHeldPressed);
    on<NoShowPressed>(_onNoShowPressed);
  }

  final GetLessonQueue _getQueue;
  final ConfirmLesson _confirm;
  final RejectLesson _reject;
  final RecordHeld _held;
  final RecordNoShow _noShow;

  // Dok se jedna akcija čuva, ostali pritisci se ignorišu.
  bool _acting = false;

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

  // Potvrda menja i ostale zahteve za isti termin, zato vraća sve njih.
  Future<void> _onConfirmPressed(ConfirmPressed event, Emitter<LessonQueueState> emit) => _act(
    QueueAction.confirm,
    emit,
    _confirm.call,
    (confirmation) => [confirmation.confirmed, ...confirmation.rejected],
  );

  Future<void> _onRejectPressed(RejectPressed event, Emitter<LessonQueueState> emit) =>
      _act(QueueAction.reject, emit, _reject.call, (lesson) => [lesson]);

  Future<void> _onHeldPressed(HeldPressed event, Emitter<LessonQueueState> emit) =>
      _act(QueueAction.held, emit, _held.call, (lesson) => [lesson]);

  Future<void> _onNoShowPressed(NoShowPressed event, Emitter<LessonQueueState> emit) =>
      _act(QueueAction.noShow, emit, _noShow.call, (lesson) => [lesson]);

  // Zajedničko za sve četiri akcije. `run` je use case, a `changed` kaže koje je časove promenio.
  Future<void> _act<T>(
    QueueAction action,
    Emitter<LessonQueueState> emit,
    Future<Result<T>> Function(Lesson) run,
    List<Lesson> Function(T) changed,
  ) async {
    final current = state;
    if (_acting || current is! LessonQueueLoaded) return;
    final row = current.selected;
    if (row == null || !row.actions.contains(action)) return;

    _acting = true;
    // Prvo obrišemo staru grešku. Inače bi ista greška drugi put dala jednako stanje,
    // Bloc bi ga odbacio i SnackBar se ne bi pokazao.
    emit(LessonQueueLoaded(current.rows, tab: current.tab, selectedId: current.selectedId));
    try {
      final result = await run(row.lesson);

      // Čitamo najnovije stanje, jer je profesor možda u međuvremenu pomerio izbor.
      final latest = state;
      if (latest is! LessonQueueLoaded) return;
      if (result is Success<T>) {
        emit(_withChanges(latest, changed(result.value)));
      } else if (result is Failure<T>) {
        emit(LessonQueueLoaded(latest.rows, tab: latest.tab, selectedId: latest.selectedId, actionError: result.error));
      }
    } on RepositoryException catch (e) {
      emit(LessonQueueFailure(e.message));
    } finally {
      _acting = false;
    }
  }

  // Promenjene časove menjamo po id-ju, bez ponovnog učitavanja. Ako izabrani red više nije u ovom tabu,
  // biramo red koji je sad na njegovom mestu, pa posle P izbor stoji na sledećem zahtevu.
  LessonQueueLoaded _withChanges(LessonQueueLoaded current, List<Lesson> changed) {
    final byId = {for (final lesson in changed) lesson.id: lesson};
    final rows = [for (final row in current.rows) _toRow(byId[row.lesson.id] ?? row.lesson)];
    final next = LessonQueueLoaded(rows, tab: current.tab, selectedId: current.selectedId);
    final visible = next.visibleRows;
    if (visible.any((row) => row.lesson.id == current.selectedId)) return next;

    final index = current.visibleRows.indexWhere((row) => row.lesson.id == current.selectedId);
    final selectedId = visible.isEmpty ? null : visible[index.clamp(0, visible.length - 1)].lesson.id;
    return LessonQueueLoaded(rows, tab: current.tab, selectedId: selectedId);
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
