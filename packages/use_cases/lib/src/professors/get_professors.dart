import 'package:domain/domain.dart';

import '../ports/professor_repository.dart';

final class GetProfessors {
  GetProfessors(this._professors);

  final ProfessorRepository _professors;

  Future<List<ProfessorProfile>> call() => _professors.professors();
}
