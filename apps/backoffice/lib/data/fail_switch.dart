import 'package:use_cases/use_cases.dart';

// Stavka menija „Simuliraj grešku“ postavlja failNext. Sledeći poziv repozitorijuma baca grešku i vraća ga na false.
// Isti objekat dobijaju oba lažna repozitorijuma, pa jedna stavka radi i za časove i za verifikaciju.
final class FailSwitch {
  bool failNext = false;

  // Vrsta greške. Podrazumevano podaci nisu dostupni; test stavi unreachable kad glumi ugašen server.
  RepositoryFailure failure = RepositoryFailure.unavailable;

  void check() {
    if (!failNext) return;
    failNext = false;
    throw RepositoryException('Simulirana greška', failure: failure);
  }
}
