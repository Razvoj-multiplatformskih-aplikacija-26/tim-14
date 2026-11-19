import 'package:domain/domain.dart';

import '../professors/professors_page.dart';

abstract interface class ProfessorRepository {
  Future<ProfessorsPage> professors({int offset = 0, int limit = 20});

  Future<ProfessorProfile> profile(UserId id);

  Future<List<Listing>> listingsOf(UserId professor);

  Future<List<Slot>> slotsOf(UserId professor);

  Future<Slot?> findSlot(SlotId id);
}
