import 'package:domain/domain.dart';

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

// Jedna strana liste profesora. nextOffset je null na poslednjoj strani.
// Isti oblik kao ProfessorsPageDto, pa preko HTTP-a cela strana stiže jednim pozivom.
final class ProfessorsPage {
  const ProfessorsPage({required this.items, this.nextOffset});

  final List<ProfessorSummary> items;
  final int? nextOffset;
}
