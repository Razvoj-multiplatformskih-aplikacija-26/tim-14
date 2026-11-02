import 'package:domain/domain.dart';

import '../ports/professor_repository.dart';

// Jedan red na listi profesora: profil i njegovi oglasi (zbog predmeta i cene na kartici).
final class ProfessorSummary {
  const ProfessorSummary({required this.profile, required this.listings});

  final ProfessorProfile profile;
  final List<Listing> listings;

  // Cena najjeftinijeg oglasa, za "od 1.800 din" na kartici. Null ako profesor nema oglas.
  Price? get lowestPrice {
    Price? lowest;
    for (final listing in listings) {
      if (lowest == null || listing.price.dinars < lowest.dinars) {
        lowest = listing.price;
      }
    }
    return lowest;
  }
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
