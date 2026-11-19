import 'package:domain/domain.dart';

abstract interface class VerificationRepository {
  Future<List<ProfessorProfile>> queue();

  Future<ProfessorProfile?> find(UserId professor);

  // Kao LessonRepository.save: ako je drugi administrator već odlučio, vraća InvalidVerificationTransition.
  Future<Result<ProfessorProfile>> save(ProfessorProfile profile, {required VerificationStatus from});
}
