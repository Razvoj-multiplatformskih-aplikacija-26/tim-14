import 'dart:convert';

import 'package:api_client/api_client.dart';
import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

final base = Uri.parse('http://localhost:8080');
final at = DateTime.utc(2026, 11, 20, 10);

ApiClient clientOver(MockClient server) => ApiClient(baseUri: base, httpClient: server, keepsSessionInCookie: false);

http.Response jsonAnswer(Object? json, {int status = 200}) =>
    http.Response.bytes(utf8.encode(jsonEncode(json)), status, headers: {'content-type': 'application/json'});

http.Response problemAnswer(DomainError error) {
  final problem = error.toProblem();
  return http.Response(jsonEncode(problem.toJson()), problem.status, headers: {'content-type': ProblemDto.mediaType});
}

/// A fake server that remembers the last request and answers with [answer].
final class Recorded {
  Recorded(this.answer);

  http.Response Function(http.Request request) answer;
  http.Request? last;

  MockClient get client => MockClient((request) async {
    last = request;
    return answer(request);
  });

  Map<String, Object?>? get body => last!.body.isEmpty ? null : jsonDecode(last!.body) as Map<String, Object?>;
}

void main() {
  final lesson = Lesson(
    id: const LessonId('l-1'),
    slotId: const SlotId('s-1'),
    listingId: const ListingId('l-math'),
    professorId: const UserId('milica'),
    professorName: 'Milica Jovanović',
    studentId: const UserId('ana'),
    studentName: 'Ana Marković',
    start: DateTime.utc(2026, 11, 25, 16),
    duration: LessonDuration.minutes60,
    message: RequestMessage.parse('Treba mi pomoć oko integrala.').valueOrNull!,
    createdAt: at,
  );

  group('HttpLessonRepository', () {
    test('lessons of a student are read with the student filter', () async {
      final server = Recorded((request) => jsonAnswer([lesson.toDto().toJson()]));

      final lessons = await HttpLessonRepository(clientOver(server.client)).lessonsOf(const UserId('ana'));

      expect(lessons, [lesson]);
      expect(server.last!.url.path, ApiPaths.lessons);
      expect(server.last!.url.queryParameters, {ApiQuery.student: 'ana'});
    });

    test('find: someone else\'s or a missing lesson is null', () async {
      final server = Recorded((request) => problemAnswer(const NotFound()));

      expect(await HttpLessonRepository(clientOver(server.client)).find(const LessonId('l-9')), isNull);
      expect(server.last!.url.path, ApiPaths.lesson('l-9'));
    });

    test('taken slots come from the professor route', () async {
      final server = Recorded((request) => jsonAnswer(const TakenSlotsDto(slotIds: ['s-1', 's-3']).toJson()));

      final taken = await HttpLessonRepository(clientOver(server.client)).takenSlotsOf(const UserId('milica'));

      expect(taken, {const SlotId('s-1'), const SlotId('s-3')});
      expect(server.last!.url.path, ApiPaths.takenSlotsOf('milica'));
    });

    test('a new request sends only the slot and the message, and gets the lesson with the real id', () async {
      final stored = Lesson(
        id: const LessonId('9b1f'),
        slotId: lesson.slotId,
        listingId: lesson.listingId,
        professorId: lesson.professorId,
        professorName: lesson.professorName,
        studentId: lesson.studentId,
        studentName: lesson.studentName,
        start: lesson.start,
        duration: lesson.duration,
        message: lesson.message,
        createdAt: lesson.createdAt,
      );
      final server = Recorded((request) => jsonAnswer(stored.toDto().toJson(), status: 201));
      final repository = HttpLessonRepository(clientOver(server.client));

      final temporary = await repository.nextId();
      final result = await repository.create(lesson);

      expect(temporary, const LessonId('nov'));
      expect(server.body, {'slotId': 's-1', 'message': 'Treba mi pomoć oko integrala.'});
      expect(result, Success(stored));
    });

    test('a rule the server applies comes back as a Failure with the same error and limit', () async {
      final server = Recorded((request) => problemAnswer(const TooManyPendingRequests(max: 2)));

      final result = await HttpLessonRepository(clientOver(server.client)).create(lesson);

      expect(result, const Failure<Lesson>(TooManyPendingRequests(max: 2)));
    });

    group('save picks the action from where the lesson comes from and where it goes', () {
      final confirmed = lesson.copyWith(status: Confirmed(at: at));
      final cases = <String, (Lesson, LessonStatus, String)>{
        'withdrawing a request': (
          lesson.copyWith(
            status: Cancelled(by: lesson.studentId, at: at),
          ),
          const Pending(),
          'withdrawal',
        ),
        'cancelling a confirmed lesson': (
          confirmed.copyWith(
            status: Cancelled(by: lesson.studentId, at: at),
          ),
          Confirmed(at: at),
          'cancellation',
        ),
        'rejecting': (
          lesson.copyWith(
            status: Rejected(cause: RejectionCause.byProfessor, at: at),
          ),
          const Pending(),
          'rejection',
        ),
        'recording held': (confirmed.copyWith(status: Held(at: at)), Confirmed(at: at), 'held'),
        'recording a no-show': (confirmed.copyWith(status: NoShow(at: at)), Confirmed(at: at), 'no-show'),
      };

      for (final MapEntry(key: name, value: (saved, from, action)) in cases.entries) {
        test(name, () async {
          final server = Recorded((request) => jsonAnswer(saved.toDto().toJson()));

          final result = await HttpLessonRepository(clientOver(server.client)).save(saved, from: from);

          expect(server.last!.method, 'POST');
          expect(server.last!.url.path, '/lessons/l-1/$action');
          expect(result, Success(saved));
        });
      }

      test('held sends the note', () async {
        final held = confirmed.copyWith(
          status: Held(at: at, note: LessonNote.parse('Odlično.').valueOrNull),
        );
        final server = Recorded((request) => jsonAnswer(held.toDto().toJson()));

        await HttpLessonRepository(clientOver(server.client)).save(held, from: Confirmed(at: at));

        expect(server.body, {'note': 'Odlično.'});
      });

      test('a move no action makes is a mistake in the app, not a request', () async {
        final repository = HttpLessonRepository(clientOver(Recorded((request) => jsonAnswer(null)).client));

        expect(() => repository.save(confirmed, from: const Pending()), throwsArgumentError);
      });

      test('the student who withdraws while the professor confirms gets the server\'s refusal', () async {
        final server = Recorded(
          (request) => problemAnswer(
            InvalidTransition(
              from: Confirmed(at: at),
              to: Cancelled(by: lesson.studentId, at: at),
            ),
          ),
        );

        final result = await HttpLessonRepository(clientOver(server.client)).save(
          lesson.copyWith(
            status: Cancelled(by: lesson.studentId, at: at),
          ),
          from: const Pending(),
        );

        expect(result.errorOrNull, isA<InvalidTransition>());
      });
    });

    test('a confirmation that lost the race reaches the Bloc as Failure(SlotTaken)', () async {
      final server = Recorded((request) => problemAnswer(const SlotTaken()));
      final confirmation = Confirmation(
        confirmed: lesson.copyWith(status: Confirmed(at: at)),
        rejected: const [],
      );

      final result = await HttpLessonRepository(clientOver(server.client)).saveConfirmation(confirmation);

      expect(result, const Failure<Confirmation>(SlotTaken()));
      expect(server.last!.url.path, ApiPaths.confirmation('l-1'));
    });

    test('a successful confirmation brings the requests rejected with it', () async {
      final confirmation = Confirmation(
        confirmed: lesson.copyWith(status: Confirmed(at: at)),
        rejected: [
          lesson.copyWith(
            status: Rejected(cause: RejectionCause.slotTaken, at: at),
          ),
        ],
      );
      final server = Recorded((request) => jsonAnswer(confirmation.toDto().toJson()));

      final result = await HttpLessonRepository(clientOver(server.client)).saveConfirmation(confirmation);

      expect(result, Success(confirmation));
    });
  });

  group('HttpProfessorRepository', () {
    const profile = ProfessorProfile(id: UserId('milica'), fullName: 'Milica Jovanović', city: City.belgrade, bio: '');

    test('a page asks for its offset and limit', () async {
      final server = Recorded(
        (request) => jsonAnswer(
          const ProfessorsPage(
            items: [ProfessorSummary(profile: profile, listings: [])],
          ).toDto().toJson(),
        ),
      );

      final page = await HttpProfessorRepository(clientOver(server.client)).professors(offset: 20, limit: 20);

      expect(server.last!.url.queryParameters, {ApiQuery.offset: '20', ApiQuery.limit: '20'});
      expect(page.items.single.profile, profile);
      expect(page.nextOffset, isNull);
    });

    test('a profile, its listings and its slots come from the professor routes', () async {
      final slot = Slot(
        id: const SlotId('s-1'),
        listingId: const ListingId('l-math'),
        professorId: profile.id,
        start: DateTime.utc(2026, 12, 1, 10),
        duration: LessonDuration.minutes60,
      );
      final server = Recorded(
        (request) => switch (request.url.path) {
          '/professors/milica' => jsonAnswer(profile.toDto().toJson()),
          '/professors/milica/listings' => jsonAnswer(const <Object?>[]),
          '/professors/milica/slots' => jsonAnswer([slot.toDto().toJson()]),
          _ => throw StateError('unexpected ${request.url}'),
        },
      );
      final repository = HttpProfessorRepository(clientOver(server.client));

      expect(await repository.profile(profile.id), profile);
      expect(await repository.listingsOf(profile.id), isEmpty);
      expect(await repository.slotsOf(profile.id), [slot]);
    });

    test('finding a slot by id is only for the server', () {
      final repository = HttpProfessorRepository(clientOver(Recorded((request) => jsonAnswer(null)).client));

      expect(() => repository.findSlot(const SlotId('s-1')), throwsUnsupportedError);
    });
  });

  group('HttpVerificationRepository', () {
    final linkedIn = LinkedInUrl.parse('https://www.linkedin.com/in/jovan').valueOrNull!;
    final awaiting = ProfessorProfile(
      id: const UserId('jovan'),
      fullName: 'Jovan Marković',
      city: City.noviSad,
      bio: '',
      verification: AwaitingReview(submittedAt: at, diplomaFile: 'diploma.pdf', linkedIn: linkedIn),
    );

    test('the queue is the profiles the server sends', () async {
      final server = Recorded((request) => jsonAnswer([awaiting.toDto().toJson()]));

      expect(await HttpVerificationRepository(clientOver(server.client)).queue(), [awaiting]);
      expect(server.last!.url.path, ApiPaths.verifications);
    });

    test('approving goes to approval, rejecting to rejection with the reason', () async {
      final verified = awaiting.copyWith(
        verification: Verified(by: const UserId('jovana'), at: at),
      );
      final reason = RejectionReason.parse('Diploma nije čitljiva.').valueOrNull!;
      final rejected = awaiting.copyWith(
        verification: VerificationRejected(by: const UserId('jovana'), at: at, reason: reason),
      );
      final server = Recorded(
        (request) => jsonAnswer((request.url.path.endsWith('approval') ? verified : rejected).toDto().toJson()),
      );
      final repository = HttpVerificationRepository(clientOver(server.client));

      expect(await repository.save(verified, from: awaiting.verification), Success(verified));
      expect(server.last!.url.path, ApiPaths.approval('jovan'));

      expect(await repository.save(rejected, from: awaiting.verification), Success(rejected));
      expect(server.last!.url.path, ApiPaths.verificationRejection('jovan'));
      expect(server.body, {'reason': 'Diploma nije čitljiva.'});
    });

    test('another admin who decided first comes back as a Failure', () async {
      final server = Recorded(
        (request) => problemAnswer(
          InvalidVerificationTransition(
            from: Verified(by: const UserId('drugi'), at: at),
            to: Verified(by: const UserId('jovana'), at: at),
          ),
        ),
      );
      final verified = awaiting.copyWith(
        verification: Verified(by: const UserId('jovana'), at: at),
      );

      final result = await HttpVerificationRepository(clientOver(server.client))
          .save(verified, from: awaiting.verification);

      expect(result.errorOrNull, isA<InvalidVerificationTransition>());
    });

    test('find goes through the public profile and is null for a missing professor', () async {
      final server = Recorded((request) => problemAnswer(const NotFound()));

      expect(await HttpVerificationRepository(clientOver(server.client)).find(const UserId('nobody')), isNull);
      expect(server.last!.url.path, ApiPaths.professor('nobody'));
    });
  });

  test('an unreachable server is unreachable for every repository the same way', () {
    final down = clientOver(MockClient((request) async => throw http.ClientException('down')));

    expect(
      HttpLessonRepository(down).lessonsOf(const UserId('ana')),
      throwsA(isA<RepositoryException>().having((e) => e.failure, 'failure', RepositoryFailure.unreachable)),
    );
  });
}
