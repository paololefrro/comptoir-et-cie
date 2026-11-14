-- Sauvegarde en ligne de Comptoir & Cie
-- À coller dans Supabase : SQL Editor → New query → Run.
-- Une ligne par joueur. Chaque joueur ne peut lire et modifier que sa propre sauvegarde.

create table if not exists public.saves (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null,
  day integer,
  money numeric,
  updated_at timestamptz not null default now()
);

alter table public.saves enable row level security;

drop policy if exists "Lire sa sauvegarde" on public.saves;
drop policy if exists "Créer sa sauvegarde" on public.saves;
drop policy if exists "Modifier sa sauvegarde" on public.saves;
drop policy if exists "Supprimer sa sauvegarde" on public.saves;

create policy "Lire sa sauvegarde" on public.saves
  for select using (auth.uid() = user_id);

create policy "Créer sa sauvegarde" on public.saves
  for insert with check (auth.uid() = user_id);

create policy "Modifier sa sauvegarde" on public.saves
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Supprimer sa sauvegarde" on public.saves
  for delete using (auth.uid() = user_id);
