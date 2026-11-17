-- migrate:up
CREATE TABLE users (
  id text PRIMARY KEY,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('student', 'professor', 'admin')),
  login text UNIQUE,
  password_hash text
);

CREATE TABLE professor_profiles (
  user_id text PRIMARY KEY REFERENCES users (id),
  city text NOT NULL,
  bio text NOT NULL,
  education jsonb NOT NULL DEFAULT '[]',
  experience jsonb NOT NULL DEFAULT '[]',
  verification text NOT NULL CHECK (verification IN ('not_verified', 'awaiting_review', 'verified', 'rejected')),
  submitted_at timestamptz,
  diploma_file text,
  linkedin_url text,
  decided_by text REFERENCES users (id),
  decided_at timestamptz,
  rejection_reason text
);

CREATE TABLE listings (
  id text PRIMARY KEY,
  professor_id text NOT NULL REFERENCES users (id),
  subject text NOT NULL,
  level text NOT NULL,
  city text NOT NULL,
  description text NOT NULL,
  price_rsd int NOT NULL CHECK (price_rsd > 0),
  duration_minutes int NOT NULL CHECK (duration_minutes IN (45, 60, 90))
);

CREATE TABLE slots (
  id text PRIMARY KEY,
  listing_id text NOT NULL REFERENCES listings (id),
  professor_id text NOT NULL REFERENCES users (id),
  starts_at timestamptz NOT NULL,
  duration_minutes int NOT NULL
);

CREATE TABLE lessons (
  id text PRIMARY KEY,
  slot_id text NOT NULL REFERENCES slots (id),
  listing_id text NOT NULL REFERENCES listings (id),
  professor_id text NOT NULL REFERENCES users (id),
  professor_name text NOT NULL,
  student_id text NOT NULL REFERENCES users (id),
  student_name text NOT NULL,
  starts_at timestamptz NOT NULL,
  duration_minutes int NOT NULL,
  message text NOT NULL,
  created_at timestamptz NOT NULL,
  status text NOT NULL CHECK (status IN ('pending', 'confirmed', 'rejected', 'cancelled', 'held', 'no_show')),
  status_at timestamptz,
  rejection_cause text CHECK (rejection_cause IN ('by_professor', 'slot_taken')),
  cancelled_by text REFERENCES users (id),
  note text
);

-- The concurrency rule: at most one confirmed lesson per slot, decided by the database.
CREATE UNIQUE INDEX lessons_one_confirmed_per_slot ON lessons (slot_id) WHERE status = 'confirmed';
-- The index above holds only confirmed rows, so reads of every request for a slot need their own.
CREATE INDEX lessons_by_slot ON lessons (slot_id);
CREATE INDEX lessons_by_student ON lessons (student_id);
CREATE INDEX lessons_by_professor ON lessons (professor_id);

-- migrate:down
DROP TABLE lessons;
DROP TABLE slots;
DROP TABLE listings;
DROP TABLE professor_profiles;
DROP TABLE users;
