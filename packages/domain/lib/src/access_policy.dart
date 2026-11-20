import 'identifiers.dart';
import 'lesson/lesson.dart';
import 'professor/professor_profile.dart';
import 'user.dart';

abstract final class AccessPolicy {
  // Ko sme u koju aplikaciju. SessionBloc svake aplikacije dobija jedno od ova dva pravila.
  static bool canUseMobileApp(User user) => user.role == Role.student;

  static bool canUseBackoffice(User user) => user.role == Role.professor || user.role == Role.admin;

  // Čas vide samo njegov učenik i njegov profesor. Server tuđ čas prikazuje kao da ne postoji (404).
  static bool canView(User user, Lesson lesson) => _isStudentOf(user, lesson) || _isProfessorOf(user, lesson);

  // Diplomu, LinkedIn i razlog odbijanja vidi samo administrator. null je posetilac bez prijave.
  static bool canSeeVerificationDetails(User? user) => user?.role == Role.admin;

  static bool canRequestLesson(User user) => user.role == Role.student;

  static bool canWithdraw(User user, Lesson lesson) => _isStudentOf(user, lesson);

  static bool canDecide(User user, Lesson lesson) => _isProfessorOf(user, lesson);

  static bool canCancel(User user, Lesson lesson) => _isStudentOf(user, lesson) || _isProfessorOf(user, lesson);

  static bool canRecordOutcome(User user, Lesson lesson) => _isProfessorOf(user, lesson);

  static bool canWriteReview(User user, Lesson lesson) => _isStudentOf(user, lesson);

  static bool canManageSlots(User user, {required UserId professorId}) =>
      user.role == Role.professor && user.id == professorId;

  static bool canSubmitVerification(User user, ProfessorProfile profile) =>
      user.role == Role.professor && user.id == profile.id;

  static bool canDecideVerification(User user) => user.role == Role.admin;

  static bool _isStudentOf(User user, Lesson lesson) => user.role == Role.student && user.id == lesson.studentId;

  static bool _isProfessorOf(User user, Lesson lesson) => user.role == Role.professor && user.id == lesson.professorId;
}
