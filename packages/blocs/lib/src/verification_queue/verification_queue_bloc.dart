import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'verification_queue_event.dart';
import 'verification_queue_state.dart';

class VerificationQueueBloc extends Bloc<VerificationQueueEvent, VerificationQueueState> {
  VerificationQueueBloc(this._getQueue, this._verify, this._reject) : super(const VerificationQueueInitial()) {
    on<VerificationRequested>(_onRequested);
    on<VerificationRetried>(_onRetried);
    on<ProfileSelected>(_onProfileSelected);
    on<ProfileSelectionMoved>(_onSelectionMoved);
    on<VerifyPressed>(_onVerifyPressed);
    on<RejectProfessorPressed>(_onRejectPressed);
  }

  final GetVerificationQueue _getQueue;
  final VerifyProfessor _verify;
  final RejectProfessor _reject;

  // Dok se jedna odluka čuva, ostali pritisci se ignorišu.
  bool _acting = false;

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

  Future<void> _onVerifyPressed(VerifyPressed event, Emitter<VerificationQueueState> emit) => _act(emit, _verify.call);

  Future<void> _onRejectPressed(RejectProfessorPressed event, Emitter<VerificationQueueState> emit) =>
      _act(emit, (profile) => _reject(profile, reason: event.reason));

  // Zajedničko za obe odluke. `run` je use case koji odlučuje o izabranom profilu.
  Future<void> _act(
    Emitter<VerificationQueueState> emit,
    Future<Result<ProfessorProfile>> Function(ProfessorProfile) run,
  ) async {
    final current = state;
    if (_acting || current is! VerificationQueueLoaded) return;
    final profile = current.selected;
    if (profile == null) return;

    _acting = true;
    // Prvo obrišemo staru grešku. Inače bi ista greška drugi put dala jednako stanje,
    // Bloc bi ga odbacio i SnackBar se ne bi pokazao.
    emit(VerificationQueueLoaded(current.profiles, selectedId: current.selectedId));
    try {
      final result = await run(profile);

      // Čitamo najnovije stanje, jer je administrator možda u međuvremenu pomerio izbor.
      final latest = state;
      if (latest is! VerificationQueueLoaded) return;
      if (result is Success<ProfessorProfile>) {
        emit(_without(latest, profile.id));
      } else if (result is Failure<ProfessorProfile>) {
        emit(VerificationQueueLoaded(latest.profiles, selectedId: latest.selectedId, actionError: result.error));
      }
    } on RepositoryException catch (e) {
      emit(VerificationQueueFailure(e.message));
    } finally {
      _acting = false;
    }
  }

  // Profil o kome je odlučeno izlazi iz reda, bez ponovnog učitavanja. Ako je bio izabran, biramo profil
  // koji je sad na njegovom mestu, pa posle V izbor stoji na sledećem. Posle poslednjeg red je prazan.
  VerificationQueueState _without(VerificationQueueLoaded current, UserId decided) {
    final profiles = current.profiles.where((profile) => profile.id != decided).toList();
    if (profiles.isEmpty) return const VerificationQueueEmpty();
    if (current.selectedId != decided) return VerificationQueueLoaded(profiles, selectedId: current.selectedId);

    final index = current.profiles.indexWhere((profile) => profile.id == decided);
    return VerificationQueueLoaded(profiles, selectedId: profiles[index.clamp(0, profiles.length - 1)].id);
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
