import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/text/domain_errors.dart';

void main() {
  test('an empty request message gets its own text', () {
    expect(const InvalidRequestMessage(0, max: 300).message, 'Napiši profesoru šta ti je potrebno.');
  });

  // Stara aplikacija: granice ovde namerno nisu jednake konstantama u domenu. Tako izgleda greška sa servera
  // na kome je pravilo promenjeno posle izgradnje aplikacije. Tekst mora da pokaže broj iz greške.
  test('rule texts take their numbers from the error, not from the domain constants', () {
    expect(const InvalidRequestMessage(250, max: 200).message, 'Poruka može imati najviše 200 znakova (sada ima 250).');
    expect(
      const TooManyPendingRequests(max: 2).message,
      'Već imaš 2 zahteva na čekanju. Povuci neki pre nego što pošalješ novi.',
    );
    expect(const TooSoonToRequest(notice: Duration(hours: 48)).message, 'Termin mora biti bar 48 sata unapred.');
    expect(
      const CancellationTooLate(notice: Duration(hours: 12)).message,
      'Čas može da se otkaže najkasnije 12 sata pre početka.',
    );
  });
}
