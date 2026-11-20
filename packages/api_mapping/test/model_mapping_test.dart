import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

/// What the other side gets: the JSON text, decoded again.
Map<String, Object?> overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  final at = DateTime.utc(2026, 11, 15, 9);
  final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/milica').valueOrNull!;
  final reason = RejectionReason.parse('Diploma nije čitljiva.').valueOrNull!;

  final pending = Lesson(
    id: const LessonId('l-1'),
    slotId: const SlotId('s-1'),
    listingId: const ListingId('l-math'),
    professorId: const UserId('milica'),
    professorName: 'Milica Jovanović',
    studentId: const UserId('ana-markovic'),
    studentName: 'Ana Marković',
    start: DateTime.utc(2026, 11, 20, 16),
    duration: LessonDuration.minutes90,
    message: RequestMessage.parse('Treba mi pomoć oko integrala 🙂').valueOrNull!,
    createdAt: DateTime.utc(2026, 11, 14, 10),
  );

  Lesson lessonFromTheWire(Lesson lesson) => LessonDto.fromJson(overTheWire(lesson.toDto().toJson())).toDomain();

  group('a lesson survives the trip to the other side and back', () {
    final statuses = <LessonStatus>[
      const Pending(),
      Confirmed(at: at),
      Rejected(cause: RejectionCause.byProfessor, at: at),
      Rejected(cause: RejectionCause.slotTaken, at: at),
      Cancelled(by: const UserId('ana-markovic'), at: at),
      Held(at: at, note: LessonNote.parse('Uradili smo integrale.').valueOrNull),
      Held(at: at),
      NoShow(at: at),
    ];

    for (final status in statuses) {
      test('$status', () {
        final lesson = pending.copyWith(status: status);
        expect(lessonFromTheWire(lesson), lesson);
      });
    }
  });

  test('a lesson goes out with the JSON of the plan', () {
    expect(pending.copyWith(status: Confirmed(at: at)).toDto().toJson(), {
      'id': 'l-1',
      'slotId': 's-1',
      'listingId': 'l-math',
      'professorId': 'milica',
      'professorName': 'Milica Jovanović',
      'studentId': 'ana-markovic',
      'studentName': 'Ana Marković',
      'start': '2026-11-20T16:00:00.000Z',
      'durationMinutes': 90,
      'message': 'Treba mi pomoć oko integrala 🙂',
      'createdAt': '2026-11-14T10:00:00.000Z',
      'status': {'type': 'confirmed', 'at': '2026-11-15T09:00:00.000Z'},
    });
  });

  test('a confirmation survives the trip with the lessons rejected with it', () {
    final confirmation = Confirmation(
      confirmed: pending.copyWith(status: Confirmed(at: at)),
      rejected: [
        pending.copyWith(
          status: Rejected(cause: RejectionCause.slotTaken, at: at),
        ),
      ],
    );

    expect(ConfirmationDto.fromJson(overTheWire(confirmation.toDto().toJson())).toDomain(), confirmation);
  });

  group('values the domain refuses do not get in', () {
    Map<String, Object?> lessonJson() => overTheWire(pending.toDto().toJson());

    test('a message the domain refuses', () {
      final json = lessonJson()..['message'] = 'a' * 301;
      expect(() => LessonDto.fromJson(json).toDomain(), throwsFormatException);
    });

    test('a length no lesson has', () {
      final json = lessonJson()..['durationMinutes'] = 50;
      expect(() => LessonDto.fromJson(json).toDomain(), throwsFormatException);
    });

    test('a status this side does not know, or one without its fields', () {
      expect(() => const LessonStatusDto(type: 'expired').toDomain(), throwsFormatException);
      expect(() => const LessonStatusDto(type: LessonStatusDto.confirmed).toDomain(), throwsFormatException);
      expect(
        () => LessonStatusDto(type: LessonStatusDto.rejected, cause: 'by_admin', at: at).toDomain(),
        throwsFormatException,
      );
    });

    test('a price, a city and a role this side does not accept', () {
      const listing = ListingDto(
        id: 'l-math',
        professorId: 'milica',
        subject: 'mathematics',
        level: 'highSchool',
        city: 'belgrade',
        description: '',
        priceRsd: 0,
        durationMinutes: 60,
      );
      expect(listing.toDomain, throwsFormatException);
      expect(
        () => ListingDto.fromJson({...listing.toJson(), 'priceRsd': 2000, 'city': 'atlantis'}).toDomain(),
        throwsFormatException,
      );
      expect(const UserDto(id: 'x', name: 'X', role: 'janitor').toDomain, throwsFormatException);
    });
  });

  group('a profile survives the trip in every verification status', () {
    const base = ProfessorProfile(
      id: UserId('milica'),
      fullName: 'Milica Jovanović',
      city: City.belgrade,
      bio: 'Matematika za srednju školu.',
      education: [(institution: 'Matematički fakultet', title: 'Master', fromYear: 2012, toYear: 2017)],
      experience: [(employer: 'Treća beogradska gimnazija', title: 'Profesor', fromYear: 2017, toYear: null)],
    );

    final verifications = <VerificationStatus>[
      const NotVerified(),
      AwaitingReview(submittedAt: at, diplomaFile: 'diplome/milica.pdf', linkedIn: linkedIn),
      Verified(by: const UserId('jovana'), at: at),
      VerificationRejected(by: const UserId('jovana'), at: at, reason: reason),
    ];

    for (final verification in verifications) {
      test('$verification', () {
        final profile = base.copyWith(verification: verification);
        expect(ProfessorProfileDto.fromJson(overTheWire(profile.toDto().toJson())).toDomain(), profile);
      });
    }

    test('a LinkedIn address the domain refuses does not get in', () {
      final json = overTheWire(base.copyWith(verification: verifications[1]).toDto().toJson());
      (json['verification']! as Map<String, Object?>)['linkedIn'] = 'https://example.com/milica';
      expect(() => ProfessorProfileDto.fromJson(json).toDomain(), throwsFormatException);
    });
  });

  test('a page of professors, a listing and a slot survive the trip', () {
    final listing = Listing(
      id: const ListingId('l-math'),
      professorId: const UserId('milica'),
      subject: Subject.mathematics,
      level: Level.highSchool,
      city: City.belgrade,
      description: 'Analiza i algebra',
      price: Price.parse(2500).valueOrNull!,
      duration: LessonDuration.minutes60,
    );
    final slot = Slot(
      id: const SlotId('s-1'),
      listingId: listing.id,
      professorId: listing.professorId,
      start: DateTime.utc(2026, 12, 1, 10),
      duration: LessonDuration.minutes60,
    );
    const profile = ProfessorProfile(id: UserId('milica'), fullName: 'Milica', city: City.belgrade, bio: '');
    final page = ProfessorsPage(
      items: [
        ProfessorSummary(profile: profile, listings: [listing]),
      ],
      nextOffset: 20,
    );

    final back = ProfessorsPageDto.fromJson(overTheWire(page.toDto().toJson())).toDomain();

    expect(back.nextOffset, 20);
    expect(back.items.single.profile, profile);
    expect(back.items.single.listings, [listing]);
    expect(SlotDto.fromJson(overTheWire(slot.toDto().toJson())).toDomain(), slot);
    expect(
      ProfessorsPageDto.fromJson(overTheWire(const ProfessorsPage(items: []).toDto().toJson())).nextOffset,
      isNull,
    );
  });

  test('taken slots and a user survive the trip', () {
    final taken = {const SlotId('s-1'), const SlotId('s-3')};
    expect(TakenSlotsDto.fromJson(overTheWire(taken.toDto().toJson())).toDomain(), taken);

    const user = User(id: UserId('ana-markovic'), name: 'Ana Marković', role: Role.student);
    expect(UserDto.fromJson(overTheWire(user.toDto().toJson())).toDomain(), user);
  });
}
