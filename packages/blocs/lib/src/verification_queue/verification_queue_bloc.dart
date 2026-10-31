import 'package:bloc/bloc.dart';
import 'package:use_cases/use_cases.dart';

import 'verification_queue_event.dart';
import 'verification_queue_state.dart';

class VerificationQueueBloc extends Bloc<VerificationQueueEvent, VerificationQueueState> {
  VerificationQueueBloc(this._getQueue) : super(const VerificationQueueInitial()) {
    on<VerificationRequested>(_onRequested);
    on<VerificationRetried>(_onRetried);
  }

  final GetVerificationQueue _getQueue;

  Future<void> _onRequested(VerificationRequested event, Emitter<VerificationQueueState> emit) async {
    await _load(emit);
  }

  Future<void> _onRetried(VerificationRetried event, Emitter<VerificationQueueState> emit) async {
    await _load(emit);
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
