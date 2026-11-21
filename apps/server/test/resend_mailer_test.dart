import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:server/server.dart';
import 'package:test/test.dart';

const email = Email(to: 'inbox@example.com', subject: '[za: Ana Marković] Čas je potvrđen', text: 'Tvoj čas …');

/// The real adapter against a pretend Resend: `MockClient` answers instead of the network, the way `MockRestServiceServer`
/// stands in for the other side of a `RestTemplate` in Spring.
void main() {
  test('posts the email to Resend with the key in the Authorization header', () async {
    late http.Request seen;
    final mailer = ResendMailer(
      're_test_key',
      from: 'Casovi <onboarding@resend.dev>',
      client: MockClient((request) async {
        seen = request;
        return http.Response('{"id":"4ef9a417"}', 200);
      }),
    );

    await mailer.send(email);

    expect(seen.method, 'POST');
    expect(seen.url, Uri.parse('https://api.resend.com/emails'));
    expect(seen.headers['Authorization'], 'Bearer re_test_key');
    expect(seen.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(seen.body), {
      'from': 'Casovi <onboarding@resend.dev>',
      'to': ['inbox@example.com'],
      'subject': '[za: Ana Marković] Čas je potvrđen',
      'text': 'Tvoj čas …',
    });
  });

  test("an answer that isn't a success throws MailFailed with Resend's explanation", () async {
    final mailer = ResendMailer(
      'wrong-key',
      from: 'Casovi <onboarding@resend.dev>',
      client: MockClient((_) async => http.Response('{"message":"API key is invalid"}', 403)),
    );

    await expectLater(
      mailer.send(email),
      throwsA(
        isA<MailFailed>()
            .having((failure) => failure.status, 'status', 403)
            .having((failure) => failure.body, 'body', contains('API key is invalid')),
      ),
    );
  });

  test('a Resend that never answers is given up on after the timeout', () async {
    final mailer = ResendMailer(
      're_test_key',
      from: 'Casovi <onboarding@resend.dev>',
      timeout: const Duration(milliseconds: 50),
      client: MockClient((_) => Future.delayed(const Duration(seconds: 1), () => http.Response('{}', 200))),
    );

    await expectLater(mailer.send(email), throwsA(isA<TimeoutException>()));
  });
}
