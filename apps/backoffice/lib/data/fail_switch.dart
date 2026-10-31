import 'package:use_cases/use_cases.dart';

// Stavka menija „Simuliraj grešku“ postavlja failNext. Sledeći poziv repozitorijuma baca grešku i vraća ga na false.
// Isti objekat dobijaju oba lažna repozitorijuma, pa jedna stavka radi i za časove i za verifikaciju.
final class FailSwitch {
  bool failNext = false;

  void check() {
    if (!failNext) return;
    failNext = false;
    throw const RepositoryException('Simulirana greška');
  }
}
