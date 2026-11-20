import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 11, 10, 8, 30);

  ProfessorProfileDto profile(VerificationStatusDto verification) => ProfessorProfileDto(
    id: 'milica',
    fullName: 'Milica Jovanović',
    city: 'belgrade',
    bio: 'Matematika za srednju školu.',
    education: const [
      EducationDto(institution: 'Matematički fakultet', title: 'Master matematike', fromYear: 2012, toYear: 2017),
    ],
    experience: const [ExperienceDto(employer: 'Treća beogradska gimnazija', title: 'Profesor', fromYear: 2017)],
    verification: verification,
  );

  const listing = ListingDto(
    id: 'l-math',
    professorId: 'milica',
    subject: 'mathematics',
    level: 'highSchool',
    city: 'belgrade',
    description: 'Analiza i algebra',
    priceRsd: 2500,
    durationMinutes: 60,
  );

  final verifications = <String, VerificationStatusDto>{
    'not verified': const VerificationStatusDto(type: VerificationStatusDto.notVerified),
    'awaiting review': VerificationStatusDto(
      type: VerificationStatusDto.awaitingReview,
      submittedAt: at,
      diplomaFile: 'diplome/milica.pdf',
      linkedIn: 'https://www.linkedin.com/in/milica',
    ),
    'verified': VerificationStatusDto(type: VerificationStatusDto.verified, by: 'jovana', at: at),
    'rejected': VerificationStatusDto(
      type: VerificationStatusDto.rejected,
      by: 'jovana',
      at: at,
      reason: 'Diploma na slici nije čitljiva.',
    ),
  };

  for (final MapEntry(key: name, value: verification) in verifications.entries) {
    test('a profile that is $name survives a round trip', () {
      final json = profile(verification).toJson();
      expect(ProfessorProfileDto.fromJson(json).toJson(), json);
    });
  }

  test('a profile has the shape the staff endpoints already send', () {
    expect(profile(const VerificationStatusDto(type: VerificationStatusDto.notVerified)).toJson(), {
      'id': 'milica',
      'fullName': 'Milica Jovanović',
      'city': 'belgrade',
      'bio': 'Matematika za srednju školu.',
      'education': [
        {'institution': 'Matematički fakultet', 'title': 'Master matematike', 'fromYear': 2012, 'toYear': 2017},
      ],
      'experience': [
        {'employer': 'Treća beogradska gimnazija', 'title': 'Profesor', 'fromYear': 2017},
      ],
      'verification': {'type': 'not_verified'},
    });
  });

  test('a listing carries the price in whole dinars and the enums by name', () {
    expect(listing.toJson(), {
      'id': 'l-math',
      'professorId': 'milica',
      'subject': 'mathematics',
      'level': 'highSchool',
      'city': 'belgrade',
      'description': 'Analiza i algebra',
      'priceRsd': 2500,
      'durationMinutes': 60,
    });
    expect(ListingDto.fromJson(listing.toJson()).toJson(), listing.toJson());
    expect(() => ListingDto.fromJson({...listing.toJson(), 'priceRsd': 2500.5}), throwsFormatException);
  });

  test('a slot survives a round trip', () {
    final slot = SlotDto(
      id: 's-1',
      listingId: 'l-math',
      professorId: 'milica',
      start: DateTime.utc(2026, 12, 1, 10),
      durationMinutes: 60,
    );

    expect(slot.toJson()['start'], '2026-12-01T10:00:00.000Z');
    expect(SlotDto.fromJson(slot.toJson()).toJson(), slot.toJson());
  });

  test('taken slots are only slot ids', () {
    const taken = TakenSlotsDto(slotIds: ['s-1', 's-3']);

    expect(taken.toJson(), {
      'slotIds': ['s-1', 's-3'],
    });
    expect(TakenSlotsDto.fromJson(taken.toJson()).slotIds, ['s-1', 's-3']);
    expect(
      () => TakenSlotsDto.fromJson({
        'slotIds': [1, 2],
      }),
      throwsFormatException,
    );
  });

  test('a page of professors says where the next page starts, and null on the last page', () {
    final summary = ProfessorSummaryDto(
      profile: profile(const VerificationStatusDto(type: VerificationStatusDto.notVerified)),
      listings: const [listing],
    );
    final first = ProfessorsPageDto(items: [summary], nextOffset: 20);
    final last = ProfessorsPageDto(items: [summary]);

    expect(ProfessorsPageDto.fromJson(first.toJson()).nextOffset, 20);
    expect(last.toJson()['nextOffset'], isNull);
    expect(ProfessorsPageDto.fromJson(last.toJson()).nextOffset, isNull);
    expect(ProfessorsPageDto.fromJson(first.toJson()).toJson(), first.toJson());
  });

  test('a rejection carries the reason', () {
    expect(RejectionDto.fromJson(const RejectionDto(reason: 'Nije čitljivo.').toJson()).reason, 'Nije čitljivo.');
    expect(() => RejectionDto.fromJson(const {}), throwsFormatException);
  });
}
