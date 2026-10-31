import 'package:domain/domain.dart';

abstract interface class VerificationRepository {
  Future<List<ProfessorProfile>> queue();

  Future<ProfessorProfile> save(ProfessorProfile profile);
}
