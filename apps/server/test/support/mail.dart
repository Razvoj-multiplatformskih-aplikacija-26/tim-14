import 'package:server/server.dart';

/// Keeps every email instead of sending it. It records the moment `send` is called, and the handlers call it before
/// they answer, so a test can check [sent] right after the HTTP response with no waiting.
final class RecordingMailer implements Mailer {
  final sent = <Email>[];

  List<String> get subjects => [for (final email in sent) email.subject];

  @override
  Future<void> send(Email email) async => sent.add(email);
}

/// An email service that is down.
final class FailingMailer implements Mailer {
  @override
  Future<void> send(Email email) async => throw const MailFailed(503, 'down');
}

const testInbox = 'test@example.com';

/// Notifications for a test: into [mailer] (a fresh [RecordingMailer] by default), with the log thrown away.
LessonNotifications testNotifications([Mailer? mailer]) =>
    LessonNotifications(mailer ?? RecordingMailer(), inbox: testInbox, log: (_) {});
