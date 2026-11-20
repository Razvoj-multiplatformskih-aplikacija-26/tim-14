import 'package:use_cases/use_cases.dart';

// Stavka menija „Simuliraj grešku“ postavi failNext na true.
// Sledeći poziv repozitorijuma baci grešku i vrati ga na false.
class FailSwitch {
  bool failNext = false;

  void check() {
    if (failNext) {
      failNext = false;
      // Kao prava greška veze, pa ekran pokaže isti tekst kao kad server ne radi.
      throw const RepositoryException('Simulirana greška', failure: RepositoryFailure.unreachable);
    }
  }
}
