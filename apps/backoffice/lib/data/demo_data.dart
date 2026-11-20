import 'package:domain/domain.dart';

const milica = User(id: UserId('milica'), name: 'Milica Jovanović', role: Role.professor);
const admin = User(id: UserId('admin'), name: 'Jovana Ilić', role: Role.admin);
// Učenica ima nalog samo da bi se videlo da backoffice odbija učenike.
const ana = User(id: UserId('ana-markovic'), name: 'Ana Marković', role: Role.student);

const _srednja = ListingId('l-srednja');
const _malaMatura = ListingId('l-mala-matura');
const _prijemni = ListingId('l-prijemni');

// Imena se prepisuju u čas kad stigne zahtev (lesson.studentName), pa ekranima ne treba mapa sa imenima.
const _nikola = User(id: UserId('nikola-petrovic'), name: 'Nikola Petrović', role: Role.student);
const _marija = User(id: UserId('marija-stojanovic'), name: 'Marija Stojanović', role: Role.student);
const _luka = User(id: UserId('luka-ilic'), name: 'Luka Ilić', role: Role.student);
const _teodora = User(id: UserId('teodora-djordjevic'), name: 'Teodora Đorđević', role: Role.student);
const _stefan = User(id: UserId('stefan-popovic'), name: 'Stefan Popović', role: Role.student);
const _vuk = User(id: UserId('vuk-lazic'), name: 'Vuk Lazić', role: Role.student);
const _mina = User(id: UserId('mina-kostic'), name: 'Mina Kostić', role: Role.student);
const _petar = User(id: UserId('petar-jankovic'), name: 'Petar Janković', role: Role.student);

// Čas nosi samo id oglasa, ne i naziv. Kolona oglas čita ovu mapu.
// Seed na serveru koristi iste id-jeve oglasa, pa mapa radi i nad serverom.
const listingTitles = <ListingId, String>{
  _srednja: 'Matematika za srednju školu i pripremu za fakultet',
  _malaMatura: 'Priprema za malu maturu',
  _prijemni: 'Matematika za prijemni na FTN',
};

// Ako naziva nema u mapi (oglas iz seeda koji ovde ne postoji), ekran pokaže id, da ne bi pukao.
String listingTitle(ListingId id) => listingTitles[id] ?? id.value;

const _durations = <ListingId, LessonDuration>{
  _srednja: LessonDuration.minutes60,
  _malaMatura: LessonDuration.minutes45,
  _prijemni: LessonDuration.minutes90,
};

// Termin za demo automatskog odbijanja. Računa se od now, pa je u budućnosti na bilo koji dan odbrane.
// Bar 2 dana unapred, da ne bude bliže od pravila od 24 sata.
DateTime nextThursdayAt17(DateTime now) {
  final local = now.toLocal();
  for (var days = 0; ; days++) {
    final candidate = DateTime(local.year, local.month, local.day + days, 17);
    if (candidate.weekday == DateTime.thursday && candidate.difference(local) >= const Duration(days: 2)) {
      return candidate;
    }
  }
}

// Pun sat, da u tabeli ne piše 14:37.
DateTime _dayAt(DateTime now, int days, int hour) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day + days, hour);
}

List<Lesson> demoLessons(DateTime now) {
  DateTime hoursAgo(int hours) => now.subtract(Duration(hours: hours));
  DateTime dayAt(int days, int hour) => _dayAt(now, days, hour);

  final local = now.toLocal();
  final startedAnHourAgo = DateTime(local.year, local.month, local.day, local.hour - 1);
  const takenSlot = 's-c-09';

  return [
    // Tri zahteva za isti termin. Potvrda jednog odbija druga dva.
    _lesson(
      'c-01',
      student: ana,
      listing: _srednja,
      slot: 's-thu-17',
      start: nextThursdayAt17(now),
      createdAt: hoursAgo(26),
      message:
          'Imam kontrolni iz integrala sledeće nedelje i ne snalazim se sa parcijalnom integracijom. '
          'Možemo li da prođemo zadatke iz zbirke?',
    ),
    _lesson(
      'c-02',
      student: _nikola,
      listing: _srednja,
      slot: 's-thu-17',
      start: nextThursdayAt17(now),
      createdAt: hoursAgo(20),
      message: 'Spremam se za pismeni iz analize. Najviše mi trebaju granične vrednosti i izvodi.',
    ),
    _lesson(
      'c-03',
      student: _marija,
      listing: _srednja,
      slot: 's-thu-17',
      start: nextThursdayAt17(now),
      createdAt: hoursAgo(3),
      message: 'Treći razred gimnazije, trigonometrija mi je slaba tačka. Volela bih da utvrdimo adicione formule.',
    ),
    _lesson(
      'c-04',
      student: _luka,
      listing: _malaMatura,
      start: dayAt(3, 10),
      createdAt: hoursAgo(30),
      message: 'Osmi sam razred i spremam malu maturu. Najteži su mi zadaci sa procentima i površinama.',
    ),
    _lesson(
      'c-05',
      student: _teodora,
      listing: _prijemni,
      start: dayAt(4, 18),
      createdAt: hoursAgo(8),
      message: 'Spremam prijemni na FTN u junu. Htela bih da radimo stare testove i vidimo gde gubim poene.',
    ),
    // Počeo je pre sat vremena, pa može da se označi kao održan ili neodržan.
    _lesson(
      'c-06',
      student: _stefan,
      listing: _srednja,
      start: startedAnHourAgo,
      createdAt: hoursAgo(80),
      message: 'Treba mi pomoć oko kvadratnih nejednačina, imam test u petak.',
      status: Confirmed(at: hoursAgo(76)),
    ),
    // Još nisu počeli, pa „održan“ vraća LessonNotStarted.
    _lesson(
      'c-07',
      student: ana,
      listing: _prijemni,
      start: dayAt(2, 12),
      createdAt: hoursAgo(30),
      message: 'Posle prvog časa bih da nastavimo sa određenim integralima i površinama.',
      status: Confirmed(at: hoursAgo(27)),
    ),
    _lesson(
      'c-08',
      student: _vuk,
      listing: _malaMatura,
      start: dayAt(6, 16),
      createdAt: hoursAgo(50),
      message: 'Želim da prođemo jednačine i razlomke, to mi najslabije ide za malu maturu.',
      status: Confirmed(at: hoursAgo(46)),
    ),
    _lesson(
      'c-09',
      student: _mina,
      listing: _srednja,
      slot: takenSlot,
      start: dayAt(-2, 17),
      createdAt: dayAt(-6, 11),
      message: 'Imam usmeno odgovaranje iz logaritama sledeće nedelje.',
      status: Held(at: dayAt(-2, 20)),
    ),
    _lesson(
      'c-10',
      student: _teodora,
      listing: _prijemni,
      start: dayAt(-5, 10),
      createdAt: dayAt(-8, 19),
      message: 'Htela bih da prođemo prošlogodišnji prijemni, posebno zadatke sa funkcijama.',
      status: Held(
        at: dayAt(-5, 13),
        note: LessonNote.parse('Prošli smo ceo test iz 2025. Za sledeći put: zadaci 14–20 i ponoviti logaritme.')
            .valueOrNull,
      ),
    ),
    _lesson(
      'c-11',
      student: _petar,
      listing: _malaMatura,
      start: dayAt(-9, 18),
      createdAt: dayAt(-12, 9),
      message: 'Spremam se za probni test male mature, potrebna mi je geometrija.',
      status: Held(at: dayAt(-9, 21)),
    ),
    _lesson(
      'c-12',
      student: _luka,
      listing: _srednja,
      start: dayAt(-4, 15),
      createdAt: dayAt(-7, 16),
      message: 'Možemo li da ponovimo jednačine sa jednom nepoznatom?',
      status: NoShow(at: dayAt(-4, 17)),
    ),
    _lesson(
      'c-13',
      student: _petar,
      listing: _prijemni,
      start: dayAt(5, 8),
      createdAt: hoursAgo(28),
      message: 'Odgovara mi samo rano ujutru. Treba mi priprema za prijemni iz matematike.',
      status: Rejected(cause: RejectionCause.byProfessor, at: hoursAgo(25)),
    ),
    // Isti termin kao c-09. Odbijen je kad je c-09 potvrđen.
    _lesson(
      'c-14',
      student: _nikola,
      listing: _srednja,
      slot: takenSlot,
      start: dayAt(-2, 17),
      createdAt: dayAt(-6, 18),
      message: 'Treba mi pomoć oko vektora i analitičke geometrije.',
      status: Rejected(cause: RejectionCause.slotTaken, at: dayAt(-5, 9)),
    ),
    _lesson(
      'c-15',
      student: _vuk,
      listing: _malaMatura,
      start: dayAt(7, 11),
      createdAt: hoursAgo(72),
      message: 'Želeo bih još jedan čas pred probni test.',
      status: Cancelled(by: _vuk.id, at: hoursAgo(24)),
    ),
  ];
}

Lesson _lesson(
  String id, {
  required User student,
  required ListingId listing,
  required DateTime start,
  required DateTime createdAt,
  required String message,
  String? slot,
  LessonStatus status = const Pending(),
}) => Lesson(
  id: LessonId(id),
  slotId: SlotId(slot ?? 's-$id'),
  listingId: listing,
  professorId: milica.id,
  professorName: milica.name,
  studentId: student.id,
  studentName: student.name,
  start: start,
  duration: _durations[listing]!,
  message: RequestMessage.parse(message).valueOrNull!,
  createdAt: createdAt,
  status: status,
);

// U podacima ih je 7, a u redu za verifikaciju se vide samo 4 koja čekaju. Tako se vidi da filter radi.
List<ProfessorProfile> demoProfessors(DateTime now) {
  DateTime hoursAgo(int hours) => now.subtract(Duration(hours: hours));

  return [
    ProfessorProfile(
      id: milica.id,
      fullName: milica.name,
      city: City.belgrade,
      bio: 'Profesorka matematike u gimnaziji, deset godina pripremam učenike za prijemni.',
      verification: Verified(by: admin.id, at: hoursAgo(24 * 40)),
    ),
    _awaiting(
      'jelena-markovic',
      'Jelena Marković',
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
      'milan-djuric',
      'Milan Đurić',
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
      'ana-kovacevic',
      'Ana Kovačević',
      city: City.kragujevac,
      submittedAt: hoursAgo(24 * 3),
      bio: 'Doktorantkinja na PMF-u, pomažem studentima prve godine oko analize i linearne algebre.',
      education: (
        institution: 'Prirodno-matematički fakultet u Kragujevcu',
        title: 'Master matematičar',
        fromYear: 2016,
        toYear: 2021,
      ),
      experience: (
        employer: 'Prirodno-matematički fakultet u Kragujevcu',
        title: 'Saradnica u nastavi',
        fromYear: 2021,
        toYear: null,
      ),
    ),
    _awaiting(
      'dragan-simic',
      'Dragan Simić',
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
      id: const UserId('ivana-pavlovic'),
      fullName: 'Ivana Pavlović',
      city: City.belgrade,
      bio: 'Predajem matematiku osnovcima.',
      verification: VerificationRejected(
        by: admin.id,
        at: hoursAgo(24 * 2),
        reason: RejectionReason.parse('Sken diplome je nečitak. Pošaljite jasniju kopiju.').valueOrNull!,
      ),
    ),
    const ProfessorProfile(
      id: UserId('bojan-stankovic'),
      fullName: 'Bojan Stanković',
      city: City.noviSad,
      bio: 'Student četvrte godine matematike.',
    ),
  ];
}

ProfessorProfile _awaiting(
  String slug,
  String fullName, {
  required City city,
  required DateTime submittedAt,
  required String bio,
  required Education education,
  required WorkExperience experience,
}) => ProfessorProfile(
  id: UserId(slug),
  fullName: fullName,
  city: city,
  bio: bio,
  education: [education],
  experience: [experience],
  verification: AwaitingReview(
    submittedAt: submittedAt,
    diplomaFile: 'diploma-$slug.pdf',
    linkedIn: LinkedInUrl.parse('https://www.linkedin.com/in/$slug').valueOrNull!,
  ),
);
