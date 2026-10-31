import 'package:bloc/bloc.dart';
import 'package:use_cases/use_cases.dart';

import 'verification_queue_event.dart';
import 'verification_queue_state.dart';

class VerificationQueueBloc extends Bloc<VerificationQueueEvent, VerificationQueueState> {
  VerificationQueueBloc(this._getQueue) : super(const VerificationQueueInitial()) {
    on<VerificationRequested>(_onRequested);
    on<VerificationRetried>(_onRetried);
    on<ProfileSelected>(_onProfileSelected);
    on<ProfileSelectionMoved>(_onSelectionMoved);
  }

  final GetVerificationQueue _getQueue;

  Future<void> _onRequested(VerificationRequested event, Emitter<VerificationQueueState> emit) async {
    await _load(emit);
  }

  Future<void> _onRetried(VerificationRetried event, Emitter<VerificationQueueState> emit) async {
    await _load(emit);
  }

  // Novo stanje se pravi bez actionError, inače bi se SnackBar ponovo pokazao na svaku strelicu.
  void _onProfileSelected(ProfileSelected event, Emitter<VerificationQueueState> emit) {
    final current = state;
    if (current is! VerificationQueueLoaded) return;
    emit(VerificationQueueLoaded(current.profiles, selectedId: event.id));
  }

  // Na prvom i poslednjem redu izbor ostaje gde je.
  void _onSelectionMoved(ProfileSelectionMoved event, Emitter<VerificationQueueState> emit) {
    final current = state;
    if (current is! VerificationQueueLoaded) return;
    final profiles = current.profiles;
    final index = profiles.indexWhere((profile) => profile.id == current.selectedId);
    final next = (index + event.delta).clamp(0, profiles.length - 1);
    emit(VerificationQueueLoaded(profiles, selectedId: profiles[next].id));
  }

  Future<void> _load(Emitter<VerificationQueueState> emit) async {
    emit(const VerificationQueueLoading());
    try {
      final profiles = await _getQueue();
      if (profiles.isEmpty) {
        emit(const VerificationQueueEmpty());
      } else {
        emit(VerificationQueueLoaded(profiles, selectedId: profiles.first.id));
      }
    } on RepositoryException catch (e) {
      emit(VerificationQueueFailure(e.message));
    }
  }
}
