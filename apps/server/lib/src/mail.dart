import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// One plain-text email.
final class Email {
  const Email({required this.to, required this.subject, required this.text});

  final String to;
  final String subject;
  final String text;

  @override
  String toString() => 'Email(to: $to, subject: $subject)';
}

/// The port to the outside email service. In Spring terms: `JavaMailSender`.
///
/// It lives in the server, not in `use_cases`, because only the server sends email. The clients run the same use
/// cases and never send any.
abstract interface class Mailer {
  /// Throws when the email could not be sent. The caller decides what that means.
  Future<void> send(Email email);
}

/// The fake: writes the email to the log instead of sending it. The server uses it when `RESEND_API_KEY` is not set,
/// so a fresh clone runs without an account anywhere.
final class LogMailer implements Mailer {
  LogMailer(this._log);

  final void Function(String line) _log;

  @override
  Future<void> send(Email email) async {
    _log('Mail (not sent) → ${email.to}\n  ${email.subject}\n  ${email.text.replaceAll('\n', '\n  ')}');
  }
}

/// The real one: Resend's HTTP API. The key never leaves the server: it comes from the server's `.env`, goes only
/// into the `Authorization` header and is never logged.
///
/// Replacing Resend with another provider means one more class like this one; nothing that sends email changes.
final class ResendMailer implements Mailer {
  ResendMailer(this._apiKey, {required this.from, http.Client? client, this.timeout = const Duration(seconds: 10)})
    : _http = client ?? http.Client();

  static final endpoint = Uri.parse('https://api.resend.com/emails');

  final String _apiKey;
  final http.Client _http;

  /// The sender, for example `Casovi <onboarding@resend.dev>`.
  final String from;

  /// How long to wait for Resend before giving up, so a hanging call never piles up in the server.
  final Duration timeout;

  @override
  Future<void> send(Email email) async {
    final response = await _http
        .post(
          endpoint,
          headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'from': from,
            'to': [email.to],
            'subject': email.subject,
            'text': email.text,
          }),
        )
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MailFailed(response.statusCode, response.body);
    }
  }

  void close() => _http.close();
}

/// Resend answered, but not with a success. [body] is Resend's own explanation, such as a wrong key.
final class MailFailed implements Exception {
  const MailFailed(this.status, this.body);

  final int status;
  final String body;

  @override
  String toString() => 'MailFailed($status $body)';
}
