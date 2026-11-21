import 'package:domain/domain.dart';
import 'package:server/server.dart';
import 'package:test/test.dart';

import 'support/mail.dart';

void main() {
  /// Tuesday 1 December 2026, 10:00 UTC: 11:00 in Belgrade, which is on winter time then.
  final winter = DateTime.utc(2026, 12, 1, 10);
  final decided = DateTime.utc(2026, 11, 20, 9);

  Lesson lesson(String id, {String student = 'Ana Marković', DateTime? start, LessonStatus status = const Pending()}) =>
      Lesson(
        id: LessonId(id),
        slotId: const SlotId('s-1'),
        listingId: const ListingId('l-math'),
        professorId: const UserId('milica'),
        professorName: 'Milica Jovanović',
        studentId: UserId(id),
        studentName: student,
        start: start ?? winter,
        duration: LessonDuration.minutes60,
        message: RequestMessage.parse('Treba mi pomoć oko integrala.').valueOrNull!,
        createdAt: decided.subtract(const Duration(days: 1)),
        status: status,
      );

  late RecordingMailer mailer;
  late LessonNotifications notifications;

  setUp(() {
    mailer = RecordingMailer();
    notifications = testNotifications(mailer);
  });

  test('a new request emails the professor, with the time in Belgrade and the message', () async {
    await notifications.requested(lesson('ana'));

    expect(mailer.sent, hasLength(1));
    final email = mailer.sent.single;
    expect(email.to, testInbox);
    expect(email.subject, '[za: Milica Jovanović] Novi zahtev za čas');
    expect(email.text, contains('Ana Marković traži čas uto 1. dec u 11:00, 60 min.'));
    expect(email.text, contains('„Treba mi pomoć oko integrala.“'));
  });

  test('a confirmation emails its student and every student rejected with it', () async {
    final rejected = Rejected(cause: RejectionCause.slotTaken, at: decided);

    await notifications.confirmed(
      Confirmation(
        confirmed: lesson('ana', status: Confirmed(at: decided)),
        rejected: [
          lesson('nikola', student: 'Nikola Petrović', status: rejected),
          lesson('marija', student: 'Marija Ilić', status: rejected),
        ],
      ),
    );

    expect(mailer.subjects, [
      '[za: Ana Marković] Čas je potvrđen',
      '[za: Nikola Petrović] Termin je zauzet',
      '[za: Marija Ilić] Termin je zauzet',
    ]);
    expect(mailer.sent[0].text, 'Tvoj čas kod Milica Jovanović uto 1. dec u 11:00 je potvrđen.');
    expect(mailer.sent[1].text, contains('je u međuvremenu zauzet, pa je tvoj zahtev odbijen'));
  });

  test('a confirmation with nobody else waiting sends one email', () async {
    await notifications.confirmed(
      Confirmation(
        confirmed: lesson('ana', status: Confirmed(at: decided)),
        rejected: [],
      ),
    );

    expect(mailer.subjects, ['[za: Ana Marković] Čas je potvrđen']);
  });

  test("the professor's rejection emails the student", () async {
    await notifications.rejected(
      lesson(
        'ana',
        status: Rejected(cause: RejectionCause.byProfessor, at: decided),
      ),
    );

    expect(mailer.subjects, ['[za: Ana Marković] Zahtev je odbijen']);
    expect(mailer.sent.single.text, 'Tvoj zahtev za čas kod Milica Jovanović uto 1. dec u 11:00 je odbijen.');
  });

  group('Belgrade time', () {
    Future<String> shown(DateTime start) async {
      await notifications.requested(lesson('ana', start: start));
      final text = mailer.sent.last.text;
      return RegExp(r'u (\d+:\d\d),').firstMatch(text)!.group(1)!;
    }

    test('is UTC+1 in winter and UTC+2 in summer', () async {
      expect(await shown(winter), '11:00');
      expect(await shown(DateTime.utc(2027, 6, 1, 10)), '12:00');
    });

    test('summer time starts on the last Sunday of March at 01:00 UTC', () async {
      expect(await shown(DateTime.utc(2026, 3, 29, 0, 59)), '1:59');
      expect(await shown(DateTime.utc(2026, 3, 29, 1)), '3:00');
    });

    test('and ends on the last Sunday of October at 01:00 UTC', () async {
      expect(await shown(DateTime.utc(2026, 10, 25, 0, 59)), '2:59');
      expect(await shown(DateTime.utc(2026, 10, 25, 1)), '2:00');
    });
  });

  test('an email service that is down never throws: each lost email is one line in the log', () async {
    final log = <String>[];
    final failing = LessonNotifications(FailingMailer(), inbox: testInbox, log: log.add);
    final rejected = Rejected(cause: RejectionCause.slotTaken, at: decided);

    await failing.confirmed(
      Confirmation(
        confirmed: lesson('ana', status: Confirmed(at: decided)),
        rejected: [lesson('nikola', student: 'Nikola Petrović', status: rejected)],
      ),
    );

    expect(log, [
      'Mail nije poslat ([za: Ana Marković] Čas je potvrđen): MailFailed(503 down)',
      'Mail nije poslat ([za: Nikola Petrović] Termin je zauzet): MailFailed(503 down)',
    ]);
  });
}
