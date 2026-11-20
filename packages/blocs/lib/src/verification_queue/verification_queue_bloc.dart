import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import '../action_notice.dart';
import 'verification_queue_event.dart';
import 'verification_queue_state.dart';

class VerificationQueueBloc extends Bloc<VerificationQueueEvent, VerificationQueueState> {
  VerificationQueueBloc(this._getQueue, this._verify, this._reject) : super(const VerificationQueueInitial()) {
    on<VerificationRequested>(_onRequested);
    on<VerificationRetried>(_onRetried);
    on<VerificationRefreshed>(_onRefreshed);
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

  // Isto kao kod časova: dok se učitava ili čuva odluka, osvežavanje ne radi ništa.
  Future<void> _onRefreshed(VerificationRefreshed event, Emitter<VerificationQueueState> emit) async {
    final current = state;
    if (_acting || current is VerificationQueueLoading) return;
    if (current is VerificationQueueLoaded) {
      await _reload(emit);
    } else {
      await _load(emit);
    }
  }

  // Novo stanje se pravi bez notice, inače bi se SnackBar ponovo pokazao na svaku strelicu.
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
        // Kasni klijent: možda je drugi administrator već odlučio. Prvo kažemo zašto, pa tiho osvežimo.
        emit(
          VerificationQueueLoaded(latest.profiles, selectedId: latest.selectedId, notice: ActionRejected(result.error)),
        );
        await _reload(emit);
      }
    } on RepositoryException catch (e) {
      // Veza je pukla usred odluke. Lista ostaje, a greška ide u SnackBar.
      _showFailure(emit, e.failure);
    } finally {
      _acting = false;
    }
  }

  // Profil o kome je odlučeno izlazi iz reda, bez ponovnog učitavanja.
  VerificationQueueState _without(VerificationQueueLoaded current, UserId decided) =>
      _keepSelection(current, current.profiles.where((profile) => profile.id != decided).toList());

  // Izbor ostaje ako je profil i dalje u redu. Ako nije, biramo profil koji je sad na njegovom mestu,
  // pa posle V izbor stoji na sledećem. Kad nema nikog, red je prazan. Važi posle odluke i posle osvežavanja.
  VerificationQueueState _keepSelection(VerificationQueueLoaded current, List<ProfessorProfile> profiles) {
    if (profiles.isEmpty) return const VerificationQueueEmpty();
    if (profiles.any((profile) => profile.id == current.selectedId)) {
      return VerificationQueueLoaded(profiles, selectedId: current.selectedId);
    }

    final index = current.profiles.indexWhere((profile) => profile.id == current.selectedId);
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
      emit(VerificationQueueFailure(e.failure));
    }
  }

  // Tiho učitavanje: bez VerificationQueueLoading, pa stari redovi ostaju na ekranu dok stižu novi.
  // Novo stanje nema notice, pa se SnackBar koji je već na ekranu ne pokaže ponovo.
  Future<void> _reload(Emitter<VerificationQueueState> emit) async {
    try {
      final profiles = await _getQueue();
      final latest = state;
      if (latest is! VerificationQueueLoaded) return;
      emit(_keepSelection(latest, profiles));
    } on RepositoryException catch (e) {
      // Server se ne javlja: stara lista bi izgledala kao da je sve u redu, pa ide ekran „Nema veze sa serverom“
      // sa dugmetom Pokušaj ponovo. Za ostale greške server je bar odgovorio, pa lista ostaje, a greška ide u SnackBar.
      if (e.failure == RepositoryFailure.unreachable) {
        emit(VerificationQueueFailure(e.failure));
      } else {
        _showFailure(emit, e.failure);
      }
    }
  }

  // Lista ostaje, greška ide u SnackBar. Prvo obrišemo stari notice, inače bi ista greška
  // drugi put dala jednako stanje i SnackBar se ne bi pokazao.
  void _showFailure(Emitter<VerificationQueueState> emit, RepositoryFailure failure) {
    final latest = state;
    if (latest is! VerificationQueueLoaded) return;
    emit(VerificationQueueLoaded(latest.profiles, selectedId: latest.selectedId));
    emit(VerificationQueueLoaded(latest.profiles, selectedId: latest.selectedId, notice: ActionFailed(failure)));
  }
}
