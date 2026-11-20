import 'package:bloc/bloc.dart';
import 'package:use_cases/use_cases.dart';

import 'professors_event.dart';
import 'professors_state.dart';

class ProfessorsBloc extends Bloc<ProfessorsEvent, ProfessorsState> {
  ProfessorsBloc(this._getProfessors) : super(const ProfessorsInitial()) {
    on<ProfessorsRequested>(_onRequested);
    on<ProfessorsRetried>(_onRetried);
    on<ProfessorsNextPageRequested>(_onNextPageRequested);
    on<ProfessorsRefreshed>(_onRefreshed);
  }

  final GetProfessors _getProfessors;

  Future<void> _onRequested(ProfessorsRequested event, Emitter<ProfessorsState> emit) async {
    await _load(emit);
  }

  Future<void> _onRetried(ProfessorsRetried event, Emitter<ProfessorsState> emit) async {
    await _load(emit);
  }

  // Sledeća strana se nadovezuje na učitane. Ako ne stigne, lista ostaje, a greška ide na dno liste.
  // Ekran može da javi kraj liste više puta zaredom. Prvi zahtev odmah postavi loadingMore, pa se ostali vrate
  // bez poziva i ista strana se ne traži dvaput.
  Future<void> _onNextPageRequested(ProfessorsNextPageRequested event, Emitter<ProfessorsState> emit) async {
    final current = state;
    if (current is! ProfessorsLoaded || !current.hasMore || current.loadingMore) {
      return;
    }

    emit(ProfessorsLoaded(current.professors, nextOffset: current.nextOffset, loadingMore: true));
    try {
      final page = await _getProfessors(offset: current.nextOffset!);
      emit(ProfessorsLoaded([...current.professors, ...page.items], nextOffset: page.nextOffset));
    } on RepositoryException catch (e) {
      emit(ProfessorsLoaded(current.professors, nextOffset: current.nextOffset, moreFailure: e.failure));
    }
  }

  // Sa listom na ekranu se osvežava tiho, od prve strane. Ako server ne odgovori, lista ostaje kakva je.
  Future<void> _onRefreshed(ProfessorsRefreshed event, Emitter<ProfessorsState> emit) async {
    final current = state;
    if (current is! ProfessorsLoaded) {
      await _load(emit);
      return;
    }
    try {
      _show(await _getProfessors(), emit);
    } on RepositoryException catch (e) {
      emit(ProfessorsLoaded(current.professors, nextOffset: current.nextOffset, refreshFailure: e.failure));
    }
  }

  Future<void> _load(Emitter<ProfessorsState> emit) async {
    emit(const ProfessorsLoading());
    try {
      _show(await _getProfessors(), emit);
    } on RepositoryException catch (e) {
      emit(ProfessorsFailure(e.failure));
    }
  }

  void _show(ProfessorsPage page, Emitter<ProfessorsState> emit) {
    if (page.items.isEmpty) {
      emit(const ProfessorsEmpty());
    } else {
      emit(ProfessorsLoaded(page.items, nextOffset: page.nextOffset));
    }
  }
}
