import 'dart:async';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final now = DateTime.utc(2026, 11, 2, 10);

const student = User(id: UserId('ana'), name: 'Ana', role: Role.student);
const professor = User(id: UserId('milica'), name: 'Milica', role: Role.professor);
const admin = User(id: UserId('jovana'), name: 'Jovana', role: Role.admin);

final message = RequestMessage.parse('Treba mi pomoć oko integrala.').valueOrNull!;

final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/jelena-petrovic').valueOrNull!;

Lesson lessonAt(DateTime start, {required String id, String? slot, LessonStatus status = const Pending()}) => Lesson(
  id: LessonId(id),
  slotId: SlotId(slot ?? 's-$id'),
  listingId: const ListingId('l-math'),
  professorId: professor.id,
  professorName: professor.name,
  studentId: student.id,
  studentName: student.name,
  start: start,
  duration: LessonDuration.minutes60,
  message: message,
  createdAt: now.subtract(const Duration(days: 1)),
  status: status,
);

ProfessorProfile awaiting(String id, {required DateTime submittedAt}) => ProfessorProfile(
  id: UserId(id),
  fullName: id,
  city: City.belgrade,
  bio: '',
  verification: AwaitingReview(submittedAt: submittedAt, diplomaFile: 'diplomas/$id.pdf', linkedIn: linkedIn),
);

final class FixedClock implements Clock {
  FixedClock(this.time);

  final DateTime time;

  @override
  DateTime now() => time;
}

// Ponaša se kao baza: save proverava status (from), saveConfirmation radi sve ili ništa.
final class InMemoryLessonRepository implements LessonRepository {
  InMemoryLessonRepository([List<Lesson> lessons = const []]) : lessons = [...lessons];

  final List<Lesson> lessons;
  bool fail = false;

  void _check() {
    if (fail) {
      throw const RepositoryException('Nema mreže');
    }
  }

  Lesson? _stored(LessonId id) => lessons.where((lesson) => lesson.id == id).firstOrNull;

  void _put(Lesson lesson) {
    lessons.removeWhere((other) => other.id == lesson.id);
    lessons.add(lesson);
  }

  @override
  Future<List<Lesson>> lessonsOf(UserId student) async {
    _check();
    return lessons.where((lesson) => lesson.studentId == student).toList();
  }

  @override
  Future<List<Lesson>> lessonsForSlot(SlotId slot) async {
    _check();
    return lessons.where((lesson) => lesson.slotId == slot).toList();
  }

  @override
  Future<List<Lesson>> lessonsOfProfessor(UserId professor) async {
    _check();
    return lessons.where((lesson) => lesson.professorId == professor).toList();
  }

  @override
  Future<Set<SlotId>> takenSlotsOf(UserId professor) async {
    _check();
    return takenSlots(lessons.where((lesson) => lesson.professorId == professor));
  }

  @override
  Future<Lesson?> find(LessonId id) async {
    _check();
    return _stored(id);
  }

  @override
  Future<LessonId> nextId() async => LessonId('lesson-${lessons.length + 1}');

  @override
  Future<Result<Lesson>> create(Lesson lesson) async {
    _check();
    _put(lesson);
    return Success(lesson);
  }

  @override
  Future<Result<Lesson>> save(Lesson lesson, {required LessonStatus from}) async {
    _check();
    final stored = _stored(lesson.id);
    if (stored == null || stored.status.runtimeType != from.runtimeType) {
      return const Failure(LessonChanged());
    }
    _put(lesson);
    return Success(lesson);
  }

  @override
  Future<Result<Confirmation>> saveConfirmation(Confirmation confirmation) async {
    _check();
    final confirmed = confirmation.confirmed;
    if (_stored(confirmed.id)?.status is! Pending) {
      return const Failure(LessonChanged());
    }
    final slotTaken = lessons.any(
      (other) => other.slotId == confirmed.slotId && other.id != confirmed.id && other.status is Confirmed,
    );
    if (slotTaken) {
      return const Failure(SlotTaken());
    }

    _put(confirmed);
    final rejected = <Lesson>[];
    for (final other in confirmation.rejected) {
      if (_stored(other.id)?.status is Pending) {
        _put(other);
        rejected.add(other);
      }
    }
    return Success(Confirmation(confirmed: confirmed, rejected: rejected));
  }
}

final class InMemoryVerificationRepository implements VerificationRepository {
  InMemoryVerificationRepository([List<ProfessorProfile> profiles = const []]) : profiles = [...profiles];

  final List<ProfessorProfile> profiles;
  bool fail = false;

  // Ako je postavljen, save čeka dok ga test ne pusti.
  Completer<void>? gate;

  void _check() {
    if (fail) {
      throw const RepositoryException('Nema mreže');
    }
  }

  @override
  Future<List<ProfessorProfile>> queue() async {
    _check();
    return profiles;
  }

  @override
  Future<ProfessorProfile?> find(UserId professor) async {
    _check();
    return profiles.where((profile) => profile.id == professor).firstOrNull;
  }

  @override
  Future<Result<ProfessorProfile>> save(ProfessorProfile profile, {required VerificationStatus from}) async {
    _check();
    await gate?.future;
    final stored = profiles.where((other) => other.id == profile.id).firstOrNull;
    if (stored == null) {
      return const Failure(NotFound());
    }
    if (stored.verification.runtimeType != from.runtimeType) {
      return Failure(InvalidVerificationTransition(from: stored.verification, to: profile.verification));
    }
    profiles.removeWhere((other) => other.id == profile.id);
    profiles.add(profile);
    return Success(profile);
  }
}

final class InMemoryProfessorRepository implements ProfessorRepository {
  InMemoryProfessorRepository({this.profiles = const [], this.listings = const [], this.slots = const []});

  final List<ProfessorProfile> profiles;
  final List<Listing> listings;
  final List<Slot> slots;
  bool fail = false;

  void _check() {
    if (fail) {
      throw const RepositoryException('Nema mreže');
    }
  }

  @override
  Future<ProfessorsPage> professors({int offset = 0, int limit = 20}) async {
    _check();
    final end = offset + limit < profiles.length ? offset + limit : profiles.length;
    final start = offset < end ? offset : end;
    return ProfessorsPage(
      items: [
        for (final profile in profiles.sublist(start, end))
          ProfessorSummary(profile: profile, listings: await listingsOf(profile.id)),
      ],
      nextOffset: end < profiles.length ? end : null,
    );
  }

  @override
  Future<ProfessorProfile> profile(UserId id) async {
    _check();
    return profiles.firstWhere((profile) => profile.id == id);
  }

  @override
  Future<List<Listing>> listingsOf(UserId professor) async {
    _check();
    return listings.where((listing) => listing.professorId == professor).toList();
  }

  @override
  Future<List<Slot>> slotsOf(UserId professor) async {
    _check();
    return slots.where((slot) => slot.professorId == professor).toList();
  }

  @override
  Future<Slot?> findSlot(SlotId id) async {
    _check();
    return slots.where((slot) => slot.id == id).firstOrNull;
  }
}

// Sesija kao na serveru: login -> (lozinka, korisnik). expire() glumi server koji je odbio istekao token.
final class InMemorySessionRepository implements SessionRepository {
  InMemorySessionRepository(this.accounts, {this.signedIn});

  final Map<String, (String, User)> accounts;
  User? signedIn;
  bool fail = false;
  int logInCalls = 0;
  int logOutCalls = 0;
  final _expirations = StreamController<void>.broadcast();

  // Ako je postavljen, logIn čeka dok ga test ne pusti.
  Completer<void>? gate;

  void expire() => _expirations.add(null);

  void _check() {
    if (fail) {
      throw const RepositoryException('Nema veze sa serverom', failure: RepositoryFailure.unreachable);
    }
  }

  @override
  Future<User?> logIn({required String login, required String password}) async {
    logInCalls++;
    await gate?.future;
    _check();
    final account = accounts[login];
    if (account == null || account.$1 != password) {
      return null;
    }
    return signedIn = account.$2;
  }

  @override
  Future<User?> current() async {
    _check();
    return signedIn;
  }

  @override
  Future<void> logOut() async {
    logOutCalls++;
    _check();
    signedIn = null;
  }

  @override
  Stream<void> get expirations => _expirations.stream;
}
