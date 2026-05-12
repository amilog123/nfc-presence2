-- =============================================================
-- NFCPresence – Schéma Supabase
-- =============================================================
-- Note de nommage : la table "sessions" représente les cours planifiés.
-- Elle s'appelle "sessions" (et non "courses") car l'app iOS interroge
-- l'endpoint /rest/v1/sessions via PostgREST.
-- =============================================================

-- Extensions -----------------------------------------------

create extension if not exists "pgcrypto";


-- =============================================================
-- Tables
-- =============================================================

-- -------------------------------------------------------------
-- students
-- L'id est celui de auth.users : pas de doublon, RLS simple.
-- -------------------------------------------------------------
create table public.students (
  id         uuid        primary key references auth.users(id) on delete cascade,
  email      text        not null unique,
  nom        text        not null,
  device_id  text        not null,
  created_at timestamptz not null default now()
);

-- -------------------------------------------------------------
-- teachers
-- Gérés manuellement (pas de self-registration).
-- nfc_tag_uid : UID du badge physique du professeur.
-- -------------------------------------------------------------
create table public.teachers (
  id          uuid        primary key default gen_random_uuid(),
  nom         text        not null,
  email       text        not null unique,
  nfc_tag_uid text        not null unique,
  created_at  timestamptz not null default now()
);

-- -------------------------------------------------------------
-- sessions  (= cours planifiés)
-- nfc_tag_uid est dénormalisé depuis teachers pour que l'app iOS
-- puisse le lire en une seule requête sans join.
-- -------------------------------------------------------------
create table public.sessions (
  id          uuid        primary key default gen_random_uuid(),
  titre       text        not null,
  date        date        not null,
  creneau     text        not null check (creneau in ('matin', 'apres-midi')),
  salle       text        not null,
  teacher_id  uuid        not null references public.teachers(id) on delete cascade,
  nfc_tag_uid text        not null,
  created_at  timestamptz not null default now()
);

-- -------------------------------------------------------------
-- signatures
-- unique (student_id, session_id) : une seule signature par
-- étudiant par session.
-- -------------------------------------------------------------
create table public.signatures (
  id           uuid        primary key default gen_random_uuid(),
  student_id   uuid        not null references public.students(id)  on delete cascade,
  session_id   uuid        not null references public.sessions(id)  on delete cascade,
  creneau      text        not null check (creneau in ('matin', 'apres-midi')),
  image_base64 text,
  timestamp    timestamptz not null default now(),
  device_id    text        not null,
  nfc_uid      text        not null,
  hash         text        not null,
  created_at   timestamptz not null default now(),

  constraint unique_student_session unique (student_id, session_id)
);


-- =============================================================
-- Index
-- =============================================================

-- sessions : requête principale = "sessions du jour"
create index idx_sessions_date       on public.sessions(date);
create index idx_sessions_teacher_id on public.sessions(teacher_id);

-- signatures : historique étudiant + dédoublonnage
create index idx_signatures_student_id on public.signatures(student_id);
create index idx_signatures_session_id on public.signatures(session_id);
create index idx_signatures_timestamp  on public.signatures(timestamp desc);

-- students / teachers : lookup par email et par tag NFC
create index idx_students_email        on public.students(email);
create index idx_teachers_nfc_tag_uid  on public.teachers(nfc_tag_uid);


-- =============================================================
-- Row Level Security
-- =============================================================

alter table public.students   enable row level security;
alter table public.teachers   enable row level security;
alter table public.sessions   enable row level security;
alter table public.signatures enable row level security;

-- -------------------------------------------------------------
-- students
-- Un étudiant ne voit et ne modifie que sa propre ligne.
-- L'insertion est autorisée uniquement avec son propre auth.uid().
-- -------------------------------------------------------------
create policy "students: select own"
  on public.students for select
  using (id = auth.uid());

create policy "students: insert own"
  on public.students for insert
  with check (id = auth.uid());

create policy "students: update own"
  on public.students for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- -------------------------------------------------------------
-- teachers
-- Lecture seule pour tous les utilisateurs authentifiés.
-- (L'app vérifie le nfc_tag_uid du prof lors du scan.)
-- -------------------------------------------------------------
create policy "teachers: select authenticated"
  on public.teachers for select
  to authenticated
  using (true);

-- -------------------------------------------------------------
-- sessions
-- Lecture seule pour tous les utilisateurs authentifiés.
-- La création/modification est réservée aux admins (service_role).
-- -------------------------------------------------------------
create policy "sessions: select authenticated"
  on public.sessions for select
  to authenticated
  using (true);

-- -------------------------------------------------------------
-- signatures
-- Un étudiant insère et lit uniquement ses propres signatures.
-- -------------------------------------------------------------
create policy "signatures: select own"
  on public.signatures for select
  using (student_id = auth.uid());

create policy "signatures: insert own"
  on public.signatures for insert
  with check (student_id = auth.uid());
