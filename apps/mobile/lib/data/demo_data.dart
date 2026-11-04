import 'package:domain/domain.dart';

// Ulogovani učenik. Prijava stiže u KT2.
const ana = User(id: UserId('ana-markovic'), name: 'Ana Marković', role: Role.student);

const _milica = UserId('milica-jovanovic');
const _nikola = UserId('nikola-petrovic');
const _anaK = UserId('ana-kovacevic');
const _jelena = UserId('jelena-markovic');
const _milan = UserId('milan-djuric');

const _srednja = ListingId('l-srednja');
const _fakultet = ListingId('l-fakultet');
const _fizika = ListingId('l-fizika');
const _malaMatura = ListingId('l-mala-matura');
const _gimnazija = ListingId('l-gimnazija');
const _prijemni = ListingId('l-prijemni');

// Lesson ima samo id profesora i oglasa, pa kartica imena čita odavde.
const professorNames = <UserId, String>{
  _milica: 'Milica Jovanović',
  _nikola: 'Nikola Petrović',
  _anaK: 'Ana Kovačević',
  _jelena: 'Jelena Marković',
  _milan: 'Milan Đurić',
};

const listingTitles = <ListingId, String>{
  _srednja: 'Matematika za srednju školu i pripremu za fakultet',
  _fakultet: 'Analiza za studente prve godine',
  _fizika: 'Fizika za srednju školu',
  _malaMatura: 'Priprema za malu maturu',
  _gimnazija: 'Matematika i fizika za gimnazijalce',
  _prijemni: 'Matematika za prijemni na FTN',
};

final _verifiedAt = DateTime.utc(2026, 9, 15);
const _admin = UserId('jovana-ilic');

// Bar dva verifikovana, da se na listi vidi bedž „Diploma potvrđena“.
final demoProfessors = <ProfessorProfile>[
  ProfessorProfile(
    id: _milica,
    fullName: professorNames[_milica]!,
    city: City.belgrade,
    bio: 'Profesorka matematike u gimnaziji, deset godina pripremam učenike za prijemni.',
    verification: Verified(by: _admin, at: _verifiedAt),
  ),
  ProfessorProfile(
    id: _nikola,
    fullName: professorNames[_nikola]!,
    city: City.noviSad,
    bio: 'Inženjer fizike, strpljivo objašnjavam kroz mnogo primera iz života.',
  ),
  ProfessorProfile(
    id: _anaK,
    fullName: professorNames[_anaK]!,
    city: City.kragujevac,
    bio: 'Doktorantkinja na PMF-u, spremam kandidate za prijemni na tehničkim fakultetima.',
    verification: Verified(by: _admin, at: _verifiedAt),
  ),
  ProfessorProfile(
    id: _jelena,
    fullName: professorNames[_jelena]!,
    city: City.noviSad,
    bio: 'Predajem matematiku i fiziku srednjoškolcima, najviše radim sa trećim i četvrtim razredom.',
    verification: Verified(by: _admin, at: _verifiedAt),
  ),
  ProfessorProfile(
    id: _milan,
    fullName: professorNames[_milan]!,
    city: City.nis,
    bio: 'Spremam osmake za malu maturu, strpljivo i kroz mnogo zadataka.',
  ),
];

final demoListings = <Listing>[
  _listing(_srednja, _milica, Subject.mathematics, Level.highSchool, City.belgrade, 2000),
  _listing(_fakultet, _milica, Subject.mathematics, Level.university, City.belgrade, 2500),
  _listing(_fizika, _nikola, Subject.physics, Level.highSchool, City.noviSad, 1800),
  _listing(_prijemni, _anaK, Subject.mathematics, Level.entranceExam, City.kragujevac, 2500),
  _listing(_gimnazija, _jelena, Subject.mathematics, Level.highSchool, City.noviSad, 2200),
  _listing(_malaMatura, _milan, Subject.mathematics, Level.primarySchool, City.nis, 1500),
];

Listing _listing(ListingId id, UserId professor, Subject subject, Level level, City city, int price) => Listing(
  id: id,
  professorId: professor,
  subject: subject,
  level: level,
  city: city,
  description: listingTitles[id]!,
  price: Price.parse(price).valueOrNull!,
  duration: LessonDuration.minutes60,
);

// Termini su oni na kojima su već časovi, plus po tri nova slobodna za svaki oglas.
// Novi su bar 2 dana od danas, jer zahtev mora biti bar 24 sata unapred.
// Svaki oglas počinje dan kasnije od prethodnog. Milica ima dva oglasa, a oni dele jedan kalendar,
// pa njeni termini ne smeju da se preklapaju (proverava test demo_data_test.dart).
List<Slot> demoSlots(DateTime now) {
  final slots = <Slot>[];

  for (final lesson in demoLessons(now)) {
    slots.add(
      Slot(
        id: lesson.slotId,
        listingId: lesson.listingId,
        professorId: lesson.professorId,
        start: lesson.start,
        duration: lesson.duration,
      ),
    );
  }

  for (var n = 0; n < demoListings.length; n++) {
    final listing = demoListings[n];
    final days = [2 + n, 4 + n, 6 + n];
    final hours = [10, 14, 18];
    for (var i = 0; i < days.length; i++) {
      slots.add(
        Slot(
          id: SlotId('s-${listing.id.value}-$i'),
          listingId: listing.id,
          professorId: listing.professorId,
          start: _dayAt(now, days[i], hours[i]),
          duration: listing.duration,
        ),
      );
    }
  }

  return slots;
}

// Pun sat, da na kartici ne piše 14:37.
DateTime _dayAt(DateTime now, int days, int hour) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day + days, hour);
}

// Svi termini se računaju od now, pa demo radi na bilo koji dan odbrane.
List<Lesson> demoLessons(DateTime now) {
  DateTime dayAt(int days, int hour) => _dayAt(now, days, hour);
  DateTime hoursAgo(int hours) => now.subtract(Duration(hours: hours));

  final local = now.toLocal();
  final inTenHours = DateTime(local.year, local.month, local.day, local.hour + 10);

  return [
    // Zahtev na čekanju koji može da se povuče.
    _lesson(
      'c-01',
      professor: _milica,
      listing: _srednja,
      start: dayAt(3, 17),
      createdAt: hoursAgo(5),
      message: 'Imam kontrolni iz integrala sledeće nedelje. Možemo li da prođemo zadatke iz zbirke?',
    ),
    // Drugi zahtev na čekanju. Sa dva na čekanju novi zahtev prolazi, četvrti ne.
    _lesson(
      'c-02',
      professor: _nikola,
      listing: _fizika,
      start: dayAt(5, 18),
      createdAt: hoursAgo(20),
      message: 'Treba mi pomoć iz fizike, kretanje i Njutnovi zakoni.',
    ),
    // Potvrđen, za dva dana. Otkazivanje prolazi.
    _lesson(
      'c-03',
      professor: _milica,
      listing: _srednja,
      start: dayAt(2, 16),
      createdAt: hoursAgo(50),
      message: 'Spremam pismeni iz analize, najviše mi trebaju izvodi.',
      status: Confirmed(at: hoursAgo(45)),
    ),
    // Potvrđen, za deset sati. Otkazivanje je prekasno (CancellationTooLate).
    _lesson(
      'c-04',
      professor: _anaK,
      listing: _prijemni,
      start: inTenHours,
      createdAt: hoursAgo(72),
      message: 'Htela bih da radimo stare testove za prijemni.',
      status: Confirmed(at: hoursAgo(70)),
    ),
    _lesson(
      'c-05',
      professor: _jelena,
      listing: _gimnazija,
      start: dayAt(7, 12),
      createdAt: hoursAgo(30),
      message: 'Treći razred gimnazije, trigonometrija mi je slaba tačka.',
      status: Confirmed(at: hoursAgo(26)),
    ),
    _lesson(
      'c-06',
      professor: _milica,
      listing: _srednja,
      start: dayAt(-7, 17),
      createdAt: dayAt(-10, 11),
      message: 'Treba mi pomoć oko kvadratnih nejednačina.',
      status: Held(at: dayAt(-7, 18)),
    ),
    _lesson(
      'c-07',
      professor: _jelena,
      listing: _gimnazija,
      start: dayAt(-14, 15),
      createdAt: dayAt(-17, 9),
      message: 'Imam test iz vektora za nedelju dana.',
      status: Held(at: dayAt(-14, 16)),
    ),
    _lesson(
      'c-08',
      professor: _nikola,
      listing: _fizika,
      start: dayAt(-3, 18),
      createdAt: dayAt(-8, 10),
      message: 'Možemo li da ponovimo električno polje?',
      status: Cancelled(by: ana.id, at: dayAt(-6, 9)),
    ),
    _lesson(
      'c-09',
      professor: _anaK,
      listing: _prijemni,
      start: dayAt(-5, 10),
      createdAt: dayAt(-9, 19),
      message: 'Treba mi priprema za prijemni iz matematike.',
      status: Rejected(cause: RejectionCause.slotTaken, at: dayAt(-8, 12)),
    ),
    _lesson(
      'c-10',
      professor: _milan,
      listing: _malaMatura,
      start: dayAt(-10, 16),
      createdAt: dayAt(-13, 14),
      message: 'Spremam se za probni test male mature.',
      status: NoShow(at: dayAt(-10, 17)),
    ),
  ];
}

Lesson _lesson(
  String id, {
  required UserId professor,
  required ListingId listing,
  required DateTime start,
  required DateTime createdAt,
  required String message,
  LessonStatus status = const Pending(),
}) => Lesson(
  id: LessonId(id),
  slotId: SlotId('s-$id'),
  listingId: listing,
  professorId: professor,
  studentId: ana.id,
  start: start,
  duration: LessonDuration.minutes60,
  message: RequestMessage.parse(message).valueOrNull!,
  createdAt: createdAt,
  status: status,
);
