import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'accepted.dart';

extension VerificationStatusMapping on VerificationStatus {
  VerificationStatusDto toDto() => switch (this) {
    NotVerified() => const VerificationStatusDto(type: VerificationStatusDto.notVerified),
    AwaitingReview(:final submittedAt, :final diplomaFile, :final linkedIn) => VerificationStatusDto(
      type: VerificationStatusDto.awaitingReview,
      submittedAt: submittedAt,
      diplomaFile: diplomaFile,
      linkedIn: linkedIn.value,
    ),
    Verified(:final by, :final at) => VerificationStatusDto(type: VerificationStatusDto.verified, by: by.value, at: at),
    VerificationRejected(:final by, :final at, :final reason) => VerificationStatusDto(
      type: VerificationStatusDto.rejected,
      by: by.value,
      at: at,
      reason: reason.text,
    ),
  };
}

extension VerificationStatusDtoMapping on VerificationStatusDto {
  VerificationStatus toDomain() => switch (this) {
    VerificationStatusDto(type: VerificationStatusDto.notVerified) => const NotVerified(),
    VerificationStatusDto(
      type: VerificationStatusDto.awaitingReview,
      :final submittedAt?,
      :final diplomaFile?,
      :final linkedIn?,
    ) =>
      AwaitingReview(
        submittedAt: submittedAt,
        diplomaFile: diplomaFile,
        linkedIn: accepted(LinkedInUrl.parse(linkedIn)),
      ),
    VerificationStatusDto(type: VerificationStatusDto.verified, :final by?, :final at?) => Verified(
      by: UserId(by),
      at: at,
    ),
    VerificationStatusDto(type: VerificationStatusDto.rejected, :final by?, :final at?, :final reason?) =>
      VerificationRejected(by: UserId(by), at: at, reason: accepted(RejectionReason.parse(reason))),
    _ => throw FormatException('Unknown verification status or missing fields', type),
  };
}

extension ProfessorProfileMapping on ProfessorProfile {
  ProfessorProfileDto toDto() => ProfessorProfileDto(
    id: id.value,
    fullName: fullName,
    city: city.name,
    bio: bio,
    education: [
      for (final item in education)
        EducationDto(institution: item.institution, title: item.title, fromYear: item.fromYear, toYear: item.toYear),
    ],
    experience: [
      for (final item in experience)
        ExperienceDto(employer: item.employer, title: item.title, fromYear: item.fromYear, toYear: item.toYear),
    ],
    verification: verification.toDto(),
  );
}

extension ProfessorProfileDtoMapping on ProfessorProfileDto {
  ProfessorProfile toDomain() => ProfessorProfile(
    id: UserId(id),
    fullName: fullName,
    city: byName(City.values, city),
    bio: bio,
    education: [
      for (final item in education)
        (institution: item.institution, title: item.title, fromYear: item.fromYear, toYear: item.toYear),
    ],
    experience: [
      for (final item in experience)
        (employer: item.employer, title: item.title, fromYear: item.fromYear, toYear: item.toYear),
    ],
    verification: verification.toDomain(),
  );
}

extension ListingMapping on Listing {
  ListingDto toDto() => ListingDto(
    id: id.value,
    professorId: professorId.value,
    subject: subject.name,
    level: level.name,
    city: city.name,
    description: description,
    priceRsd: price.dinars,
    durationMinutes: duration.minutes,
  );
}

extension ListingDtoMapping on ListingDto {
  Listing toDomain() => Listing(
    id: ListingId(id),
    professorId: UserId(professorId),
    subject: byName(Subject.values, subject),
    level: byName(Level.values, level),
    city: byName(City.values, city),
    description: description,
    price: accepted(Price.parse(priceRsd)),
    duration: durationOf(durationMinutes),
  );
}

extension SlotMapping on Slot {
  SlotDto toDto() => SlotDto(
    id: id.value,
    listingId: listingId.value,
    professorId: professorId.value,
    start: start,
    durationMinutes: duration.minutes,
  );
}

extension SlotDtoMapping on SlotDto {
  Slot toDomain() => Slot(
    id: SlotId(id),
    listingId: ListingId(listingId),
    professorId: UserId(professorId),
    start: start,
    duration: durationOf(durationMinutes),
  );
}

/// The answer to `GET /professors/{id}/taken-slots`.
extension TakenSlotsMapping on Set<SlotId> {
  TakenSlotsDto toDto() => TakenSlotsDto(slotIds: [for (final slot in this) slot.value]);
}

extension TakenSlotsDtoMapping on TakenSlotsDto {
  Set<SlotId> toDomain() => {for (final id in slotIds) SlotId(id)};
}

extension ProfessorSummaryMapping on ProfessorSummary {
  ProfessorSummaryDto toDto() =>
      ProfessorSummaryDto(profile: profile.toDto(), listings: [for (final listing in listings) listing.toDto()]);
}

extension ProfessorSummaryDtoMapping on ProfessorSummaryDto {
  ProfessorSummary toDomain() =>
      ProfessorSummary(profile: profile.toDomain(), listings: [for (final listing in listings) listing.toDomain()]);
}

extension ProfessorsPageMapping on ProfessorsPage {
  ProfessorsPageDto toDto() =>
      ProfessorsPageDto(items: [for (final item in items) item.toDto()], nextOffset: nextOffset);
}

extension ProfessorsPageDtoMapping on ProfessorsPageDto {
  ProfessorsPage toDomain() =>
      ProfessorsPage(items: [for (final item in items) item.toDomain()], nextOffset: nextOffset);
}
