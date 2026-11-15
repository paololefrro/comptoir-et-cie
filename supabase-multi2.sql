-- =====================================================================
-- Comptoir & Cie · multijoueur, 2e partie : défis entre joueurs et clubs
-- À exécuter dans Supabase → SQL Editor, après supabase-multi.sql.
-- Relançable sans perte de données.
-- =====================================================================

-- 1. Colonnes ajoutées aux vitrines -----------------------------------------
alter table public.profiles add column if not exists club_id bigint;
alter table public.profiles add column if not exists duels_won int not null default 0;
alter table public.profiles add column if not exists last_day int;

-- 2. Clubs ----------------------------------------------------------------------
create table if not exists public.clubs (
  id         bigint generated always as identity primary key,
  name       text not null check (char_length(name) between 3 and 30),
  emoji      text not null default '☕' check (char_length(emoji) <= 8),
  motto      text check (char_length(motto) <= 80),
  owner      uuid references public.profiles (id) on delete set null,
  reports    int not null default 0,
  hidden     boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index if not exists clubs_name_idx on public.clubs (lower(name));
alter table public.profiles drop constraint if exists profiles_club_fk;
alter table public.profiles add constraint profiles_club_fk foreign key (club_id) references public.clubs (id) on delete set null;
create index if not exists profiles_club_idx on public.profiles (club_id);

create table if not exists public.club_weeks (
  club_id bigint not null references public.clubs (id) on delete cascade,
  week    date   not null,
  served  bigint not null default 0,
  sales   bigint not null default 0,
  primary key (club_id, week)
);
create table if not exists public.club_claims (
  club_id bigint not null references public.clubs (id) on delete cascade,
  week    date   not null,
  user_id uuid   not null references public.profiles (id) on delete cascade,
  primary key (club_id, week, user_id)
);
create table if not exists public.club_reports (
  club_id  bigint not null references public.clubs (id) on delete cascade,
  reporter uuid   not null references public.profiles (id) on delete cascade,
  primary key (club_id, reporter)
);
alter table public.clubs enable row level security;
alter table public.club_weeks enable row level security;
alter table public.club_claims enable row level security;
alter table public.club_reports enable row level security;
revoke all on public.clubs, public.club_weeks, public.club_claims, public.club_reports from anon, authenticated;

-- Semaine en cours (du lundi, heure de Paris) et objectif commun
create or replace function public.mp_week()
returns date language sql stable
as $$ select date_trunc('week', now() at time zone 'Europe/Paris')::date; $$;

create or replace function public.mp_club_goal(p_members int)
returns bigint language sql immutable
as $$ select greatest(2000, 1000 * coalesce(p_members, 1))::bigint; $$;

-- 3. Défis (duels de ventes sur 3 journées) -----------------------------------
create table if not exists public.duels (
  id          bigint generated always as identity primary key,
  challenger  uuid not null references public.profiles (id) on delete cascade,
  opponent    uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'pending'
              check (status in ('pending', 'active', 'done', 'declined', 'expired', 'cancelled')),
  days        int    not null default 3,
  c_days      int    not null default 0,
  o_days      int    not null default 0,
  c_score     bigint not null default 0,
  o_score     bigint not null default 0,
  winner      uuid,
  c_claimed   boolean not null default false,
  o_claimed   boolean not null default false,
  created_at  timestamptz not null default now(),
  accepted_at timestamptz,
  finished_at timestamptz,
  check (challenger <> opponent)
);
create index if not exists duels_challenger_idx on public.duels (challenger, status);
create index if not exists duels_opponent_idx on public.duels (opponent, status);
alter table public.duels enable row level security;
revoke all on public.duels from anon, authenticated;

-- Termine les duels joués ou trop anciens et compte les victoires
create or replace function public.mp_duels_tick()
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update public.duels set status = 'expired', finished_at = now()
   where status = 'pending' and created_at < now() - interval '48 hours';
  with fin as (
    update public.duels
       set status = 'done', finished_at = now(),
           winner = case when c_score > o_score then challenger when o_score > c_score then opponent end
     where status = 'active'
       and ((c_days >= days and o_days >= days) or accepted_at < now() - interval '72 hours')
    returning winner
  )
  update public.profiles p set duels_won = p.duels_won + w.n
    from (select winner, count(*)::int as n from fin where winner is not null group by winner) w
   where p.id = w.winner;
  if random() < 0.02 then
    delete from public.duels where finished_at < now() - interval '30 days';
  end if;
end $$;

-- 4. Mon profil, ma vitrine et le classement (versions avec défis et clubs) ---
create or replace function public.mp_me()
returns jsonb
language sql stable security definer set search_path = public
as $$
  select case when p.id is null then null else jsonb_build_object(
    'id', p.id, 'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji,
    'level', p.level, 'firm_value', p.firm_value,
    'tips_pending', p.tips_pending, 'tips_total', p.tips_total,
    'cheater', p.cheats > 0, 'hidden', p.hidden, 'banned_until', p.banned_until,
    'club_id', p.club_id, 'duels_won', p.duels_won,
    'duels_todo', (select count(*) from public.duels d
                   where (d.opponent = p.id and d.status = 'pending')
                      or (d.status = 'done' and d.finished_at > now() - interval '7 days'
                          and ((d.challenger = p.id and not d.c_claimed) or (d.opponent = p.id and not d.o_claimed)))),
    'rank', case when p.cheats = 0 and not p.hidden then (
      select count(*) + 1 from public.profiles q
      where q.cheats = 0 and not q.hidden and q.updated_at > now() - interval '30 days' and q.firm_value > p.firm_value) end,
    'players', (select count(*) from public.profiles q
      where q.cheats = 0 and not q.hidden and q.updated_at > now() - interval '30 days')
  ) end
  from (select auth.uid() as uid) u
  left join public.profiles p on p.id = u.uid;
$$;

create or replace function public.mp_leaderboard(p_kind text default 'value')
returns jsonb
language sql stable security definer set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(r) order by r.pos), '[]'::jsonb)
  from (
    select row_number() over (order by s.score desc, s.firm_value desc, s.created_at) as pos,
           s.id, s.pseudo, s.firm_name, s.emoji, s.level, s.firm_value, s.cafes, s.franchises,
           s.rep, s.followers, s.tips_total, s.duels_won
    from (
      select p.*, case p_kind when 'followers' then p.followers::numeric
                              when 'tips' then p.tips_total::numeric
                              when 'duels' then p.duels_won::numeric
                              else p.firm_value::numeric end as score
      from public.profiles p
      where not p.hidden and p.cheats = 0 and p.updated_at > now() - interval '30 days'
    ) s
    order by s.score desc, s.firm_value desc, s.created_at
    limit 50
  ) r;
$$;

-- Annuaire : ajoute le mode « near » (adversaires à ta taille)
create or replace function public.mp_directory(p_mode text default 'recent', p_search text default null)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare
  q    text := nullif(btrim(coalesce(p_search, '')), '');
  mine bigint := coalesce((select firm_value from public.profiles where id = auth.uid()), 0);
  res  jsonb;
begin
  if q is not null then
    q := '%' || replace(replace(replace(left(q, 30), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  end if;
  select coalesce(jsonb_agg(to_jsonb(r) - 'k' order by r.k desc), '[]'::jsonb) into res
  from (
    select p.id, p.pseudo, p.firm_name, p.emoji, p.level, p.firm_value, p.cafes, p.franchises,
           p.rep, p.followers, p.tips_total, p.duels_won, p.cheats > 0 as cheater, p.updated_at,
           case when p_mode = 'random' then random()
                when p_mode = 'near' then -abs(ln(greatest(p.firm_value, 1)) - ln(greatest(mine, 1)))
                else extract(epoch from p.updated_at) end as k
    from public.profiles p
    where not p.hidden and (q is null or p.pseudo ilike q or p.firm_name ilike q)
      and (p_mode <> 'near' or (p.id <> coalesce(auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
                                and p.updated_at > now() - interval '14 days'))
    order by k desc
    limit case when p_mode = 'near' then 8 else 30 end
  ) r;
  return res;
end $$;

create or replace function public.mp_profile(p_id uuid)
returns jsonb
language sql stable security definer set search_path = public
as $$
  select jsonb_build_object(
    'id', p.id, 'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji,
    'level', p.level, 'firm_value', p.firm_value, 'cafes', p.cafes, 'franchises', p.franchises,
    'rep', p.rep, 'followers', p.followers, 'days', p.days, 'served', p.served,
    'best_day', p.best_day, 'items', p.items, 'snapshot', p.snapshot,
    'tips_total', p.tips_total, 'duels_won', p.duels_won, 'cheater', p.cheats > 0,
    'created_at', p.created_at, 'updated_at', p.updated_at,
    'club', (select jsonb_build_object('id', c.id, 'name', c.name, 'emoji', c.emoji)
             from public.clubs c where c.id = p.club_id and not c.hidden),
    'rank', case when p.cheats = 0 then (
      select count(*) + 1 from public.profiles q
      where q.cheats = 0 and not q.hidden and q.updated_at > now() - interval '30 days' and q.firm_value > p.firm_value) end,
    'tipped', exists (select 1 from public.tips t
                      where t.giver = auth.uid() and t.receiver = p.id
                        and t.day = (now() at time zone 'Europe/Paris')::date),
    'dueling', exists (select 1 from public.duels d
                       where d.status in ('pending', 'active')
                         and ((d.challenger = auth.uid() and d.opponent = p.id) or (d.opponent = auth.uid() and d.challenger = p.id))),
    'mine', p.id = auth.uid())
  from public.profiles p
  where p.id = p_id and (not p.hidden or p.id = auth.uid());
$$;

-- 5. Fin de journée : alimente les défis et l'objectif du club -----------------
create or replace function public.mp_report_day(p_day int, p_sales bigint, p_served int)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  me  public.profiles;
  s   bigint := least(greatest(coalesce(p_sales, 0), 0), 1000000000);
  n   int    := least(greatest(coalesce(p_served, 0), 0), 100000);
begin
  select * into me from public.profiles where id = uid;
  if not found then return jsonb_build_object('ok', false); end if;
  -- Une même journée n'est comptée qu'une fois
  if me.last_day is not null and me.last_day = p_day then return jsonb_build_object('ok', true, 'dup', true); end if;
  update public.profiles set last_day = p_day where id = uid;
  update public.duels set c_days = c_days + 1, c_score = c_score + s
   where status = 'active' and challenger = uid and c_days < days;
  update public.duels set o_days = o_days + 1, o_score = o_score + s
   where status = 'active' and opponent = uid and o_days < days;
  perform public.mp_duels_tick();
  if me.club_id is not null then
    insert into public.club_weeks (club_id, week, served, sales) values (me.club_id, public.mp_week(), n, s)
    on conflict (club_id, week) do update set served = club_weeks.served + excluded.served, sales = club_weeks.sales + excluded.sales;
  end if;
  return jsonb_build_object('ok', true);
end $$;

-- 6. Défis --------------------------------------------------------------------------
create or replace function public.mp_duel_create(p_opponent uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not exists (select 1 from public.profiles where id = uid) then
    return jsonb_build_object('ok', false, 'error', 'Rejoins d’abord le multijoueur.');
  end if;
  if p_opponent = uid then return jsonb_build_object('ok', false, 'error', 'Tu ne peux pas te défier toi-même !'); end if;
  if not exists (select 1 from public.profiles where id = p_opponent and not hidden) then
    return jsonb_build_object('ok', false, 'error', 'Ce café est introuvable.');
  end if;
  perform public.mp_duels_tick();
  if exists (select 1 from public.duels where status in ('pending', 'active')
             and ((challenger = uid and opponent = p_opponent) or (challenger = p_opponent and opponent = uid))) then
    return jsonb_build_object('ok', false, 'error', 'Un défi est déjà en cours avec ce café.');
  end if;
  if (select count(*) from public.duels where status in ('pending', 'active') and (challenger = uid or opponent = uid)) >= 3 then
    return jsonb_build_object('ok', false, 'error', 'Tu as déjà 3 défis en cours. Termine-les avant d’en lancer un autre.');
  end if;
  if (select count(*) from public.duels where status in ('pending', 'active') and (challenger = p_opponent or opponent = p_opponent)) >= 5 then
    return jsonb_build_object('ok', false, 'error', 'Ce café a déjà beaucoup de défis en cours. Réessaie plus tard.');
  end if;
  insert into public.duels (challenger, opponent) values (uid, p_opponent);
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.mp_duel_answer(p_id bigint, p_accept boolean)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  perform public.mp_duels_tick();
  if not exists (select 1 from public.duels where id = p_id and opponent = uid and status = 'pending') then
    return jsonb_build_object('ok', false, 'error', 'Ce défi n’est plus disponible.');
  end if;
  if p_accept and (select count(*) from public.duels where status = 'active' and (challenger = uid or opponent = uid)) >= 3 then
    return jsonb_build_object('ok', false, 'error', 'Tu as déjà 3 défis en cours. Termine-les avant d’en accepter un autre.');
  end if;
  update public.duels
     set status = case when p_accept then 'active' else 'declined' end,
         accepted_at = case when p_accept then now() end,
         finished_at = case when p_accept then null else now() end
   where id = p_id;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.mp_duel_cancel(p_id bigint)
returns jsonb
language plpgsql security definer set search_path = public
as $$
begin
  update public.duels set status = 'cancelled', finished_at = now()
   where id = p_id and challenger = auth.uid() and status = 'pending';
  return jsonb_build_object('ok', found);
end $$;

create or replace function public.mp_duels()
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  res jsonb;
begin
  if uid is null then return '[]'::jsonb; end if;
  perform public.mp_duels_tick();
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', d.id, 'status', d.status, 'days', d.days,
           'me_first', d.challenger = uid,
           'my_days', case when d.challenger = uid then d.c_days else d.o_days end,
           'my_score', case when d.challenger = uid then d.c_score else d.o_score end,
           'their_days', case when d.challenger = uid then d.o_days else d.c_days end,
           'their_score', case when d.challenger = uid then d.o_score else d.c_score end,
           'claimed', case when d.challenger = uid then d.c_claimed else d.o_claimed end,
           'won', d.winner = uid, 'draw', d.status = 'done' and d.winner is null,
           'other', jsonb_build_object('id', o.id, 'pseudo', o.pseudo, 'emoji', o.emoji, 'firm_name', o.firm_name,
                                       'level', o.level, 'cheater', o.cheats > 0),
           'created_at', d.created_at, 'accepted_at', d.accepted_at, 'finished_at', d.finished_at)
         order by case d.status when 'pending' then 0 when 'active' then 1 else 2 end, d.id desc), '[]'::jsonb)
    into res
  from public.duels d
  join public.profiles o on o.id = case when d.challenger = uid then d.opponent else d.challenger end
  where (d.challenger = uid or d.opponent = uid)
    and (d.status in ('pending', 'active') or d.finished_at > now() - interval '7 days');
  return res;
end $$;

-- Récompense d'un duel terminé (une seule fois par joueur)
create or replace function public.mp_duel_claim(p_id bigint)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  d   public.duels;
begin
  select * into d from public.duels where id = p_id and status = 'done' and (challenger = uid or opponent = uid) for update;
  if not found then return jsonb_build_object('ok', false, 'error', 'Ce défi n’est pas terminé.'); end if;
  if (d.challenger = uid and d.c_claimed) or (d.opponent = uid and d.o_claimed) then
    return jsonb_build_object('ok', false, 'error', 'Récompense déjà récupérée.');
  end if;
  update public.duels set c_claimed = c_claimed or challenger = uid, o_claimed = o_claimed or opponent = uid where id = p_id;
  return jsonb_build_object('ok', true, 'won', d.winner = uid, 'draw', d.winner is null);
end $$;

-- 7. Clubs ------------------------------------------------------------------------------
create or replace function public.mp_club_row(c public.clubs)
returns jsonb
language sql stable security definer set search_path = public
as $$
  select jsonb_build_object(
    'id', c.id, 'name', c.name, 'emoji', c.emoji, 'motto', c.motto,
    'members', (select count(*) from public.profiles p where p.club_id = c.id),
    'value', (select coalesce(sum(p.firm_value), 0) from public.profiles p
              where p.club_id = c.id and p.cheats = 0 and not p.hidden and p.updated_at > now() - interval '30 days'));
$$;

create or replace function public.mp_clubs(p_search text default null)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare
  q   text := nullif(btrim(coalesce(p_search, '')), '');
  res jsonb;
begin
  if q is not null then
    q := '%' || replace(replace(replace(left(q, 30), '\', '\\'), '%', '\%'), '_', '\_') || '%';
  end if;
  select coalesce(jsonb_agg(x.j order by (x.j->>'value')::numeric desc, (x.j->>'members')::int desc), '[]'::jsonb) into res
  from (select public.mp_club_row(c) as j from public.clubs c
        where not c.hidden and (q is null or c.name ilike q)) x
  where (x.j->>'members')::int > 0;
  return (select coalesce(jsonb_agg(e || jsonb_build_object('pos', i) order by i), '[]'::jsonb)
          from jsonb_array_elements(res) with ordinality as t(e, i) where i <= 30);
end $$;

create or replace function public.mp_club(p_id bigint)
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  c   public.clubs;
  n   int;
  wk  date := public.mp_week();
begin
  select * into c from public.clubs where id = p_id and (not hidden or exists (select 1 from public.profiles where id = uid and club_id = p_id));
  if not found then return null; end if;
  select count(*) into n from public.profiles where club_id = c.id;
  return public.mp_club_row(c) || jsonb_build_object(
    'owner', c.owner, 'hidden', c.hidden,
    'mine', exists (select 1 from public.profiles where id = uid and club_id = c.id),
    'goal', public.mp_club_goal(n),
    'served', coalesce((select served from public.club_weeks where club_id = c.id and week = wk), 0),
    'sales', coalesce((select sales from public.club_weeks where club_id = c.id and week = wk), 0),
    'claimed', exists (select 1 from public.club_claims where club_id = c.id and week = wk and user_id = uid),
    'rank', (select count(*) + 1 from public.clubs c2
             where not c2.hidden and (public.mp_club_row(c2)->>'value')::numeric > (public.mp_club_row(c)->>'value')::numeric
               and exists (select 1 from public.profiles p where p.club_id = c2.id)),
    'list', (select coalesce(jsonb_agg(jsonb_build_object(
               'id', p.id, 'pseudo', p.pseudo, 'emoji', p.emoji, 'firm_name', p.firm_name, 'level', p.level,
               'firm_value', p.firm_value, 'cheater', p.cheats > 0, 'owner', p.id = c.owner, 'updated_at', p.updated_at)
               order by p.firm_value desc), '[]'::jsonb)
             from public.profiles p where p.club_id = c.id and not p.hidden));
end $$;

create or replace function public.mp_club_create(p_name text, p_emoji text, p_motto text default null)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  me  public.profiles;
  nm  text := regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g');
  mo  text := nullif(regexp_replace(btrim(coalesce(p_motto, '')), '\s+', ' ', 'g'), '');
  em  text := case when p_emoji = any (array['☕','🥐','🍰','🧁','🍩','🍪','🧋','🍵','🫖','🥤','🍫','🌿','🌸','⭐','👑','🐱','🦊','🐻','🚀','🎵'])
                   then p_emoji else '☕' end;
  cid bigint;
begin
  select * into me from public.profiles where id = uid;
  if not found then return jsonb_build_object('ok', false, 'error', 'Rejoins d’abord le multijoueur.'); end if;
  if me.club_id is not null then return jsonb_build_object('ok', false, 'error', 'Quitte d’abord ton club actuel.'); end if;
  if me.level < 3 then return jsonb_build_object('ok', false, 'error', 'Il faut atteindre le niveau 3 pour fonder un club.'); end if;
  if nm !~ '^[A-Za-zÀ-ÖØ-öø-ÿ0-9 &''’._-]{3,30}$' then
    return jsonb_build_object('ok', false, 'error', 'Le nom du club doit faire 3 à 30 caractères : lettres, chiffres, espaces.');
  end if;
  if mo is not null and (char_length(mo) > 80 or mo ~ '[<>{}]') then
    return jsonb_build_object('ok', false, 'error', 'La devise doit faire 80 caractères au plus.');
  end if;
  if not public.mp_is_clean(nm || ' ' || coalesce(mo, '')) then
    return jsonb_build_object('ok', false, 'error', 'Ce nom ou cette devise contient un mot interdit.');
  end if;
  if public.mp_has_contact(nm || ' ' || coalesce(mo, '')) then
    return jsonb_build_object('ok', false, 'error', 'Pas de lien, d’e-mail ni de numéro dans le nom ou la devise.');
  end if;
  if exists (select 1 from public.clubs where lower(name) = lower(nm)) then
    return jsonb_build_object('ok', false, 'error', 'Ce nom de club est déjà pris.');
  end if;
  insert into public.clubs (name, emoji, motto, owner) values (nm, em, mo, uid) returning id into cid;
  update public.profiles set club_id = cid where id = uid;
  return jsonb_build_object('ok', true, 'id', cid);
exception when unique_violation then
  return jsonb_build_object('ok', false, 'error', 'Ce nom de club est déjà pris.');
end $$;

create or replace function public.mp_club_join(p_id bigint)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  me  public.profiles;
begin
  select * into me from public.profiles where id = uid;
  if not found then return jsonb_build_object('ok', false, 'error', 'Rejoins d’abord le multijoueur.'); end if;
  if me.club_id is not null then return jsonb_build_object('ok', false, 'error', 'Quitte d’abord ton club actuel.'); end if;
  if not exists (select 1 from public.clubs where id = p_id and not hidden) then
    return jsonb_build_object('ok', false, 'error', 'Ce club n’existe plus.');
  end if;
  perform 1 from public.clubs where id = p_id for update;
  if (select count(*) from public.profiles where club_id = p_id) >= 20 then
    return jsonb_build_object('ok', false, 'error', 'Ce club est complet (20 membres).');
  end if;
  update public.profiles set club_id = p_id where id = uid;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.mp_club_leave()
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid bigint;
  nxt uuid;
begin
  select club_id into cid from public.profiles where id = uid;
  if cid is null then return jsonb_build_object('ok', true); end if;
  update public.profiles set club_id = null where id = uid;
  if (select owner from public.clubs where id = cid) = uid then
    select id into nxt from public.profiles where club_id = cid order by created_at limit 1;
    if nxt is null then
      delete from public.clubs where id = cid;
    else
      update public.clubs set owner = nxt where id = cid;
    end if;
  end if;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.mp_club_kick(p_member uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid bigint;
begin
  select id into cid from public.clubs where owner = uid;
  if cid is null or p_member = uid then return jsonb_build_object('ok', false, 'error', 'Seule la personne qui a fondé le club peut retirer un membre.'); end if;
  update public.profiles set club_id = null where id = p_member and club_id = cid;
  return jsonb_build_object('ok', found);
end $$;

create or replace function public.mp_club_claim()
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  cid bigint;
  wk  date := public.mp_week();
  n   int;
begin
  select club_id into cid from public.profiles where id = uid;
  if cid is null then return jsonb_build_object('ok', false, 'error', 'Tu n’as pas de club.'); end if;
  select count(*) into n from public.profiles where club_id = cid;
  if coalesce((select served from public.club_weeks where club_id = cid and week = wk), 0) < public.mp_club_goal(n) then
    return jsonb_build_object('ok', false, 'error', 'L’objectif de la semaine n’est pas encore atteint.');
  end if;
  insert into public.club_claims (club_id, week, user_id) values (cid, wk, uid) on conflict do nothing;
  if not found then return jsonb_build_object('ok', false, 'error', 'Tu as déjà récupéré la récompense de cette semaine.'); end if;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.mp_report_club(p_id bigint)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not exists (select 1 from public.profiles where id = uid) then
    return jsonb_build_object('ok', false, 'error', 'Rejoins d’abord le multijoueur pour signaler un club.');
  end if;
  insert into public.club_reports (club_id, reporter) values (p_id, uid) on conflict do nothing;
  if found then
    update public.clubs set reports = reports + 1, hidden = hidden or reports + 1 >= 5 where id = p_id;
  end if;
  return jsonb_build_object('ok', true);
end $$;

-- 8. Messages : salon privé de chaque club (room « club:<id> ») -------------------
alter table public.messages drop constraint if exists messages_room_check;
alter table public.messages add constraint messages_room_check
  check (room = 'terrasse' or room ~ '^cafe:[0-9a-f-]{36}$' or room ~ '^club:[0-9]+$');

create or replace function public.mp_post(p_room text, p_body text)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  me  public.profiles;
  b   text := btrim(regexp_replace(coalesce(p_body, ''), '\s+', ' ', 'g'));
  nid bigint;
begin
  select * into me from public.profiles where id = uid;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Rejoins d’abord le multijoueur.');
  end if;
  if me.banned_until is not null and me.banned_until > now() then
    return jsonb_build_object('ok', false, 'error', 'Tu ne peux plus écrire jusqu’au '
      || to_char(me.banned_until at time zone 'Europe/Paris', 'DD/MM à HH24"h"MI') || '.');
  end if;
  if p_room is null or not (
       p_room = 'terrasse'
    or (p_room ~ '^cafe:[0-9a-f-]{36}$' and exists (select 1 from public.profiles where id::text = substr(p_room, 6) and not hidden))
    or (p_room ~ '^club:[0-9]+$' and me.club_id is not null and me.club_id::text = substr(p_room, 6))) then
    return jsonb_build_object('ok', false, 'error', 'Ce salon est introuvable.');
  end if;
  if char_length(b) = 0 then
    return jsonb_build_object('ok', false, 'error', 'Écris d’abord ton message.');
  end if;
  if char_length(b) > 200 then
    return jsonb_build_object('ok', false, 'error', 'Ton message est trop long : 200 caractères au plus.');
  end if;
  if not public.mp_is_clean(b) then
    return jsonb_build_object('ok', false, 'error', 'Ton message contient un mot interdit. Reste sympa !');
  end if;
  if public.mp_has_contact(b) then
    return jsonb_build_object('ok', false, 'error', 'Pas de lien, d’e-mail, de pseudo de réseau social ni de numéro de téléphone : c’est pour la sécurité de tout le monde.');
  end if;
  if exists (select 1 from public.messages where author = uid and created_at > now() - interval '4 seconds') then
    return jsonb_build_object('ok', false, 'error', 'Doucement ! Attends quelques secondes entre deux messages.');
  end if;
  if (select count(*) from public.messages where author = uid and created_at > now() - interval '10 minutes') >= 15 then
    return jsonb_build_object('ok', false, 'error', 'Tu as écrit beaucoup de messages. Fais une petite pause !');
  end if;
  if exists (select 1 from public.messages where author = uid and body = b and created_at > now() - interval '2 minutes') then
    return jsonb_build_object('ok', false, 'error', 'Tu viens déjà d’envoyer ce message.');
  end if;
  insert into public.messages (room, author, body) values (p_room, uid, b) returning id into nid;
  if random() < 0.01 then delete from public.messages where created_at < now() - interval '60 days'; end if;
  return jsonb_build_object('ok', true, 'id', nid);
end $$;

create or replace function public.mp_messages(p_room text, p_after bigint default 0)
returns jsonb
language sql stable security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'id', m.id, 'author', m.author, 'pseudo', p.pseudo, 'emoji', p.emoji,
           'body', m.body, 'at', m.created_at, 'mine', m.author = auth.uid()) order by m.id), '[]'::jsonb)
  from (select * from public.messages
        where room = p_room and not hidden and id > coalesce(p_after, 0)
          -- Le salon d'un club n'est lisible que par ses membres
          and (p_room !~ '^club:' or exists (select 1 from public.profiles me
                                             where me.id = auth.uid() and me.club_id::text = substr(p_room, 6)))
        order by id desc limit 50) m
  join public.profiles p on p.id = m.author
  where not p.hidden;
$$;

-- 9. Modération : les clubs ---------------------------------------------------------
create or replace function public.admin_mod_overview()
returns jsonb
language plpgsql stable security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Ce compte n''a pas accès à la modération.' using errcode = '42501';
  end if;
  return jsonb_build_object(
    'players', (select count(*) from public.profiles),
    'active_week', (select count(*) from public.profiles where updated_at > now() - interval '7 days'),
    'messages_day', (select count(*) from public.messages where created_at > now() - interval '1 day'),
    'clubs_count', (select count(*) from public.clubs),
    'duels_week', (select count(*) from public.duels where created_at > now() - interval '7 days'),
    'reported', (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'body', m.body, 'room', m.room, 'at', m.created_at,
                   'author', m.author, 'pseudo', p.pseudo, 'reports', m.reports, 'hidden', m.hidden) order by m.reports desc, m.id desc), '[]'::jsonb)
                 from (select * from public.messages where reports > 0 order by reports desc, id desc limit 30) m
                 join public.profiles p on p.id = m.author),
    'recent', (select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'body', m.body, 'room', m.room, 'at', m.created_at,
                 'author', m.author, 'pseudo', p.pseudo, 'reports', m.reports, 'hidden', m.hidden) order by m.id desc), '[]'::jsonb)
               from (select * from public.messages order by id desc limit 40) m
               join public.profiles p on p.id = m.author),
    'profiles', (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'pseudo', pseudo, 'firm_name', firm_name,
                   'reports', reports, 'hidden', hidden, 'banned_until', banned_until) order by reports desc, updated_at desc), '[]'::jsonb)
                 from (select * from public.profiles
                       where reports > 0 or hidden or (banned_until is not null and banned_until > now())
                       order by reports desc, updated_at desc limit 40) x),
    'clubs', (select coalesce(jsonb_agg(jsonb_build_object('id', id, 'name', name, 'motto', motto, 'reports', reports, 'hidden', hidden,
                'members', (select count(*) from public.profiles p where p.club_id = c.id)) order by hidden desc, reports desc, created_at desc), '[]'::jsonb)
              from (select * from public.clubs order by hidden desc, reports desc, created_at desc limit 30) c)
  );
end $$;

create or replace function public.admin_mod_club(p_id bigint, p_hidden boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  update public.clubs set hidden = p_hidden, reports = case when p_hidden then reports else 0 end where id = p_id;
end $$;

-- 10. Droits ------------------------------------------------------------------------------
revoke all on function public.mp_week(), public.mp_club_goal(int), public.mp_duels_tick(),
  public.mp_club_row(public.clubs) from public, anon, authenticated;

revoke all on function public.mp_clubs(text), public.mp_club(bigint) from public;
grant execute on function public.mp_clubs(text), public.mp_club(bigint) to anon, authenticated;

revoke all on function public.mp_report_day(int, bigint, int), public.mp_duel_create(uuid), public.mp_duel_answer(bigint, boolean),
  public.mp_duel_cancel(bigint), public.mp_duels(), public.mp_duel_claim(bigint),
  public.mp_club_create(text, text, text), public.mp_club_join(bigint), public.mp_club_leave(),
  public.mp_club_kick(uuid), public.mp_club_claim(), public.mp_report_club(bigint) from public, anon;
grant execute on function public.mp_report_day(int, bigint, int), public.mp_duel_create(uuid), public.mp_duel_answer(bigint, boolean),
  public.mp_duel_cancel(bigint), public.mp_duels(), public.mp_duel_claim(bigint),
  public.mp_club_create(text, text, text), public.mp_club_join(bigint), public.mp_club_leave(),
  public.mp_club_kick(uuid), public.mp_club_claim(), public.mp_report_club(bigint) to authenticated;

revoke all on function public.admin_mod_club(bigint, boolean) from public, anon;
grant execute on function public.admin_mod_club(bigint, boolean) to authenticated;
