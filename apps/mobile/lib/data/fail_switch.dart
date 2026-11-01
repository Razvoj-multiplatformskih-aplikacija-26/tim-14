import 'package:use_cases/use_cases.dart';

// Stavka menija „Simuliraj grešku“ postavi failNext na true.
// Sledeći poziv repozitorijuma baci grešku i vrati ga na false.
class FailSwitch {
  bool failNext = false;

  void check() {
    if (failNext) {
      failNext = false;
      throw const RepositoryException('Simulirana greška');
    }
  }
}
