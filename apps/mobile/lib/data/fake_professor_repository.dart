import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'fail_switch.dart';

class FakeProfessorRepository implements ProfessorRepository {
  FakeProfessorRepository({
    required this.profiles,
    required this.listings,
    required this.slots,
    required this.failSwitch,
    this.delay = const Duration(milliseconds: 800),
  });

  final List<ProfessorProfile> profiles;
  final List<Listing> listings;
  final List<Slot> slots;
  final FailSwitch failSwitch;
  final Duration delay;

  // Kasni samo ono čime ekran počinje da se učitava (lista i profil), kao kod časova.
  Future<void> _load() async {
    await Future<void>.delayed(delay);
    failSwitch.check();
  }

  @override
  Future<List<ProfessorProfile>> professors() async {
    await _load();
    return profiles;
  }

  @override
  Future<ProfessorProfile> profile(UserId id) async {
    await _load();
    for (final profile in profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    throw const RepositoryException('Profesor ne postoji');
  }

  @override
  Future<List<Listing>> listingsOf(UserId professor) async {
    failSwitch.check();
    return listings.where((listing) => listing.professorId == professor).toList();
  }

  @override
  Future<List<Slot>> slotsOf(UserId professor) async {
    failSwitch.check();
    return slots.where((slot) => slot.professorId == professor).toList();
  }
}
