import 'json.dart';

/// A lesson status on the wire: `{"type": …}` plus the fields of that status.
///
/// | type        | fields             |
/// |-------------|--------------------|
/// | `pending`   | none               |
/// | `confirmed` | `at`               |
/// | `rejected`  | `cause`, `at`      |
/// | `cancelled` | `by`, `at`         |
/// | `held`      | `at`, `note?`      |
/// | `no_show`   | `at`               |
///
/// The DTO does not check which fields belong to which type. The mapping does, because only it knows the domain.
final class LessonStatusDto {
  const LessonStatusDto({required this.type, this.at, this.cause, this.by, this.note});

  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
  static const held = 'held';
  static const noShow = 'no_show';

  static const byProfessor = 'by_professor';
  static const slotTaken = 'slot_taken';

  final String type;
  final DateTime? at;

  /// [byProfessor] or [slotTaken], only for [rejected].
  final String? cause;

  /// The id of the user who cancelled, only for [cancelled].
  final String? by;
  final String? note;

  Map<String, Object?> toJson() => {
    'type': type,
    'cause': ?cause,
    'by': ?by,
    if (at case final at?) 'at': instantToJson(at),
    'note': ?note,
  };

  factory LessonStatusDto.fromJson(Map<String, Object?> json) => LessonStatusDto(
    type: jsonString(json, 'type'),
    at: jsonOptionalInstant(json, 'at'),
    cause: jsonOptionalString(json, 'cause'),
    by: jsonOptionalString(json, 'by'),
    note: jsonOptionalString(json, 'note'),
  );
}

/// A lesson as the server sends it. The names are copied when the request is made, so the clients need no
/// lookup of their own.
final class LessonDto {
  const LessonDto({
    required this.id,
    required this.slotId,
    required this.listingId,
    required this.professorId,
    required this.professorName,
    required this.studentId,
    required this.studentName,
    required this.start,
    required this.durationMinutes,
    required this.message,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String slotId;
  final String listingId;
  final String professorId;
  final String professorName;
  final String studentId;
  final String studentName;
  final DateTime start;
  final int durationMinutes;
  final String message;
  final DateTime createdAt;
  final LessonStatusDto status;

  Map<String, Object?> toJson() => {
    'id': id,
    'slotId': slotId,
    'listingId': listingId,
    'professorId': professorId,
    'professorName': professorName,
    'studentId': studentId,
    'studentName': studentName,
    'start': instantToJson(start),
    'durationMinutes': durationMinutes,
    'message': message,
    'createdAt': instantToJson(createdAt),
    'status': status.toJson(),
  };

  factory LessonDto.fromJson(Map<String, Object?> json) => LessonDto(
    id: jsonString(json, 'id'),
    slotId: jsonString(json, 'slotId'),
    listingId: jsonString(json, 'listingId'),
    professorId: jsonString(json, 'professorId'),
    professorName: jsonString(json, 'professorName'),
    studentId: jsonString(json, 'studentId'),
    studentName: jsonString(json, 'studentName'),
    start: jsonInstant(json, 'start'),
    durationMinutes: jsonInt(json, 'durationMinutes'),
    message: jsonString(json, 'message'),
    createdAt: jsonInstant(json, 'createdAt'),
    status: LessonStatusDto.fromJson(jsonObject(json['status'])),
  );
}

/// `POST /lessons`. Only what the student chooses: the server reads everything else (time, professor, names)
/// from its own database and never from the client.
final class NewLessonDto {
  const NewLessonDto({required this.slotId, required this.message});

  final String slotId;
  final String message;

  Map<String, Object?> toJson() => {'slotId': slotId, 'message': message};

  factory NewLessonDto.fromJson(Map<String, Object?> json) =>
      NewLessonDto(slotId: jsonString(json, 'slotId'), message: jsonString(json, 'message'));
}

/// `POST /lessons/{id}/held`, with an optional note.
final class HeldDto {
  const HeldDto({this.note});

  final String? note;

  Map<String, Object?> toJson() => {'note': ?note};

  factory HeldDto.fromJson(Map<String, Object?> json) => HeldDto(note: jsonOptionalString(json, 'note'));
}

/// The answer to `POST /lessons/{id}/confirmation`: the confirmed lesson and the requests for the same slot that
/// were rejected with it, in one answer because the server writes them in one transaction.
final class ConfirmationDto {
  const ConfirmationDto({required this.confirmed, required this.rejected});

  final LessonDto confirmed;
  final List<LessonDto> rejected;

  Map<String, Object?> toJson() => {
    'confirmed': confirmed.toJson(),
    'rejected': [for (final lesson in rejected) lesson.toJson()],
  };

  factory ConfirmationDto.fromJson(Map<String, Object?> json) => ConfirmationDto(
    confirmed: LessonDto.fromJson(jsonObject(json['confirmed'])),
    rejected: [for (final lesson in jsonObjects(json, 'rejected')) LessonDto.fromJson(lesson)],
  );
}
