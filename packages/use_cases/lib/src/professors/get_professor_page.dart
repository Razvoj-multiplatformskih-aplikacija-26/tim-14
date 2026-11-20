import 'package:domain/domain.dart';

import '../clock.dart';
import '../ports/lesson_repository.dart';
import '../ports/professor_repository.dart';

final class ProfessorPage {
  const ProfessorPage({required this.profile, required this.listings, required this.freeSlots});

  final ProfessorProfile profile;
  final List<Listing> listings;
  final List<Slot> freeSlots;

  List<Slot> freeSlotsOf(ListingId listing) => freeSlots.where((slot) => slot.listingId == listing).toList();
}

final class GetProfessorPage {
  GetProfessorPage(this._professors, this._lessons, this._clock);

  final ProfessorRepository _professors;
  final LessonRepository _lessons;
  final Clock _clock;

  Future<ProfessorPage> call(UserId professor) async {
    final profile = await _professors.profile(professor);
    final listings = await _professors.listingsOf(professor);
    final slots = await _professors.slotsOf(professor);
    // Samo koji termini su zauzeti, ne tuđi časovi: učenik ne sme da vidi tuđe zahteve i poruke.
    final taken = await _lessons.takenSlotsOf(professor);

    return ProfessorPage(
      profile: profile,
      listings: listings,
      freeSlots: freeSlots(slots, taken: taken, now: _clock.now()),
    );
  }
}
