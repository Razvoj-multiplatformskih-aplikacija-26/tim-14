import 'package:domain/domain.dart';

// Domen zna samo vrednosti enuma, a tekst bira aplikacija, kao kod grešaka.
// Switch nema default granu, pa nova vrednost u domenu ne prolazi kompajler dok ne dobije tekst ovde.

extension CityText on City {
  String get label => switch (this) {
    City.belgrade => 'Beograd',
    City.noviSad => 'Novi Sad',
    City.nis => 'Niš',
    City.kragujevac => 'Kragujevac',
    City.subotica => 'Subotica',
  };
}

extension SubjectText on Subject {
  String get label => switch (this) {
    Subject.mathematics => 'Matematika',
    Subject.physics => 'Fizika',
    Subject.chemistry => 'Hemija',
    Subject.biology => 'Biologija',
    Subject.serbian => 'Srpski jezik',
    Subject.english => 'Engleski jezik',
    Subject.german => 'Nemački jezik',
    Subject.informatics => 'Informatika',
    Subject.history => 'Istorija',
    Subject.geography => 'Geografija',
  };
}

extension LevelText on Level {
  String get label => switch (this) {
    Level.primarySchool => 'Osnovna škola',
    Level.highSchool => 'Srednja škola',
    Level.entranceExam => 'Prijemni ispit',
    Level.university => 'Fakultet',
  };
}

// Npr. 2000 → "2.000 din".
String formatPrice(Price price) {
  final digits = price.dinars.toString();
  var result = '';
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      result += '.';
    }
    result += digits[i];
  }
  return '$result din';
}
