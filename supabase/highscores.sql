-- Bestenliste für DOSIS
-- Einmal im Supabase-Dashboard unter "SQL Editor" ausführen.

create table if not exists public.highscores (
  id         bigint generated always as identity primary key,
  name       text        not null check (char_length(btrim(name)) between 1 and 20),
  score      integer     not null check (score between -1000 and 10000),
  saved      smallint    not null check (saved between 0 and 15),
  stage      smallint    not null check (stage between 1 and 3),
  created_at timestamptz not null default now()
);

create index if not exists highscores_score_idx on public.highscores (score desc, created_at asc);

-- Row Level Security: jeder darf lesen und neue Einträge anlegen,
-- niemand darf über den öffentlichen Schlüssel ändern oder löschen.
alter table public.highscores enable row level security;

drop policy if exists "highscores lesen" on public.highscores;
create policy "highscores lesen"
  on public.highscores for select
  to anon, authenticated
  using (true);

drop policy if exists "highscores eintragen" on public.highscores;
create policy "highscores eintragen"
  on public.highscores for insert
  to anon, authenticated
  with check (true);

grant select, insert on public.highscores to anon, authenticated;
