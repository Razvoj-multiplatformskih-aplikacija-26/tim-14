import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'fail_switch.dart';

final class FakeVerificationRepository implements VerificationRepository {
  FakeVerificationRepository(
    List<ProfessorProfile> profiles,
    this._failSwitch, {
    this.delay = const Duration(milliseconds: 800),
  }) : _profiles = [...profiles];

  final List<ProfessorProfile> _profiles;
  final FailSwitch _failSwitch;
  final Duration delay;

  // Vraća sve profile, i one koji ne čekaju. Filtrira GetVerificationQueue.
  @override
  Future<List<ProfessorProfile>> queue() async {
    await Future<void>.delayed(delay);
    _failSwitch.check();
    return [..._profiles];
  }

  @override
  Future<ProfessorProfile?> find(UserId professor) async {
    _failSwitch.check();
    return _profiles.where((profile) => profile.id == professor).firstOrNull;
  }

  // Kao baza na serveru: ako je drugi administrator već odlučio, ništa se ne upisuje.
  @override
  Future<Result<ProfessorProfile>> save(ProfessorProfile profile, {required VerificationStatus from}) async {
    _failSwitch.check();
    final index = _profiles.indexWhere((other) => other.id == profile.id);
    if (index == -1) {
      return const Failure(NotFound());
    }
    final stored = _profiles[index].verification;
    if (stored.runtimeType != from.runtimeType) {
      return Failure(InvalidVerificationTransition(from: stored, to: profile.verification));
    }
    _profiles[index] = profile;
    return Success(profile);
  }
}
