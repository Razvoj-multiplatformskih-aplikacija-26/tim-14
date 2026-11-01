import 'package:domain/domain.dart';

// Domen zna samo vrednosti enuma, a tekst bira aplikacija, kao kod grešaka.
// Switch nema default granu, pa novi grad u domenu ne prolazi kompajler dok ne dobije ime ovde.
extension CityText on City {
  String get label => switch (this) {
    City.belgrade => 'Beograd',
    City.noviSad => 'Novi Sad',
    City.nis => 'Niš',
    City.kragujevac => 'Kragujevac',
    City.subotica => 'Subotica',
  };
}
