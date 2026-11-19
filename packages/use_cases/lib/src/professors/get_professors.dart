import '../ports/professor_repository.dart';
import 'professors_page.dart';

final class GetProfessors {
  GetProfessors(this._professors);

  final ProfessorRepository _professors;

  // Strana po strana: sledeća strana se traži sa offset = nextOffset prethodne.
  Future<ProfessorsPage> call({int offset = 0}) => _professors.professors(offset: offset);
}
