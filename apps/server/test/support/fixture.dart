import 'package:postgres/postgres.dart' show QueryMode;
import 'package:server/server.dart';

/// Rows every repository test starts from: an admin, five professors (one per verification state, two awaiting
/// review), three students, three listings and four slots. Lessons are added by the tests that need them.
///
/// Professor names start with different ASCII letters, so `ORDER BY name` is the same under every collation.
const fixtureSql = '''
INSERT INTO users (id, name, role) VALUES
  ('jovana', 'Jovana Admin', 'admin'),
  ('milica', 'Milica Petrović', 'professor'),
  ('jovan', 'Jovan Marković', 'professor'),
  ('vesna', 'Vesna Ilić', 'professor'),
  ('luka', 'Luka Popović', 'professor'),
  ('sara', 'Sara Nikolić', 'professor'),
  ('ana', 'Ana Jovanović', 'student'),
  ('nikola', 'Nikola Ilić', 'student'),
  ('marija', 'Marija Stojanović', 'student');

INSERT INTO professor_profiles (user_id, city, bio, education, experience, verification,
                                submitted_at, diploma_file, linkedin_url, decided_by, decided_at, rejection_reason)
VALUES
  ('milica', 'belgrade', 'Matematika za srednju školu.',
   '[{"institution": "Matematički fakultet", "title": "Master matematike", "fromYear": 2012, "toYear": 2017}]',
   '[{"employer": "Treća beogradska gimnazija", "title": "Profesor", "fromYear": 2017, "toYear": null}]',
   'verified', '2026-10-01 09:00+00', 'diplome/milica.pdf', 'https://www.linkedin.com/in/milica',
   'jovana', '2026-10-02 12:00+00', NULL),
  ('jovan', 'noviSad', 'Fizika za fakultet.', '[]', '[]',
   'awaiting_review', '2026-11-10 08:30+00', 'diplome/jovan.pdf', 'https://www.linkedin.com/in/jovan', NULL, NULL, NULL),
  ('vesna', 'nis', 'Hemija.', '[]', '[]',
   'awaiting_review', '2026-11-05 14:00+00', 'diplome/vesna.pdf', 'https://www.linkedin.com/in/vesna', NULL, NULL, NULL),
  ('luka', 'kragujevac', 'Istorija.', '[]', '[]',
   'rejected', '2026-10-20 10:00+00', 'diplome/luka.pdf', 'https://www.linkedin.com/in/luka',
   'jovana', '2026-10-21 10:00+00', 'Diploma na slici nije čitljiva.'),
  ('sara', 'subotica', 'Engleski jezik.', '[]', '[]', 'not_verified', NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO listings (id, professor_id, subject, level, city, description, price_rsd, duration_minutes) VALUES
  ('l-exam', 'milica', 'mathematics', 'entranceExam', 'belgrade', 'Prijemni za ETF', 2500, 90),
  ('l-math', 'milica', 'mathematics', 'highSchool', 'belgrade', 'Analiza i algebra', 2000, 60),
  ('l-physics', 'jovan', 'physics', 'university', 'noviSad', 'Fizika 1', 1800, 45);

INSERT INTO slots (id, listing_id, professor_id, starts_at, duration_minutes) VALUES
  ('s-1', 'l-math', 'milica', '2026-12-01 10:00+00', 60),
  ('s-2', 'l-math', 'milica', '2026-12-01 12:00+00', 60),
  ('s-3', 'l-exam', 'milica', '2026-11-30 16:00+00', 90),
  ('s-4', 'l-physics', 'jovan', '2026-12-02 09:00+00', 45);
''';

Future<void> insertFixture(Database database) => insertRows(database, fixtureSql);

/// Runs [sql] (one or more statements) as it is. For rows a test adds on top of the fixture.
Future<void> insertRows(Database database, String sql) =>
    database.run((db) => db.execute(sql, queryMode: QueryMode.simple));
