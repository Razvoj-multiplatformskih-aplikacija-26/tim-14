import 'json.dart';

/// A verification status on the wire: `{"type": …}` plus the fields of that status.
///
/// | type              | fields                                 |
/// |-------------------|----------------------------------------|
/// | `not_verified`    | none                                   |
/// | `awaiting_review` | `submittedAt`, `diplomaFile`, `linkedIn` |
/// | `verified`        | `by`, `at`                             |
/// | `rejected`        | `by`, `at`, `reason`                   |
///
/// Anyone but an admin only ever gets `not_verified` or `verified`: the server passes every profile through the
/// domain's `visibleTo` before it is sent.
final class VerificationStatusDto {
  const VerificationStatusDto({
    required this.type,
    this.submittedAt,
    this.diplomaFile,
    this.linkedIn,
    this.by,
    this.at,
    this.reason,
  });

  static const notVerified = 'not_verified';
  static const awaitingReview = 'awaiting_review';
  static const verified = 'verified';
  static const rejected = 'rejected';

  final String type;
  final DateTime? submittedAt;
  final String? diplomaFile;
  final String? linkedIn;
  final String? by;
  final DateTime? at;
  final String? reason;

  Map<String, Object?> toJson() => {
    'type': type,
    if (submittedAt case final submittedAt?) 'submittedAt': instantToJson(submittedAt),
    'diplomaFile': ?diplomaFile,
    'linkedIn': ?linkedIn,
    'by': ?by,
    if (at case final at?) 'at': instantToJson(at),
    'reason': ?reason,
  };

  factory VerificationStatusDto.fromJson(Map<String, Object?> json) => VerificationStatusDto(
    type: jsonString(json, 'type'),
    submittedAt: jsonOptionalInstant(json, 'submittedAt'),
    diplomaFile: jsonOptionalString(json, 'diplomaFile'),
    linkedIn: jsonOptionalString(json, 'linkedIn'),
    by: jsonOptionalString(json, 'by'),
    at: jsonOptionalInstant(json, 'at'),
    reason: jsonOptionalString(json, 'reason'),
  );
}

/// One school or degree. [toYear] is absent while it is still ongoing.
final class EducationDto {
  const EducationDto({required this.institution, required this.title, required this.fromYear, this.toYear});

  final String institution;
  final String title;
  final int fromYear;
  final int? toYear;

  Map<String, Object?> toJson() => {
    'institution': institution,
    'title': title,
    'fromYear': fromYear,
    'toYear': ?toYear,
  };

  factory EducationDto.fromJson(Map<String, Object?> json) => EducationDto(
    institution: jsonString(json, 'institution'),
    title: jsonString(json, 'title'),
    fromYear: jsonInt(json, 'fromYear'),
    toYear: jsonOptionalInt(json, 'toYear'),
  );
}

/// One job. [toYear] is absent for the current one.
final class ExperienceDto {
  const ExperienceDto({required this.employer, required this.title, required this.fromYear, this.toYear});

  final String employer;
  final String title;
  final int fromYear;
  final int? toYear;

  Map<String, Object?> toJson() => {'employer': employer, 'title': title, 'fromYear': fromYear, 'toYear': ?toYear};

  factory ExperienceDto.fromJson(Map<String, Object?> json) => ExperienceDto(
    employer: jsonString(json, 'employer'),
    title: jsonString(json, 'title'),
    fromYear: jsonInt(json, 'fromYear'),
    toYear: jsonOptionalInt(json, 'toYear'),
  );
}

/// [city] is the name of the domain's `City`, for example `belgrade`.
final class ProfessorProfileDto {
  const ProfessorProfileDto({
    required this.id,
    required this.fullName,
    required this.city,
    required this.bio,
    required this.education,
    required this.experience,
    required this.verification,
  });

  final String id;
  final String fullName;
  final String city;
  final String bio;
  final List<EducationDto> education;
  final List<ExperienceDto> experience;
  final VerificationStatusDto verification;

  Map<String, Object?> toJson() => {
    'id': id,
    'fullName': fullName,
    'city': city,
    'bio': bio,
    'education': [for (final item in education) item.toJson()],
    'experience': [for (final item in experience) item.toJson()],
    'verification': verification.toJson(),
  };

  factory ProfessorProfileDto.fromJson(Map<String, Object?> json) => ProfessorProfileDto(
    id: jsonString(json, 'id'),
    fullName: jsonString(json, 'fullName'),
    city: jsonString(json, 'city'),
    bio: jsonString(json, 'bio'),
    education: [for (final item in jsonObjects(json, 'education')) EducationDto.fromJson(item)],
    experience: [for (final item in jsonObjects(json, 'experience')) ExperienceDto.fromJson(item)],
    verification: VerificationStatusDto.fromJson(jsonObject(json['verification'])),
  );
}

/// A listing. Money is whole dinars, never a decimal. [subject], [level] and [city] are the names of the domain's
/// enums, for example `mathematics`, `highSchool` and `belgrade`.
final class ListingDto {
  const ListingDto({
    required this.id,
    required this.professorId,
    required this.subject,
    required this.level,
    required this.city,
    required this.description,
    required this.priceRsd,
    required this.durationMinutes,
  });

  final String id;
  final String professorId;
  final String subject;
  final String level;
  final String city;
  final String description;
  final int priceRsd;
  final int durationMinutes;

  Map<String, Object?> toJson() => {
    'id': id,
    'professorId': professorId,
    'subject': subject,
    'level': level,
    'city': city,
    'description': description,
    'priceRsd': priceRsd,
    'durationMinutes': durationMinutes,
  };

  factory ListingDto.fromJson(Map<String, Object?> json) => ListingDto(
    id: jsonString(json, 'id'),
    professorId: jsonString(json, 'professorId'),
    subject: jsonString(json, 'subject'),
    level: jsonString(json, 'level'),
    city: jsonString(json, 'city'),
    description: jsonString(json, 'description'),
    priceRsd: jsonInt(json, 'priceRsd'),
    durationMinutes: jsonInt(json, 'durationMinutes'),
  );
}

final class SlotDto {
  const SlotDto({
    required this.id,
    required this.listingId,
    required this.professorId,
    required this.start,
    required this.durationMinutes,
  });

  final String id;
  final String listingId;
  final String professorId;
  final DateTime start;
  final int durationMinutes;

  Map<String, Object?> toJson() => {
    'id': id,
    'listingId': listingId,
    'professorId': professorId,
    'start': instantToJson(start),
    'durationMinutes': durationMinutes,
  };

  factory SlotDto.fromJson(Map<String, Object?> json) => SlotDto(
    id: jsonString(json, 'id'),
    listingId: jsonString(json, 'listingId'),
    professorId: jsonString(json, 'professorId'),
    start: jsonInstant(json, 'start'),
    durationMinutes: jsonInt(json, 'durationMinutes'),
  );
}

/// `GET /professors/{id}/taken-slots`: only which slots already have a confirmed lesson. It never carries other
/// students' requests or messages.
final class TakenSlotsDto {
  const TakenSlotsDto({required this.slotIds});

  final List<String> slotIds;

  Map<String, Object?> toJson() => {'slotIds': slotIds};

  factory TakenSlotsDto.fromJson(Map<String, Object?> json) => TakenSlotsDto(slotIds: jsonStrings(json, 'slotIds'));
}

/// One row of the professor list: the profile and its listings, so the card can show subjects and prices.
final class ProfessorSummaryDto {
  const ProfessorSummaryDto({required this.profile, required this.listings});

  final ProfessorProfileDto profile;
  final List<ListingDto> listings;

  Map<String, Object?> toJson() => {
    'profile': profile.toJson(),
    'listings': [for (final listing in listings) listing.toJson()],
  };

  factory ProfessorSummaryDto.fromJson(Map<String, Object?> json) => ProfessorSummaryDto(
    profile: ProfessorProfileDto.fromJson(jsonObject(json['profile'])),
    listings: [for (final listing in jsonObjects(json, 'listings')) ListingDto.fromJson(listing)],
  );
}

/// One page of `GET /professors?offset=&limit=`. [nextOffset] is the offset of the next page, or null on the last.
final class ProfessorsPageDto {
  const ProfessorsPageDto({required this.items, this.nextOffset});

  final List<ProfessorSummaryDto> items;
  final int? nextOffset;

  Map<String, Object?> toJson() => {
    'items': [for (final item in items) item.toJson()],
    'nextOffset': nextOffset,
  };

  factory ProfessorsPageDto.fromJson(Map<String, Object?> json) => ProfessorsPageDto(
    items: [for (final item in jsonObjects(json, 'items')) ProfessorSummaryDto.fromJson(item)],
    nextOffset: jsonOptionalInt(json, 'nextOffset'),
  );
}

/// `POST /verifications/{id}/rejection`: why the admin rejected the profile.
final class RejectionDto {
  const RejectionDto({required this.reason});

  final String reason;

  Map<String, Object?> toJson() => {'reason': reason};

  factory RejectionDto.fromJson(Map<String, Object?> json) => RejectionDto(reason: jsonString(json, 'reason'));
}
