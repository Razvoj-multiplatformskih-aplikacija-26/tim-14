import 'package:domain/domain.dart';

import '../ports/professor_repository.dart';

// Jedan red na listi profesora: profil i njegovi oglasi (zbog predmeta i cene na kartici).
final class ProfessorSummary {
  const ProfessorSummary({required this.profile, required this.listings});

  final ProfessorProfile profile;
  final List<Listing> listings;
}

final class GetProfessors {
  GetProfessors(this._professors);

  final ProfessorRepository _professors;

  Future<List<ProfessorSummary>> call() async {
    final profiles = await _professors.professors();
    final result = <ProfessorSummary>[];

    for (final profile in profiles) {
      final listings = await _professors.listingsOf(profile.id);
      result.add(ProfessorSummary(profile: profile, listings: listings));
    }

    return result;
  }
}
