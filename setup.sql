-- À coller dans Supabase > SQL Editor > Run
create extension if not exists pgcrypto;
create table participants(id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  name text not null check(char_length(name) between 1 and 60), prayer text check(char_length(prayer)<=500),
  share_public boolean not null default false, consent boolean not null check(consent));
create table visits(id bigint generated always as identity primary key, created_at timestamptz default now(), page text);
create table completions(id bigint generated always as identity primary key, created_at timestamptz default now(),
  level int check(level between 1 and 3), score int, total int, name text);
alter table participants enable row level security;
alter table visits enable row level security;
alter table completions enable row level security;
-- Le public peut seulement ÉCRIRE (jamais lire les tables)
create policy "anon insert" on participants for insert to anon with check(true);
create policy "anon insert" on visits for insert to anon with check(true);
create policy "anon insert" on completions for insert to anon with check(true);
-- Seul le compte admin connecté peut tout lire / supprimer
create policy "admin all" on participants for all to authenticated using(true) with check(true);
create policy "admin all" on visits for all to authenticated using(true) with check(true);
create policy "admin all" on completions for all to authenticated using(true) with check(true);
-- Données publiques minimales : compteurs + mur de prière (uniquement les sujets cochés "public")
create function public_stats() returns json language sql security definer set search_path=public as $$
 select json_build_object('participants',(select count(*) from participants),'visits',(select count(*) from visits),'completions',(select count(*) from completions)) $$;
create function public_wall() returns table(name text, prayer text) language sql security definer set search_path=public as $$
 select name,prayer from participants where share_public and prayer is not null order by created_at desc limit 30 $$;
grant execute on function public_stats(), public_wall() to anon, authenticated;
