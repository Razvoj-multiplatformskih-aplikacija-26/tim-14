import 'package:blocs/blocs.dart';
import 'package:use_cases/use_cases.dart';

import 'domain_errors.dart';

// Srpski tekst za svaku vrstu greške veze. Repozitorijum javlja samo vrstu, a tekst pravi aplikacija.
// Switch nema default granu, pa nova vrsta ne prolazi kompajler dok ne dobije tekst ovde.
extension RepositoryFailureText on RepositoryFailure {
  String get message => switch (this) {
    RepositoryFailure.unavailable => 'Podaci trenutno nisu dostupni. Pokušaj ponovo.',
    RepositoryFailure.unreachable => 'Nema veze sa serverom. Proveri da li server radi.',
    RepositoryFailure.serverError => 'Greška na serveru. Pokušaj ponovo za koji minut.',
    RepositoryFailure.refused => 'Server je odbio zahtev.',
    RepositoryFailure.sessionExpired => 'Prijava je istekla. Prijavi se ponovo.',
  };
}

// Tekst za SnackBar posle akcije: ili pravilo koje nije prošlo, ili greška veze.
extension ActionNoticeText on ActionNotice {
  String get message => switch (this) {
    final ActionRejected rejected => rejected.error.message,
    final ActionFailed failed => failed.failure.message,
  };
}
