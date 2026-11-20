import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'accepted.dart';

extension LessonStatusMapping on LessonStatus {
  LessonStatusDto toDto() => switch (this) {
    Pending() => const LessonStatusDto(type: LessonStatusDto.pending),
    Confirmed(:final at) => LessonStatusDto(type: LessonStatusDto.confirmed, at: at),
    Rejected(:final cause, :final at) => LessonStatusDto(type: LessonStatusDto.rejected, cause: cause.toDto(), at: at),
    Cancelled(:final by, :final at) => LessonStatusDto(type: LessonStatusDto.cancelled, by: by.value, at: at),
    Held(:final at, :final note) => LessonStatusDto(type: LessonStatusDto.held, at: at, note: note?.text),
    NoShow(:final at) => LessonStatusDto(type: LessonStatusDto.noShow, at: at),
  };
}

extension on RejectionCause {
  String toDto() => switch (this) {
    RejectionCause.byProfessor => LessonStatusDto.byProfessor,
    RejectionCause.slotTaken => LessonStatusDto.slotTaken,
  };
}

RejectionCause _causeOf(String cause) => switch (cause) {
  LessonStatusDto.byProfessor => RejectionCause.byProfessor,
  LessonStatusDto.slotTaken => RejectionCause.slotTaken,
  _ => throw FormatException('Unknown rejection cause', cause),
};

extension LessonStatusDtoMapping on LessonStatusDto {
  /// A type this side does not know, or a type without its fields, is a [FormatException].
  LessonStatus toDomain() => switch (this) {
    LessonStatusDto(type: LessonStatusDto.pending) => const Pending(),
    LessonStatusDto(type: LessonStatusDto.confirmed, :final at?) => Confirmed(at: at),
    LessonStatusDto(type: LessonStatusDto.rejected, :final cause?, :final at?) => Rejected(
      cause: _causeOf(cause),
      at: at,
    ),
    LessonStatusDto(type: LessonStatusDto.cancelled, :final by?, :final at?) => Cancelled(by: UserId(by), at: at),
    LessonStatusDto(type: LessonStatusDto.held, :final at?, :final note) => Held(
      at: at,
      note: note == null ? null : accepted(LessonNote.parse(note)),
    ),
    LessonStatusDto(type: LessonStatusDto.noShow, :final at?) => NoShow(at: at),
    _ => throw FormatException('Unknown lesson status or missing fields', type),
  };
}

extension LessonMapping on Lesson {
  LessonDto toDto() => LessonDto(
    id: id.value,
    slotId: slotId.value,
    listingId: listingId.value,
    professorId: professorId.value,
    professorName: professorName,
    studentId: studentId.value,
    studentName: studentName,
    start: start,
    durationMinutes: duration.minutes,
    message: message.text,
    createdAt: createdAt,
    status: status.toDto(),
  );
}

extension LessonDtoMapping on LessonDto {
  Lesson toDomain() => Lesson(
    id: LessonId(id),
    slotId: SlotId(slotId),
    listingId: ListingId(listingId),
    professorId: UserId(professorId),
    professorName: professorName,
    studentId: UserId(studentId),
    studentName: studentName,
    start: start,
    duration: durationOf(durationMinutes),
    message: accepted(RequestMessage.parse(message)),
    createdAt: createdAt,
    status: status.toDomain(),
  );
}

extension ConfirmationMapping on Confirmation {
  ConfirmationDto toDto() =>
      ConfirmationDto(confirmed: confirmed.toDto(), rejected: [for (final lesson in rejected) lesson.toDto()]);
}

extension ConfirmationDtoMapping on ConfirmationDto {
  Confirmation toDomain() =>
      Confirmation(confirmed: confirmed.toDomain(), rejected: [for (final lesson in rejected) lesson.toDomain()]);
}
