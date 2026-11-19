import 'package:domain/domain.dart';

/// Everything the seed writes, as domain objects. Built from both apps' KT1 `demo_data.dart`, merged:
///
/// - **Accounts** (§1.6 of the KT2 plan): `ucenik1` Ana, `ucenik2` Nikola, `profesor1` Milica, `admin1` Jovana.
///   Everyone else has no login; they exist so that lists have more than one name in them.
/// - **Milica's lessons** are the backoffice's queue. **Ana's lessons with other professors** are the mobile app's.
/// - **Nikola Petrović** was a professor in the mobile data, but §1.6 makes him a student, so his physics listing
///   went to Jelena Marković.
///
/// Every message, note and reason goes through the domain's `parse`, so the seed cannot hold a value the rules
/// would refuse.
final class DemoData {
  const DemoData({
    required this.logins,
    required this.users,
    required this.profiles,
    required this.listings,
    required this.slots,
    required this.lessons,
  });

  /// The four accounts that can sign in, by login.
  final Map<String, User> logins;

  /// Every user, the four above included.
  final List<User> users;
  final List<ProfessorProfile> profiles;
  final List<Listing> listings;
  final List<Slot> slots;
  final List<Lesson> lessons;
}

const _jovana = User(id: UserId('jovana-ilic'), name: 'Jovana Ilić', role: Role.admin);
const _milica = User(id: UserId('milica-jovanovic'), name: 'Milica Jovanović', role: Role.professor);
const _ana = User(id: UserId('ana-markovic'), name: 'Ana Marković', role: Role.student);
const _nikola = User(id: UserId('nikola-petrovic'), name: 'Nikola Petrović', role: Role.student);

const _marija = User(id: UserId('marija-stojanovic'), name: 'Marija Stojanović', role: Role.student);
const _luka = User(id: UserId('luka-ilic'), name: 'Luka Ilić', role: Role.student);
const _teodora = User(id: UserId('teodora-djordjevic'), name: 'Teodora Đorđević', role: Role.student);
const _stefan = User(id: UserId('stefan-popovic'), name: 'Stefan Popović', role: Role.student);
const _vuk = User(id: UserId('vuk-lazic'), name: 'Vuk Lazić', role: Role.student);
const _mina = User(id: UserId('mina-kostic'), name: 'Mina Kostić', role: Role.student);
const _petar = User(id: UserId('petar-jankovic'), name: 'Petar Janković', role: Role.student);

const _anaK = User(id: UserId('ana-kovacevic'), name: 'Ana Kovačević', role: Role.professor);
const _jelena = User(id: UserId('jelena-markovic'), name: 'Jelena Marković', role: Role.professor);
const _milan = User(id: UserId('milan-djuric'), name: 'Milan Đurić', role: Role.professor);
const _dragan = User(id: UserId('dragan-simic'), name: 'Dragan Simić', role: Role.professor);
const _ivana = User(id: UserId('ivana-pavlovic'), name: 'Ivana Pavlović', role: Role.professor);
const _bojan = User(id: UserId('bojan-stankovic'), name: 'Bojan Stanković', role: Role.professor);

/// The demo data for a database seeded at [now]. Every time is relative to [now] and on a whole UTC hour, so the
/// demo works on any day: reseed (`docker compose down -v && docker compose up -d`) on the morning of the defense.
DemoData demoData(DateTime now) {
  final utc = now.toUtc();
  final thisHour = DateTime.utc(utc.year, utc.month, utc.day, utc.hour);
  DateTime dayAt(int days, int hour) => DateTime.utc(utc.year, utc.month, utc.day + days, hour);
  DateTime hoursAgo(int hours) => thisHour.subtract(Duration(hours: hours));

  final listings = _listings();
  Listing listing(String id) => listings.firstWhere((listing) => listing.id.value == id);

  final srednja = listing('l-srednja');
  final malaMatura = listing('l-mala-matura');
  final prijemni = listing('l-prijemni');
  final prijemniKg = listing('l-prijemni-kg');
  final gimnazija = listing('l-gimnazija');
  final fizika = listing('l-fizika');
  final malaMaturaNis = listing('l-mala-matura-nis');

  // The slot that three students want at once: confirming one request auto-rejects the other two.
  const sharedSlot = 's-c-01';
  final sharedStart = dayAt(3, 16);
  // c-09 was held on this slot. c-14 asked for it too and was rejected when c-09 was confirmed.
  const heldSlot = 's-c-09';

  final lessons = [
    // ----- Milica's queue (the backoffice) -----
    _lesson(
      'c-01',
      _ana,
      srednja,
      slot: sharedSlot,
      start: sharedStart,
      createdAt: hoursAgo(26),
      message:
          'Imam kontrolni iz integrala sledeće nedelje i ne snalazim se sa parcijalnom integracijom. '
          'Možemo li da prođemo zadatke iz zbirke?',
    ),
    _lesson(
      'c-02',
      _nikola,
      srednja,
      slot: sharedSlot,
      start: sharedStart,
      createdAt: hoursAgo(20),
      message: 'Spremam se za pismeni iz analize. Najviše mi trebaju granične vrednosti i izvodi.',
    ),
    _lesson(
      'c-03',
      _marija,
      srednja,
      slot: sharedSlot,
      start: sharedStart,
      createdAt: hoursAgo(3),
      message: 'Treći razred gimnazije, trigonometrija mi je slaba tačka. Volela bih da utvrdimo adicione formule.',
    ),
    _lesson(
      'c-04',
      _luka,
      malaMatura,
      start: dayAt(3, 10),
      createdAt: hoursAgo(30),
      message: 'Osmi sam razred i spremam malu maturu. Najteži su mi zadaci sa procentima i površinama.',
    ),
    _lesson(
      'c-05',
      _teodora,
      prijemni,
      start: dayAt(4, 18),
      createdAt: hoursAgo(8),
      message: 'Spremam prijemni na ETF u junu. Htela bih da radimo stare testove i vidimo gde gubim poene.',
    ),
    // Started an hour ago: the professor can record it as held or as a no-show.
    _lesson(
      'c-06',
      _stefan,
      srednja,
      start: hoursAgo(1),
      createdAt: hoursAgo(80),
      message: 'Treba mi pomoć oko kvadratnih nejednačina, imam test u petak.',
      status: Confirmed(at: hoursAgo(76)),
    ),
    // Two days ahead: "held" is refused (LessonNotStarted), and Ana can still cancel it.
    _lesson(
      'c-07',
      _ana,
      prijemni,
      start: dayAt(2, 12),
      createdAt: hoursAgo(30),
      message: 'Posle prvog časa bih da nastavimo sa određenim integralima i površinama.',
      status: Confirmed(at: hoursAgo(27)),
    ),
    _lesson(
      'c-08',
      _vuk,
      malaMatura,
      start: dayAt(6, 16),
      createdAt: hoursAgo(50),
      message: 'Želim da prođemo jednačine i razlomke, to mi najslabije ide za malu maturu.',
      status: Confirmed(at: hoursAgo(46)),
    ),
    _lesson(
      'c-09',
      _mina,
      srednja,
      slot: heldSlot,
      start: dayAt(-2, 17),
      createdAt: dayAt(-6, 11),
      message: 'Imam usmeno odgovaranje iz logaritama sledeće nedelje.',
      status: Held(at: dayAt(-2, 18)),
    ),
    _lesson(
      'c-10',
      _teodora,
      prijemni,
      start: dayAt(-5, 10),
      createdAt: dayAt(-8, 19),
      message: 'Htela bih da prođemo prošlogodišnji prijemni, posebno zadatke sa funkcijama.',
      status: Held(
        at: dayAt(-5, 12),
        note: _parsed(
          LessonNote.parse('Prošli smo ceo test iz 2025. Za sledeći put: zadaci 14–20 i ponoviti logaritme.'),
        ),
      ),
    ),
    _lesson(
      'c-11',
      _petar,
      malaMatura,
      start: dayAt(-9, 18),
      createdAt: dayAt(-12, 9),
      message: 'Spremam se za probni test male mature, potrebna mi je geometrija.',
      status: Held(at: dayAt(-9, 19)),
    ),
    _lesson(
      'c-12',
      _luka,
      srednja,
      start: dayAt(-4, 15),
      createdAt: dayAt(-7, 16),
      message: 'Možemo li da ponovimo jednačine sa jednom nepoznatom?',
      status: NoShow(at: dayAt(-4, 16)),
    ),
    _lesson(
      'c-13',
      _petar,
      prijemni,
      start: dayAt(5, 8),
      createdAt: hoursAgo(28),
      message: 'Odgovara mi samo rano ujutru. Treba mi priprema za prijemni iz matematike.',
      status: Rejected(cause: RejectionCause.byProfessor, at: hoursAgo(25)),
    ),
    _lesson(
      'c-14',
      _nikola,
      srednja,
      slot: heldSlot,
      start: dayAt(-2, 17),
      createdAt: dayAt(-6, 18),
      message: 'Treba mi pomoć oko vektora i analitičke geometrije.',
      status: Rejected(cause: RejectionCause.slotTaken, at: dayAt(-5, 9)),
    ),
    _lesson(
      'c-15',
      _vuk,
      malaMatura,
      start: dayAt(7, 11),
      createdAt: hoursAgo(72),
      message: 'Želeo bih još jedan čas pred probni test.',
      status: Cancelled(by: _vuk.id, at: hoursAgo(24)),
    ),
    // ----- Ana's lessons (the mobile app) -----
    // Ana's second waiting request, next to c-01. With two waiting, her 3rd request works and her 4th does not.
    _lesson(
      'c-16',
      _ana,
      fizika,
      start: dayAt(5, 18),
      createdAt: hoursAgo(20),
      message: 'Treba mi pomoć iz fizike, kretanje i Njutnovi zakoni.',
    ),
    // In ten hours: too late to cancel (CancellationTooLate).
    _lesson(
      'c-17',
      _ana,
      prijemniKg,
      start: thisHour.add(const Duration(hours: 10)),
      createdAt: hoursAgo(72),
      message: 'Htela bih da radimo stare testove za prijemni.',
      status: Confirmed(at: hoursAgo(70)),
    ),
    _lesson(
      'c-18',
      _ana,
      gimnazija,
      start: dayAt(7, 12),
      createdAt: hoursAgo(30),
      message: 'Treći razred gimnazije, trigonometrija mi je slaba tačka.',
      status: Confirmed(at: hoursAgo(26)),
    ),
    // Held, so Ana can review it.
    _lesson(
      'c-19',
      _ana,
      srednja,
      start: dayAt(-7, 17),
      createdAt: dayAt(-10, 11),
      message: 'Treba mi pomoć oko kvadratnih nejednačina.',
      status: Held(at: dayAt(-7, 18)),
    ),
    _lesson(
      'c-20',
      _ana,
      gimnazija,
      start: dayAt(-14, 15),
      createdAt: dayAt(-17, 9),
      message: 'Imam test iz vektora za nedelju dana.',
      status: Held(at: dayAt(-14, 16)),
    ),
    _lesson(
      'c-21',
      _ana,
      fizika,
      start: dayAt(-3, 18),
      createdAt: dayAt(-8, 10),
      message: 'Možemo li da ponovimo električno polje?',
      status: Cancelled(by: _ana.id, at: dayAt(-6, 9)),
    ),
    _lesson(
      'c-22',
      _ana,
      prijemniKg,
      start: dayAt(-5, 10),
      createdAt: dayAt(-9, 19),
      message: 'Treba mi priprema za prijemni iz matematike.',
      status: Rejected(cause: RejectionCause.slotTaken, at: dayAt(-8, 12)),
    ),
    _lesson(
      'c-23',
      _ana,
      malaMaturaNis,
      start: dayAt(-10, 16),
      createdAt: dayAt(-13, 14),
      message: 'Spremam se za probni test male mature.',
      status: NoShow(at: dayAt(-10, 17)),
    ),
  ];

  return DemoData(
    logins: const {'ucenik1': _ana, 'ucenik2': _nikola, 'profesor1': _milica, 'admin1': _jovana},
    users: const [
      _jovana,
      _milica,
      _ana,
      _nikola,
      _marija,
      _luka,
      _teodora,
      _stefan,
      _vuk,
      _mina,
      _petar,
      _anaK,
      _jelena,
      _milan,
      _dragan,
      _ivana,
      _bojan,
    ],
    profiles: _profiles(dayAt: dayAt, hoursAgo: hoursAgo),
    listings: listings,
    slots: [..._lessonSlots(lessons), ..._freeSlots(listings, dayAt)],
    lessons: lessons,
  );
}

/// The order matters: a professor's n-th listing gets the n-th free-slot hour (see [_freeSlots]).
List<Listing> _listings() => [
  _listing(
    'l-srednja',
    _milica,
    Level.highSchool,
    City.belgrade,
    2000,
    LessonDuration.minutes60,
    'Matematika za srednju školu i pripremu za fakultet',
  ),
  _listing(
    'l-mala-matura',
    _milica,
    Level.primarySchool,
    City.belgrade,
    1500,
    LessonDuration.minutes45,
    'Priprema za malu maturu',
  ),
  _listing(
    'l-prijemni',
    _milica,
    Level.entranceExam,
    City.belgrade,
    2500,
    LessonDuration.minutes90,
    'Matematika za prijemni na ETF',
  ),
  _listing(
    'l-fakultet',
    _milica,
    Level.university,
    City.belgrade,
    2500,
    LessonDuration.minutes60,
    'Analiza za studente prve godine',
  ),
  _listing(
    'l-prijemni-kg',
    _anaK,
    Level.entranceExam,
    City.kragujevac,
    2500,
    LessonDuration.minutes60,
    'Matematika za prijemni na FTN',
  ),
  _listing(
    'l-gimnazija',
    _jelena,
    Level.highSchool,
    City.noviSad,
    2200,
    LessonDuration.minutes60,
    'Matematika i fizika za gimnazijalce',
  ),
  _listing(
    'l-fizika',
    _jelena,
    Level.highSchool,
    City.noviSad,
    1800,
    LessonDuration.minutes60,
    'Fizika za srednju školu',
    subject: Subject.physics,
  ),
  _listing(
    'l-mala-matura-nis',
    _milan,
    Level.primarySchool,
    City.nis,
    1500,
    LessonDuration.minutes60,
    'Priprema za malu maturu',
  ),
];

Listing _listing(
  String id,
  User professor,
  Level level,
  City city,
  int dinars,
  LessonDuration duration,
  String description, {
  Subject subject = Subject.mathematics,
}) => Listing(
  id: ListingId(id),
  professorId: professor.id,
  subject: subject,
  level: level,
  city: city,
  description: description,
  price: _parsed(Price.parse(dinars)),
  duration: duration,
);

/// Seven profiles in all four verification states. The queue shows the three awaiting review.
List<ProfessorProfile> _profiles({
  required DateTime Function(int days, int hour) dayAt,
  required DateTime Function(int hours) hoursAgo,
}) => [
  ProfessorProfile(
    id: _milica.id,
    fullName: _milica.name,
    city: City.belgrade,
    bio: 'Profesorka matematike u gimnaziji, deset godina pripremam učenike za prijemni.',
    education: const [
      (institution: 'Matematički fakultet u Beogradu', title: 'Master matematičar', fromYear: 2010, toYear: 2015),
    ],
    experience: const [
      (employer: 'Treća beogradska gimnazija', title: 'Profesorka matematike', fromYear: 2015, toYear: null),
    ],
    verification: Verified(by: _jovana.id, at: dayAt(-40, 9)),
  ),
  ProfessorProfile(
    id: _anaK.id,
    fullName: _anaK.name,
    city: City.kragujevac,
    bio: 'Doktorantkinja na PMF-u, spremam kandidate za prijemni na tehničkim fakultetima.',
    education: const [
      (
        institution: 'Prirodno-matematički fakultet u Kragujevcu',
        title: 'Master matematičar',
        fromYear: 2016,
        toYear: 2021,
      ),
    ],
    experience: const [
      (
        employer: 'Prirodno-matematički fakultet u Kragujevcu',
        title: 'Saradnica u nastavi',
        fromYear: 2021,
        toYear: null,
      ),
    ],
    verification: Verified(by: _jovana.id, at: dayAt(-60, 10)),
  ),
  _awaiting(
    _jelena,
    city: City.noviSad,
    submittedAt: hoursAgo(5),
    bio: 'Predajem matematiku i fiziku srednjoškolcima, najviše radim sa trećim i četvrtim razredom.',
    education: (
      institution: 'Prirodno-matematički fakultet u Novom Sadu',
      title: 'Master matematičar',
      fromYear: 2014,
      toYear: 2019,
    ),
    experience: (
      employer: 'Gimnazija „Jovan Jovanović Zmaj“',
      title: 'Profesorka matematike',
      fromYear: 2019,
      toYear: null,
    ),
  ),
  _awaiting(
    _milan,
    city: City.nis,
    submittedAt: hoursAgo(24),
    bio: 'Spremam osmake za malu maturu, strpljivo i kroz mnogo zadataka.',
    education: (
      institution: 'Prirodno-matematički fakultet u Nišu',
      title: 'Profesor matematike',
      fromYear: 2010,
      toYear: 2015,
    ),
    experience: (employer: 'OŠ „Sveti Sava“ Niš', title: 'Nastavnik matematike', fromYear: 2015, toYear: null),
  ),
  _awaiting(
    _dragan,
    city: City.subotica,
    submittedAt: hoursAgo(24 * 6),
    bio: 'Inženjer elektrotehnike, spremam kandidate za prijemni na tehničkim fakultetima.',
    education: (
      institution: 'Fakultet tehničkih nauka u Novom Sadu',
      title: 'Diplomirani inženjer elektrotehnike',
      fromYear: 2005,
      toYear: 2010,
    ),
    experience: (employer: 'Privatni časovi', title: 'Predavač matematike', fromYear: 2012, toYear: null),
  ),
  ProfessorProfile(
    id: _ivana.id,
    fullName: _ivana.name,
    city: City.belgrade,
    bio: 'Predajem matematiku osnovcima.',
    verification: VerificationRejected(
      by: _jovana.id,
      at: hoursAgo(48),
      reason: _parsed(RejectionReason.parse('Sken diplome je nečitak. Pošaljite jasniju kopiju.')),
    ),
  ),
  ProfessorProfile(id: _bojan.id, fullName: _bojan.name, city: City.noviSad, bio: 'Student četvrte godine matematike.'),
];

ProfessorProfile _awaiting(
  User professor, {
  required City city,
  required DateTime submittedAt,
  required String bio,
  required Education education,
  required WorkExperience experience,
}) => ProfessorProfile(
  id: professor.id,
  fullName: professor.name,
  city: city,
  bio: bio,
  education: [education],
  experience: [experience],
  verification: AwaitingReview(
    submittedAt: submittedAt,
    diplomaFile: 'diploma-${professor.id.value}.pdf',
    linkedIn: _parsed(LinkedInUrl.parse('https://www.linkedin.com/in/${professor.id.value}')),
  ),
);

/// A lesson on [listing]: the professor and the length come from the listing, as a request copies them.
/// The slot is `s-<lesson id>` unless several lessons share one.
Lesson _lesson(
  String id,
  User student,
  Listing listing, {
  required DateTime start,
  required DateTime createdAt,
  required String message,
  String? slot,
  LessonStatus status = const Pending(),
}) => Lesson(
  id: LessonId(id),
  slotId: SlotId(slot ?? 's-$id'),
  listingId: listing.id,
  professorId: listing.professorId,
  studentId: student.id,
  start: start,
  duration: listing.duration,
  message: _parsed(RequestMessage.parse(message)),
  createdAt: createdAt,
  status: status,
);

/// One slot per distinct slot id of [lessons], at the lesson's time.
List<Slot> _lessonSlots(List<Lesson> lessons) {
  final slots = <SlotId, Slot>{};
  for (final lesson in lessons) {
    slots[lesson.slotId] ??= Slot(
      id: lesson.slotId,
      listingId: lesson.listingId,
      professorId: lesson.professorId,
      start: lesson.start,
      duration: lesson.duration,
    );
  }
  return slots.values.toList();
}

/// Three free slots per listing, on days +8, +10 and +12, after every lesson. A professor's n-th listing gets
/// hour 9 + 3n, so even a 90-minute slot ends before the next listing's hour and no two slots overlap.
List<Slot> _freeSlots(List<Listing> listings, DateTime Function(int days, int hour) dayAt) {
  final slots = <Slot>[];
  final listingsSoFar = <UserId, int>{};
  for (final listing in listings) {
    final n = listingsSoFar[listing.professorId] ?? 0;
    listingsSoFar[listing.professorId] = n + 1;
    const days = [8, 10, 12];
    for (var k = 0; k < days.length; k++) {
      slots.add(
        Slot(
          id: SlotId('s-${listing.id.value}-$k'),
          listingId: listing.id,
          professorId: listing.professorId,
          start: dayAt(days[k], 9 + 3 * n),
          duration: listing.duration,
        ),
      );
    }
  }
  return slots;
}

/// Demo values are constants, so a parse that fails is a typo in this file: fail at startup, loudly.
T _parsed<T>(Result<T> result) {
  if (result is Success<T>) {
    return result.value;
  }
  throw StateError('Demo data does not parse: ${result.errorOrNull}');
}
