-- =====================================================================
-- Comptoir & Cie · mesure d'audience et tableau de bord privé
-- À exécuter une fois dans Supabase → SQL Editor, après supabase.sql.
-- Le fichier peut être relancé sans risque : il ne supprime aucune donnée.
-- =====================================================================

-- 1. Une ligne par visite, sans donnée personnelle : un identifiant tiré
--    au hasard par le navigateur, la durée, le type d'appareil, le site
--    d'où vient le joueur et sa progression dans le jeu.
create table if not exists public.visits (
  id          uuid primary key,
  visitor     uuid not null,
  started_at  timestamptz not null default now(),
  last_seen   timestamptz not null default now(),
  seconds     int  not null default 0 check (seconds between 0 and 86400),
  device      text check (char_length(device) <= 12),
  referrer    text check (char_length(referrer) <= 80),
  days_played int  not null default 0 check (days_played between 0 and 10000),
  game_day    int,
  game_level  int
);
create index if not exists visits_started_idx on public.visits (started_at);
create index if not exists visits_visitor_idx on public.visits (visitor, started_at);
alter table public.visits enable row level security;
revoke all on public.visits from anon, authenticated;

-- 2. Le site enregistre les visites uniquement par cette fonction.
create or replace function public.track_visit(
  p_id uuid, p_visitor uuid, p_seconds int default 0,
  p_device text default null, p_referrer text default null,
  p_days int default 0, p_day int default null, p_level int default null)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.visits as v (id, visitor, seconds, device, referrer, days_played, game_day, game_level)
  values (p_id, p_visitor,
          least(greatest(coalesce(p_seconds, 0), 0), 86400),
          left(p_device, 12), left(p_referrer, 80),
          least(greatest(coalesce(p_days, 0), 0), 10000),
          case when p_day between 1 and 1000000 then p_day end,
          case when p_level between 1 and 1000 then p_level end)
  on conflict (id) do update set
    last_seen   = now(),
    seconds     = greatest(v.seconds, excluded.seconds),
    days_played = greatest(v.days_played, excluded.days_played),
    game_day    = coalesce(excluded.game_day, v.game_day),
    game_level  = coalesce(excluded.game_level, v.game_level)
  where v.visitor = excluded.visitor and v.started_at > now() - interval '1 day';

  -- Ménage de temps en temps : la CNIL recommande de ne pas garder ces données plus de 25 mois.
  if random() < 0.002 then
    delete from public.visits where started_at < now() - interval '25 months';
  end if;
end $$;
revoke all on function public.track_visit(uuid, uuid, int, text, text, int, int, int) from public, anon, authenticated;
grant execute on function public.track_visit(uuid, uuid, int, text, text, int, int, int) to anon, authenticated;

-- 3. Les adresses e-mail qui ont le droit de voir les statistiques.
create table if not exists public.admins (email text primary key);
alter table public.admins enable row level security;
revoke all on public.admins from anon, authenticated;
insert into public.admins (email) values ('paul_guinot@orange.fr') on conflict do nothing;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public, auth
as $$
  select exists (
    select 1
    from auth.users u
    join public.admins a on lower(a.email) = lower(u.email)
    where u.id = auth.uid() and u.email_confirmed_at is not null
  );
$$;
revoke all on function public.is_admin() from public, anon, authenticated;
grant execute on function public.is_admin() to authenticated;

-- 4. Le calcul des statistiques (jours comptés à l'heure de Paris).
create or replace function public.stats_data(p_days int default 30)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare
  tz    constant text := 'Europe/Paris';
  n     int  := least(greatest(coalesce(p_days, 30), 1), 365);
  today date := (now() at time zone tz)::date;
  d0    date := today - (n - 1);
  t0    timestamptz := d0::timestamp at time zone tz;
  p0    timestamptz := (d0 - n)::timestamp at time zone tz;
  result jsonb;
begin
  with
  firsts as (
    select visitor, min((started_at at time zone tz)::date) as first_day
    from public.visits group by visitor
  ),
  v as (
    select x.*, (x.started_at at time zone tz)::date as day,
           extract(hour from x.started_at at time zone tz)::int as hour,
           f.first_day
    from public.visits x join firsts f using (visitor)
    where x.started_at >= t0
  )
  select jsonb_build_object(
    'generated_at', now(),
    'days', n,
    'live', (select count(distinct visitor) from public.visits where last_seen > now() - interval '5 minutes'),
    'today', (select jsonb_build_object(
        'visitors', count(distinct visitor),
        'visits',   count(*),
        'new',      count(distinct visitor) filter (where first_day = day))
      from v where day = today),
    'period', (select jsonb_build_object(
        'visitors',      count(distinct visitor),
        'visits',        count(*),
        'new',           count(distinct visitor) filter (where first_day >= d0),
        'returning',     count(distinct visitor) filter (where day > first_day),
        'avg_seconds',   coalesce(round(avg(seconds)), 0),
        'total_seconds', coalesce(sum(seconds), 0),
        'days_played',   coalesce(sum(days_played), 0))
      from v),
    'previous', (select jsonb_build_object('visitors', count(distinct visitor), 'visits', count(*))
      from public.visits where started_at >= p0 and started_at < t0),
    'daily', (select coalesce(jsonb_agg(jsonb_build_object(
          'day', to_char(g.day, 'YYYY-MM-DD'),
          'visitors', coalesce(s.visitors, 0),
          'visits',   coalesce(s.visits, 0),
          'new',      coalesce(s.new_v, 0)) order by g.day), '[]'::jsonb)
      from generate_series(d0::timestamp, today::timestamp, interval '1 day') as g(day)
      left join (
        select day, count(distinct visitor) as visitors, count(*) as visits,
               count(distinct visitor) filter (where first_day = day) as new_v
        from v group by day
      ) s on s.day = g.day::date),
    'hours', (select jsonb_agg(coalesce(s.c, 0) order by h)
      from generate_series(0, 23) as h
      left join (select hour, count(*) as c from v group by hour) s on s.hour = h),
    'devices', (select coalesce(jsonb_agg(jsonb_build_object('k', k, 'n', c) order by c desc), '[]'::jsonb)
      from (select coalesce(device, 'inconnu') as k, count(distinct visitor) as c from v group by 1) s),
    'referrers', (select coalesce(jsonb_agg(jsonb_build_object('k', k, 'n', c) order by c desc), '[]'::jsonb)
      from (select coalesce(nullif(referrer, ''), 'direct') as k, count(*) as c
            from v group by 1 order by 2 desc limit 8) s),
    'durations', (select jsonb_agg(jsonb_build_object('k', label, 'n', c) order by ord)
      from (select b.ord, b.label, count(v.id) as c
            from (values (1, 'moins d''1 min', 0, 60), (2, '1 à 5 min', 60, 300),
                         (3, '5 à 15 min', 300, 900), (4, '15 à 30 min', 900, 1800),
                         (5, '30 min à 1 h', 1800, 3600), (6, 'plus d''1 h', 3600, 1000000))
                 as b(ord, label, lo, hi)
            left join v on v.seconds >= b.lo and v.seconds < b.hi
            group by b.ord, b.label) s),
    'levels', (select coalesce(jsonb_agg(jsonb_build_object('k', lvl, 'n', c) order by lvl), '[]'::jsonb)
      from (select lvl, count(*) as c
            from (select visitor, max(game_level) as lvl from v where game_level is not null group by visitor) m
            group by lvl) s),
    'retention', jsonb_build_object(
      'd1', (select jsonb_build_object('base', count(*), 'back', count(*) filter (where exists (
                select 1 from public.visits y
                where y.visitor = f.visitor and y.started_at >= ((f.first_day + 1)::timestamp at time zone tz)
                  and y.started_at < ((f.first_day + 2)::timestamp at time zone tz))))
             from firsts f where f.first_day between d0 and today - 1),
      'd7', (select jsonb_build_object('base', count(*), 'back', count(*) filter (where exists (
                select 1 from public.visits y
                where y.visitor = f.visitor and y.started_at >= ((f.first_day + 1)::timestamp at time zone tz)
                  and y.started_at < ((f.first_day + 8)::timestamp at time zone tz))))
             from firsts f where f.first_day between d0 and today - 7)),
    'suggestions', (select jsonb_build_object('total', count(*), 'new', count(*) filter (where status = 'nouvelle'))
      from public.suggestions),
    'accounts', (select count(*) from public.saves)
  ) into result;
  return result;
end $$;
revoke all on function public.stats_data(int) from public, anon, authenticated;

-- 5. Le point d'entrée du tableau de bord : réservé aux comptes de la table admins.
create or replace function public.admin_stats(p_days int default 30)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Ce compte n''a pas accès aux statistiques.' using errcode = '42501';
  end if;
  return public.stats_data(p_days);
end $$;
revoke all on function public.admin_stats(int) from public, anon, authenticated;
grant execute on function public.admin_stats(int) to authenticated;
