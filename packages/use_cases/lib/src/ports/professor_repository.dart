import 'package:domain/domain.dart';

abstract interface class ProfessorRepository {
  Future<List<ProfessorProfile>> professors();

  Future<ProfessorProfile> profile(UserId id);

  Future<List<Listing>> listingsOf(UserId professor);

  Future<List<Slot>> slotsOf(UserId professor);
}
