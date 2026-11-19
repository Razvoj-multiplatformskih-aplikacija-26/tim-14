import 'package:bloc/bloc.dart';
import 'package:use_cases/use_cases.dart';

import 'professors_event.dart';
import 'professors_state.dart';

class ProfessorsBloc extends Bloc<ProfessorsEvent, ProfessorsState> {
  ProfessorsBloc(this._getProfessors) : super(const ProfessorsInitial()) {
    on<ProfessorsRequested>(_onRequested);
    on<ProfessorsRetried>(_onRetried);
  }

  final GetProfessors _getProfessors;

  Future<void> _onRequested(ProfessorsRequested event, Emitter<ProfessorsState> emit) async {
    await _load(emit);
  }

  Future<void> _onRetried(ProfessorsRetried event, Emitter<ProfessorsState> emit) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<ProfessorsState> emit) async {
    emit(const ProfessorsLoading());
    try {
      // Za sada samo prva strana (do 20 profesora). Dugme "Učitaj još" bi tražilo offset: page.nextOffset.
      final page = await _getProfessors();
      if (page.items.isEmpty) {
        emit(const ProfessorsEmpty());
      } else {
        emit(ProfessorsLoaded(page.items));
      }
    } on RepositoryException catch (e) {
      emit(ProfessorsFailure(e.message));
    }
  }
}
