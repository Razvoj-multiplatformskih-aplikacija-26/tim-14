import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final now = DateTime.utc(2026, 11, 2, 10);

const student = User(id: UserId('ana'), name: 'Ana', role: Role.student);
const otherStudent = User(id: UserId('marko'), name: 'Marko', role: Role.student);
const professor = User(id: UserId('milica'), name: 'Milica', role: Role.professor);
const admin = User(id: UserId('jovana'), name: 'Jovana', role: Role.admin);

const math = ListingId('l-math');
const physics = ListingId('l-physics');

final message = RequestMessage.parse('Treba mi pomoć oko integrala.').valueOrNull!;

Slot slotAt(DateTime start, {String id = 's-1', ListingId listingId = math}) => Slot(
  id: SlotId(id),
  listingId: listingId,
  professorId: professor.id,
  start: start,
  duration: LessonDuration.minutes60,
);

Lesson lessonAt(
  DateTime start, {
  String id = 'lesson-1',
  String slotId = 's-1',
  UserId? studentId,
  UserId? professorId,
  LessonStatus status = const Pending(),
}) => Lesson(
  id: LessonId(id),
  slotId: SlotId(slotId),
  listingId: math,
  professorId: professorId ?? professor.id,
  professorName: professor.name,
  studentId: studentId ?? student.id,
  studentName: student.name,
  start: start,
  duration: LessonDuration.minutes60,
  message: message,
  createdAt: now.subtract(const Duration(days: 1)),
  status: status,
);

final class FixedClock implements Clock {
  FixedClock(this.time);

  final DateTime time;

  @override
  DateTime now() => time;
}

final class InMemoryLessonRepository implements LessonRepository {
  InMemoryLessonRepository([List<Lesson> lessons = const []]) : lessons = [...lessons];

  final List<Lesson> lessons;

  // Broji svaki upis: create, save i saveConfirmation (jedan poziv i kad piše više časova).
  int saveCalls = 0;
  bool fail = false;
  int _nextId = 100;

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
    return {
      for (final lesson in lessons)
        if (lesson.professorId == professor && lesson.status is Confirmed) lesson.slotId,
    };
  }

  @override
  Future<Lesson?> find(LessonId id) async {
    _check();
    return _stored(id);
  }

  @override
  Future<LessonId> nextId() async {
    _check();
    _nextId++;
    return LessonId('lesson-$_nextId');
  }

  @override
  Future<Result<Lesson>> create(Lesson lesson) async {
    _check();
    saveCalls++;
    _put(lesson);
    return Success(lesson);
  }

  // Kao UPDATE … WHERE status = from: ako sačuvani čas više nema taj status, ništa se ne upisuje.
  @override
  Future<Result<Lesson>> save(Lesson lesson, {required LessonStatus from}) async {
    _check();
    saveCalls++;
    final stored = _stored(lesson.id);
    if (stored == null || stored.status.runtimeType != from.runtimeType) {
      return const Failure(LessonChanged());
    }
    _put(lesson);
    return Success(lesson);
  }

  // Kao transakcija na serveru: ili prođe potvrda, ili se ništa ne upiše.
  @override
  Future<Result<Confirmation>> saveConfirmation(Confirmation confirmation) async {
    _check();
    saveCalls++;
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
      // Učenik je možda u međuvremenu povukao zahtev. Taj čas se preskače.
      if (_stored(other.id)?.status is Pending) {
        _put(other);
        rejected.add(other);
      }
    }
    return Success(Confirmation(confirmed: confirmed, rejected: rejected));
  }
}

final class InMemoryProfessorRepository implements ProfessorRepository {
  InMemoryProfessorRepository({required this.profiles, this.listings = const [], this.slots = const []});

  final List<ProfessorProfile> profiles;
  final List<Listing> listings;
  final List<Slot> slots;

  @override
  Future<ProfessorsPage> professors({int offset = 0, int limit = 20}) async {
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
    for (final profile in profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    throw RepositoryException('Nema profesora $id');
  }

  @override
  Future<List<Listing>> listingsOf(UserId professor) async =>
      listings.where((listing) => listing.professorId == professor).toList();

  @override
  Future<List<Slot>> slotsOf(UserId professor) async => slots.where((slot) => slot.professorId == professor).toList();

  @override
  Future<Slot?> findSlot(SlotId id) async => slots.where((slot) => slot.id == id).firstOrNull;
}

final class InMemoryVerificationRepository implements VerificationRepository {
  InMemoryVerificationRepository([List<ProfessorProfile> profiles = const []]) : profiles = [...profiles];

  final List<ProfessorProfile> profiles;
  int saveCalls = 0;
  bool fail = false;

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

  // Kao UPDATE … WHERE verification = from: ako je drugi administrator već odlučio, ništa se ne upisuje.
  @override
  Future<Result<ProfessorProfile>> save(ProfessorProfile profile, {required VerificationStatus from}) async {
    _check();
    saveCalls++;
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

final class InMemorySessionRepository implements SessionRepository {
  InMemorySessionRepository(this.accounts);

  // login -> (lozinka, korisnik)
  final Map<String, (String, User)> accounts;
  User? signedIn;
  String? lastLogin;

  @override
  Future<User?> logIn({required String login, required String password}) async {
    lastLogin = login;
    final account = accounts[login];
    if (account == null || account.$1 != password) {
      return null;
    }
    return signedIn = account.$2;
  }

  @override
  Future<User?> current() async => signedIn;

  @override
  Future<void> logOut() async => signedIn = null;

  @override
  Stream<void> get expirations => const Stream.empty();
}
