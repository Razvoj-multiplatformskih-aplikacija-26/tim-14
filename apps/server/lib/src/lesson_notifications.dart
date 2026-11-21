import 'dart:async';
import 'dart:io';

import 'package:domain/domain.dart';

import 'mail.dart';

/// Which emails a lesson event means, and what they say. [Mailer] only knows how to send one.
/// In Spring terms: a notification `@Service` that uses `JavaMailSender`.
///
/// The handlers call it only after the use case returned `Success`, so after the transaction committed: a refused
/// or rolled-back action never emails anyone. They don't wait for it either (`unawaited`), so the answer to the app
/// never waits for the email service.
///
/// Every email goes to [inbox]. Resend's free test sender delivers only to the address the account was opened with,
/// and users have no email column yet, so the subject says who the email is for. The real version adds
/// `users.email` and a verified domain; nothing that calls this class changes.
final class LessonNotifications {
  LessonNotifications(this._mailer, {required this.inbox, void Function(String line)? log})
    : _log = log ?? stdout.writeln;

  final Mailer _mailer;
  final void Function(String line) _log;

  /// Where every email goes, `MAIL_TO`.
  final String inbox;

  /// A student asked for a lesson: the professor should decide.
  Future<void> requested(Lesson lesson) => _sendAll([
    _email(
      to: lesson.professorName,
      subject: 'Novi zahtev za čas',
      text:
          '${lesson.studentName} traži čas ${_when(lesson)}, ${lesson.duration.minutes} min.\n'
          'Poruka: „${lesson.message.text}“\n\n'
          'Otvori backoffice da potvrdiš ili odbiješ zahtev.',
    ),
  ]);

  /// A professor confirmed: one email to that student, and one to every student rejected with it. Only the lessons
  /// the transaction really rejected are in [Confirmation.rejected], so a student who withdrew a moment earlier gets
  /// nothing.
  Future<void> confirmed(Confirmation confirmation) => _sendAll([
    _email(
      to: confirmation.confirmed.studentName,
      subject: 'Čas je potvrđen',
      text: 'Tvoj čas kod ${confirmation.confirmed.professorName} ${_when(confirmation.confirmed)} je potvrđen.',
    ),
    for (final lesson in confirmation.rejected) _rejection(lesson),
  ]);

  /// A professor rejected a request.
  Future<void> rejected(Lesson lesson) => _sendAll([_rejection(lesson)]);

  Email _rejection(Lesson lesson) => switch (lesson.status) {
    Rejected(cause: RejectionCause.slotTaken) => _email(
      to: lesson.studentName,
      subject: 'Termin je zauzet',
      text:
          'Termin ${_when(lesson)} kod ${lesson.professorName} je u međuvremenu zauzet, pa je tvoj zahtev odbijen.\n'
          'Izaberi drugi termin u aplikaciji.',
    ),
    _ => _email(
      to: lesson.studentName,
      subject: 'Zahtev je odbijen',
      text: 'Tvoj zahtev za čas kod ${lesson.professorName} ${_when(lesson)} je odbijen.',
    ),
  };

  Email _email({required String to, required String subject, required String text}) =>
      Email(to: inbox, subject: '[za: $to] $subject', text: text);

  /// All sends start at once, before the handler answers. One that fails is logged and the others go on.
  Future<void> _sendAll(List<Email> emails) => Future.wait([for (final email in emails) _send(email)]);

  /// Catches everything: this runs unawaited, and an error nobody catches there would stop the server.
  Future<void> _send(Email email) async {
    try {
      await _mailer.send(email);
    } catch (error) {
      _log('Mail nije poslat (${email.subject}): $error');
    }
  }
}

// The project has no intl, so the short names are written out here, as in the apps' text/dates.dart.
// DateTime.weekday goes from 1 (Monday).
const _weekdays = ['pon', 'uto', 'sre', 'čet', 'pet', 'sub', 'ned'];
const _months = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sep', 'okt', 'nov', 'dec'];

/// „uto 1. dec u 11:00“, the way the apps write it, in Belgrade time.
String _when(Lesson lesson) {
  final at = _belgrade(lesson.start);
  return '${_weekdays[at.weekday - 1]} ${at.day}. ${_months[at.month - 1]} u ${at.hour}:'
      '${at.minute.toString().padLeft(2, '0')}';
}

/// [instant] as a clock in Belgrade shows it. The server image has no time-zone data (`FROM scratch`), so
/// `toLocal()` would give UTC there. Belgrade is UTC+1, and UTC+2 under the EU summer-time rule: from the last
/// Sunday of March to the last Sunday of October, both at 01:00 UTC.
DateTime _belgrade(DateTime instant) {
  final utc = instant.toUtc();
  final summer = !utc.isBefore(_lastSundayAt1Utc(utc.year, 3)) && utc.isBefore(_lastSundayAt1Utc(utc.year, 10));
  return utc.add(Duration(hours: summer ? 2 : 1));
}

DateTime _lastSundayAt1Utc(int year, int month) {
  final lastDay = DateTime.utc(year, month + 1, 0); // day 0 of the next month is the last day of this one
  return DateTime.utc(year, month, lastDay.day - lastDay.weekday % 7, 1); // Sunday is weekday 7
}
