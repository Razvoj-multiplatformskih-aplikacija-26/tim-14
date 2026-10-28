import 'package:domain/domain.dart';

final now = DateTime.utc(2026, 11, 2, 10);
final lessonStart = DateTime.utc(2026, 11, 5, 16);

const student = User(id: UserId('u-student'), name: 'Ana', role: Role.student);
const otherStudent = User(id: UserId('u-student-2'), name: 'Marko', role: Role.student);
const professor = User(id: UserId('u-professor'), name: 'Jelena', role: Role.professor);
const otherProfessor = User(id: UserId('u-professor-2'), name: 'Nikola', role: Role.professor);
const admin = User(id: UserId('u-admin'), name: 'Admin', role: Role.admin);

const math = ListingId('l-math');
const physics = ListingId('l-physics');

final message = RequestMessage.parse('Treba mi pomoć oko integrala.').valueOrNull!;

Slot slotAt(
  DateTime start, {
  String id = 's-1',
  ListingId listingId = math,
  UserId? professorId,
  LessonDuration duration = LessonDuration.minutes60,
}) => Slot(
  id: SlotId(id),
  listingId: listingId,
  professorId: professorId ?? professor.id,
  start: start,
  duration: duration,
);

Lesson lessonAt(
  DateTime start, {
  String id = 'lesson-1',
  String slotId = 's-1',
  UserId? studentId,
  LessonStatus status = const Pending(),
}) => Lesson(
  id: LessonId(id),
  slotId: SlotId(slotId),
  listingId: math,
  professorId: professor.id,
  studentId: studentId ?? student.id,
  start: start,
  duration: LessonDuration.minutes60,
  message: message,
  createdAt: now.subtract(const Duration(days: 1)),
  status: status,
);
