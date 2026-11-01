import 'package:domain/domain.dart';

// Ulogovani učenik. Prijava stiže u KT2.
const ana = User(id: UserId('ana-markovic'), name: 'Ana Marković', role: Role.student);

const _milica = UserId('milica-jovanovic');
const _nikola = UserId('nikola-petrovic');
const _anaK = UserId('ana-kovacevic');
const _jelena = UserId('jelena-markovic');
const _milan = UserId('milan-djuric');

const _srednja = ListingId('l-srednja');
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
  _malaMatura: 'Priprema za malu maturu',
  _gimnazija: 'Matematika i fizika za gimnazijalce',
  _prijemni: 'Matematika za prijemni na FTN',
};

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
      listing: _gimnazija,
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
      listing: _gimnazija,
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
