import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'professor_page_event.dart';
import 'professor_page_state.dart';

class ProfessorPageBloc extends Bloc<ProfessorPageEvent, ProfessorPageState> {
  ProfessorPageBloc(this._getProfessorPage, this._professorId) : super(const ProfessorPageInitial()) {
    on<ProfessorPageRequested>(_onRequested);
    on<ProfessorPageRetried>(_onRetried);
    on<ProfessorPageRefreshed>(_onRefreshed);
  }

  final GetProfessorPage _getProfessorPage;
  final UserId _professorId;

  Future<void> _onRequested(ProfessorPageRequested event, Emitter<ProfessorPageState> emit) async {
    await _load(emit);
  }

  Future<void> _onRetried(ProfessorPageRetried event, Emitter<ProfessorPageState> emit) async {
    await _load(emit);
  }

  // Sa stranicom na ekranu se osvežava tiho. Ako server ne odgovori, stranica ostaje, a ekran kaže zašto.
  Future<void> _onRefreshed(ProfessorPageRefreshed event, Emitter<ProfessorPageState> emit) async {
    try {
      await _refresh(emit);
    } finally {
      event.done?.complete();
    }
  }

  Future<void> _refresh(Emitter<ProfessorPageState> emit) async {
    final current = state;
    if (current is! ProfessorPageLoaded) {
      await _load(emit);
      return;
    }
    try {
      emit(ProfessorPageLoaded(await _getProfessorPage(_professorId)));
    } on RepositoryException catch (e) {
      emit(ProfessorPageLoaded(current.page, refreshFailure: e.failure));
    }
  }

  Future<void> _load(Emitter<ProfessorPageState> emit) async {
    emit(const ProfessorPageLoading());
    try {
      final page = await _getProfessorPage(_professorId);
      emit(ProfessorPageLoaded(page));
    } on RepositoryException catch (e) {
      emit(ProfessorPageFailure(e.failure));
    }
  }
}
