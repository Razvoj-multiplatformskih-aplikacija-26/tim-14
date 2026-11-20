import 'package:blocs/blocs.dart';
import 'package:use_cases/use_cases.dart';

import 'domain_errors.dart';

// Srpski tekst za svaku vrstu greške veze, upućen učeniku. Repozitorijum javlja samo vrstu, a tekst pravi aplikacija.
// Switch nema default granu, pa nova vrsta ne prolazi kompajler dok ne dobije tekst ovde.
extension RepositoryFailureText on RepositoryFailure {
  String get message => switch (this) {
    RepositoryFailure.unavailable => 'Podaci trenutno nisu dostupni. Pokušaj ponovo.',
    RepositoryFailure.unreachable => 'Nema veze sa serverom. Proveri internet i pokušaj ponovo.',
    RepositoryFailure.serverError => 'Greška na serveru. Pokušaj ponovo za koji minut.',
    // Kôd koji ova verzija aplikacije ne poznaje, jer je server noviji: bez tehničkog teksta.
    RepositoryFailure.refused => 'Server nije prihvatio zahtev.',
    RepositoryFailure.sessionExpired => 'Prijava je istekla. Prijavi se ponovo.',
  };
}

// Tekst za SnackBar posle akcije: pravilo koje nije prošlo, ili akcija koja nije stigla do servera.
extension ActionNoticeText on ActionNotice {
  String get message => switch (this) {
    ActionRejected(:final error) => error.message,
    ActionFailed(:final failure) => failure.message,
  };
}
