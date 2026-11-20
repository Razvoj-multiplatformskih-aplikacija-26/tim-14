import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  // The example from §3.4 of the plan, as the server sends it.
  final confirmedJson = <String, Object?>{
    'id': 'l-1',
    'slotId': 's-1',
    'listingId': 'li-1',
    'professorId': 'milica',
    'professorName': 'Milica Jovanović',
    'studentId': 'ana-markovic',
    'studentName': 'Ana Marković',
    'start': '2026-11-20T16:00:00.000Z',
    'durationMinutes': 60,
    'message': 'Treba mi pomoć oko integrala.',
    'createdAt': '2026-11-14T10:00:00.000Z',
    'status': {'type': 'confirmed', 'at': '2026-11-15T09:00:00.000Z'},
  };

  LessonDto withStatus(LessonStatusDto status) => LessonDto(
    id: 'l-1',
    slotId: 's-1',
    listingId: 'li-1',
    professorId: 'milica',
    professorName: 'Milica Jovanović',
    studentId: 'ana-markovic',
    studentName: 'Ana Marković',
    start: DateTime.utc(2026, 11, 20, 16),
    durationMinutes: 60,
    message: 'Treba mi pomoć oko integrala.',
    createdAt: DateTime.utc(2026, 11, 14, 10),
    status: status,
  );

  final at = DateTime.utc(2026, 11, 15, 9);
  final statuses = <String, LessonStatusDto>{
    'pending': const LessonStatusDto(type: LessonStatusDto.pending),
    'confirmed': LessonStatusDto(type: LessonStatusDto.confirmed, at: at),
    'rejected': LessonStatusDto(type: LessonStatusDto.rejected, cause: LessonStatusDto.slotTaken, at: at),
    'cancelled': LessonStatusDto(type: LessonStatusDto.cancelled, by: 'ana-markovic', at: at),
    'held with a note': LessonStatusDto(type: LessonStatusDto.held, at: at, note: 'Uradili smo integrale.'),
    'held without a note': LessonStatusDto(type: LessonStatusDto.held, at: at),
    'no-show': LessonStatusDto(type: LessonStatusDto.noShow, at: at),
  };

  test('a lesson reads the JSON from the plan and writes exactly the same JSON back', () {
    final lesson = LessonDto.fromJson(confirmedJson);

    expect(lesson.professorName, 'Milica Jovanović');
    expect(lesson.start, DateTime.utc(2026, 11, 20, 16));
    expect(lesson.status.type, LessonStatusDto.confirmed);
    expect(lesson.toJson(), confirmedJson);
  });

  for (final MapEntry(key: name, value: status) in statuses.entries) {
    test('a lesson that is $name survives a round trip', () {
      final json = withStatus(status).toJson();
      expect(LessonDto.fromJson(json).toJson(), json);
    });
  }

  test('a status carries only its own fields', () {
    expect(const LessonStatusDto(type: LessonStatusDto.pending).toJson(), {'type': 'pending'});
    expect(LessonStatusDto(type: LessonStatusDto.held, at: at).toJson(), {
      'type': 'held',
      'at': '2026-11-15T09:00:00.000Z',
    });
  });

  test('times go out in UTC, even when given in local time', () {
    final local = DateTime.utc(2026, 11, 20, 16).toLocal();
    final lesson = LessonDto.fromJson(confirmedJson);
    final shifted = LessonDto(
      id: lesson.id,
      slotId: lesson.slotId,
      listingId: lesson.listingId,
      professorId: lesson.professorId,
      professorName: lesson.professorName,
      studentId: lesson.studentId,
      studentName: lesson.studentName,
      start: local,
      durationMinutes: lesson.durationMinutes,
      message: lesson.message,
      createdAt: lesson.createdAt,
      status: lesson.status,
    );

    expect(shifted.toJson()['start'], '2026-11-20T16:00:00.000Z');
  });

  test('an older client reads a lesson that carries a field it does not know yet', () {
    final lesson = LessonDto.fromJson({...confirmedJson, 'room': 'Sala 3'});

    expect(lesson.id, 'l-1');
    expect(lesson.toJson(), confirmedJson);
  });

  test('a missing field, a wrong type and a time without a zone are refused', () {
    expect(() => LessonDto.fromJson({...confirmedJson}..remove('studentName')), throwsFormatException);
    expect(() => LessonDto.fromJson({...confirmedJson, 'durationMinutes': '60'}), throwsFormatException);
    expect(() => LessonDto.fromJson({...confirmedJson, 'start': '2026-11-20T16:00:00'}), throwsFormatException);
    expect(() => LessonDto.fromJson({...confirmedJson, 'status': 'confirmed'}), throwsFormatException);
  });

  test('a confirmation carries the confirmed lesson and the rejected ones', () {
    final confirmation = ConfirmationDto(
      confirmed: withStatus(LessonStatusDto(type: LessonStatusDto.confirmed, at: at)),
      rejected: [withStatus(LessonStatusDto(type: LessonStatusDto.rejected, cause: LessonStatusDto.slotTaken, at: at))],
    );

    final json = confirmation.toJson();
    expect(ConfirmationDto.fromJson(json).toJson(), json);
    expect(ConfirmationDto.fromJson({...json, 'rejected': <Object?>[]}).rejected, isEmpty);
  });

  test('a new request carries only the slot and the message', () {
    const request = NewLessonDto(slotId: 's-1', message: 'Zdravo');

    expect(request.toJson(), {'slotId': 's-1', 'message': 'Zdravo'});
    expect(NewLessonDto.fromJson(request.toJson()).toJson(), request.toJson());
    expect(() => NewLessonDto.fromJson({'slotId': 's-1'}), throwsFormatException);
  });

  test('held may come with or without a note', () {
    expect(const HeldDto().toJson(), isEmpty);
    expect(HeldDto.fromJson(const {}).note, isNull);
    expect(HeldDto.fromJson(const HeldDto(note: 'Odlično.').toJson()).note, 'Odlično.');
  });
}
