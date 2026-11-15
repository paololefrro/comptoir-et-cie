-- =====================================================================
-- Comptoir & Cie · multijoueur : vitrines, classement, visites,
-- pourboires et terrasse (chat modéré).
-- À exécuter dans Supabase → SQL Editor, après supabase-stats.sql
-- (il utilise la fonction is_admin). Relançable sans perte de données.
-- Prérequis : Authentication → Sign In / Providers → « Allow anonymous sign-ins ».
-- =====================================================================

-- 1. Vitrines publiques des joueurs ------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  pseudo       text not null check (char_length(pseudo) between 3 and 20),
  firm_name    text not null check (char_length(firm_name) between 2 and 40),
  emoji        text not null default '☕' check (char_length(emoji) <= 8),
  level        int    not null default 1,
  firm_value   bigint not null default 0,
  cafes        int    not null default 1,
  franchises   int    not null default 0,
  rep          numeric(3,2) not null default 3,
  followers    int    not null default 0,
  days         int    not null default 0,
  served       bigint not null default 0,
  best_day     int    not null default 0,
  items        int    not null default 0,
  snapshot     jsonb  not null default '{}'::jsonb,
  cheats       int    not null default 0,
  tips_total   int    not null default 0,
  tips_pending int    not null default 0,
  reports      int    not null default 0,
  hidden       boolean not null default false,
  banned_until timestamptz,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create unique index if not exists profiles_pseudo_idx on public.profiles (lower(pseudo));
create index if not exists profiles_value_idx on public.profiles (firm_value desc);
create index if not exists profiles_updated_idx on public.profiles (updated_at desc);
alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;

-- 2. Pourboires (un par café et par jour) --------------------------------
create table if not exists public.tips (
  giver    uuid not null references public.profiles (id) on delete cascade,
  receiver uuid not null references public.profiles (id) on delete cascade,
  day      date not null,
  created_at timestamptz not null default now(),
  primary key (giver, receiver, day)
);
alter table public.tips enable row level security;
revoke all on public.tips from anon, authenticated;

-- 3. Messages : la terrasse (salon commun) et les livres d'or des cafés --
create table if not exists public.messages (
  id         bigint generated always as identity primary key,
  room       text not null check (room = 'terrasse' or room ~ '^cafe:[0-9a-f-]{36}$'),
  author     uuid not null references public.profiles (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 200),
  created_at timestamptz not null default now(),
  reports    int not null default 0,
  hidden     boolean not null default false
);
create index if not exists messages_room_idx on public.messages (room, id desc);
create index if not exists messages_author_idx on public.messages (author, created_at desc);
alter table public.messages enable row level security;
revoke all on public.messages from anon, authenticated;

create table if not exists public.reports (
  message_id bigint not null references public.messages (id) on delete cascade,
  reporter   uuid   not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (message_id, reporter)
);
create table if not exists public.profile_reports (
  target   uuid not null references public.profiles (id) on delete cascade,
  reporter uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (target, reporter)
);
alter table public.reports enable row level security;
alter table public.profile_reports enable row level security;
revoke all on public.reports, public.profile_reports from anon, authenticated;

-- 4. Filtre des mots interdits -------------------------------------------
--    collapse = true : les lettres répétées comptent pour une (« connnnard »)
--    glued    = true : repéré même collé ou espacé (« s a l o p e »)
create table if not exists public.banned_words (
  word     text primary key,
  glued    boolean not null default false,
  collapse boolean not null default true
);
alter table public.banned_words enable row level security;
revoke all on public.banned_words from anon, authenticated;

insert into public.banned_words (word, glued, collapse) values
  ('connard', true, true), ('connards', false, true), ('connasse', true, true), ('connasses', false, true),
  ('conne', false, false), ('connes', false, false),
  ('salope', false, true), ('salopes', false, true), ('salaud', false, true), ('salauds', false, true),
  ('pute', false, true), ('putes', false, true), ('putain', true, true),
  ('pd', false, true), ('pds', false, true), ('pede', false, true), ('pedes', false, true), ('pedale', false, true),
  ('tapette', false, true), ('tapettes', false, true), ('gouine', false, true), ('gouines', false, true),
  ('encule', true, true), ('encules', false, true), ('enculee', false, true), ('enculer', true, true), ('enculeur', false, true),
  ('enfoire', true, true), ('enfoires', false, true), ('enfoiree', false, true),
  ('batard', false, true), ('batards', false, true), ('batarde', false, true),
  ('merde', false, true), ('merdes', false, true), ('chier', false, true), ('chieur', false, true),
  ('couille', false, true), ('couilles', false, true), ('couillon', false, true),
  ('bite', false, true), ('bites', false, true), ('teub', false, true), ('zob', false, true),
  ('nique', false, true), ('niquer', false, true), ('niquez', false, true), ('ntm', false, true),
  ('nique ta mere', true, true), ('fdp', false, true), ('fils de pute', true, true),
  ('tg', false, true), ('ftg', false, true), ('ta gueule', true, true), ('va te faire foutre', true, true),
  ('foutre', false, true), ('branleur', false, true), ('branleurs', false, true), ('branler', false, true), ('branlette', false, true),
  ('suce', false, true), ('suceur', false, true), ('catin', false, true), ('garce', false, true),
  ('poufiasse', true, true), ('pouffiasse', true, true), ('petasse', false, true), ('grognasse', false, true),
  ('nazi', false, true), ('nazis', false, true), ('hitler', false, true), ('heil', false, true),
  ('negre', false, true), ('negres', false, true), ('negro', false, true), ('negros', false, true),
  ('bougnoul', true, true), ('bougnoule', false, true), ('bougnoules', false, true), ('bicot', false, true), ('bicots', false, true),
  ('youpin', true, true), ('youpins', false, true), ('youpine', false, true), ('chinetoque', false, true), ('chintok', false, true),
  ('sale arabe', false, true), ('sale juif', false, true), ('sale race', false, true), ('sale negre', false, true),
  ('porno', false, true), ('viol', false, true), ('violer', false, true), ('violeur', false, true),
  ('nichon', false, true), ('nichons', false, true),
  ('fuck', true, true), ('fucking', false, true), ('fucker', false, true), ('motherfucker', true, true),
  ('shit', false, true), ('bitch', false, true), ('bitches', false, true), ('asshole', false, true),
  ('dick', false, true), ('cock', false, true), ('pussy', false, true), ('cunt', false, true),
  ('nigger', true, false), ('niggers', false, false), ('nigga', true, false), ('niggas', false, false),
  ('faggot', true, true), ('fag', false, true), ('whore', false, true), ('slut', false, true)
on conflict (word) do nothing;

-- Minuscules sans accents, chiffres « leet » remplacés (0→o, 1→i…), mots séparés par une espace
create or replace function public.mp_norm(t text)
returns text
language sql immutable
as $$
  select btrim(regexp_replace(
    translate(lower(coalesce(t, '')),
      'àâäáãåçéèêëíìîïñóòôöõúùûüýÿœæÀÂÄÁÃÅÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜÝŒÆ0134578@$€',
      'aaaaaaceeeeiiiinooooouuuuyyoaaaaaaaceeeeiiiinooooouuuuyoaoieastbase'),
    '[^a-z]+', ' ', 'g'));
$$;

create or replace function public.mp_is_clean(t text)
returns boolean
language plpgsql stable security definer set search_path = public
as $$
declare
  n  text := public.mp_norm(t);
  c1 text := ' ' || regexp_replace(n, '(.)\1+', '\1', 'g') || ' ';
  c2 text := ' ' || regexp_replace(n, '(.)\1{2,}', '\1\1', 'g') || ' ';
  g1 text := replace(c1, ' ', '');
  g2 text := replace(c2, ' ', '');
  w record;
  k text;
begin
  for w in select word, glued, collapse from public.banned_words loop
    if w.collapse then
      k := regexp_replace(w.word, '(.)\1+', '\1', 'g');
      if position(' ' || k || ' ' in c1) > 0 or (w.glued and position(replace(k, ' ', '') in g1) > 0) then
        return false;
      end if;
    else
      if position(' ' || w.word || ' ' in c2) > 0 or (w.glued and position(replace(w.word, ' ', '') in g2) > 0) then
        return false;
      end if;
    end if;
  end loop;
  return true;
end $$;

-- Liens, adresses e-mail, pseudos de réseaux sociaux et numéros de téléphone
create or replace function public.mp_has_contact(t text)
returns boolean
language sql immutable
as $$
  select coalesce(t, '') ~* '(https?:|www\.|discord\.gg|[a-z0-9-]{2,}\.(com|fr|net|org|io|gg|ly|be|me|tv|xyz|co|info|app|link|site|shop)([^a-z]|$)|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}|(^|[^a-z0-9])@[a-z0-9_.]{3,}|(\+|00)\s?[0-9]{2}([ .-]?[0-9]){8,}|(^|[^0-9])0[1-9]([ .-]?[0-9]{2}){4}([^0-9]|$))';
$$;
revoke all on function public.mp_norm(text), public.mp_is_clean(text), public.mp_has_contact(text) from public, anon, authenticated;

-- 5. Mon profil -----------------------------------------------------------
create or replace function public.mp_me()
returns jsonb
language sql stable security definer set search_path = public
as $$
  select case when p.id is null then null else jsonb_build_object(
    'id', p.id, 'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji,
    'level', p.level, 'firm_value', p.firm_value,
    'tips_pending', p.tips_pending, 'tips_total', p.tips_total,
    'cheater', p.cheats > 0, 'hidden', p.hidden, 'banned_until', p.banned_until,
    'rank', case when p.cheats = 0 and not p.hidden then (
      select count(*) + 1 from public.profiles q
      where q.cheats = 0 and not q.hidden and q.updated_at > now() - interval '30 days' and q.firm_value > p.firm_value) end,
    'players', (select count(*) from public.profiles q
      where q.cheats = 0 and not q.hidden and q.updated_at > now() - interval '30 days')
  ) end
  from (select auth.uid() as uid) u
  left join public.profiles p on p.id = u.uid;
$$;

-- 6. Publier ou mettre à jour sa vitrine ----------------------------------
create or replace function public.mp_publish(
  p_pseudo text, p_firm_name text, p_emoji text default '☕',
  p_level int default 1, p_firm_value bigint default 0, p_cafes int default 1, p_franchises int default 0,
  p_rep numeric default 3, p_followers int default 0, p_days int default 0, p_served bigint default 0,
  p_best_day int default 0, p_items int default 0, p_snapshot jsonb default '{}'::jsonb, p_cheats int default 0)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid  uuid := auth.uid();
  ps   text := regexp_replace(btrim(coalesce(p_pseudo, '')), '\s+', ' ', 'g');
  fn   text := regexp_replace(btrim(coalesce(p_firm_name, '')), '\s+', ' ', 'g');
  em   text := case when p_emoji = any (array['☕','🥐','🍰','🧁','🍩','🍪','🧋','🍵','🫖','🥤','🍫','🌿','🌸','⭐','👑','🐱','🦊','🐻','🚀','🎵'])
                    then p_emoji else '☕' end;
  snap jsonb := case when jsonb_typeof(p_snapshot) = 'object' and pg_column_size(p_snapshot) < 6000
                     then p_snapshot else '{}'::jsonb end;
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'Connexion au multijoueur impossible. Recharge la page.');
  end if;
  if ps !~ '^[A-Za-zÀ-ÖØ-öø-ÿ0-9 _.-]{3,20}$' then
    return jsonb_build_object('ok', false, 'error', 'Ton pseudo doit faire 3 à 20 caractères : lettres, chiffres, espace, point ou tiret.');
  end if;
  if char_length(fn) not between 2 and 40 or fn ~ '[<>{}]' then
    return jsonb_build_object('ok', false, 'error', 'Le nom de ton enseigne doit faire 2 à 40 caractères.');
  end if;
  if not public.mp_is_clean(ps || ' ' || fn) then
    return jsonb_build_object('ok', false, 'error', 'Ce nom contient un mot interdit. Choisis-en un autre.');
  end if;
  if public.mp_has_contact(ps || ' ' || fn) then
    return jsonb_build_object('ok', false, 'error', 'Pas de lien, d’adresse e-mail ni de numéro dans les noms.');
  end if;
  if exists (select 1 from public.profiles where lower(pseudo) = lower(ps) and id <> uid) then
    return jsonb_build_object('ok', false, 'error', 'Ce pseudo est déjà pris. Essaie une variante.');
  end if;

  insert into public.profiles as p (id, pseudo, firm_name, emoji, level, firm_value, cafes, franchises, rep,
                                    followers, days, served, best_day, items, snapshot, cheats)
  values (uid, ps, fn, em,
          least(greatest(coalesce(p_level, 1), 1), 100),
          least(greatest(coalesce(p_firm_value, 0), 0), 1000000000000000),
          least(greatest(coalesce(p_cafes, 1), 1), 10000),
          least(greatest(coalesce(p_franchises, 0), 0), 1000000),
          least(greatest(coalesce(p_rep, 3), 0), 5),
          least(greatest(coalesce(p_followers, 0), 0), 2000000000),
          least(greatest(coalesce(p_days, 0), 0), 10000000),
          least(greatest(coalesce(p_served, 0), 0), 1000000000000),
          least(greatest(coalesce(p_best_day, 0), 0), 2000000000),
          least(greatest(coalesce(p_items, 0), 0), 1000),
          snap,
          least(greatest(coalesce(p_cheats, 0), 0), 1000000))
  on conflict (id) do update set
    pseudo = excluded.pseudo, firm_name = excluded.firm_name, emoji = excluded.emoji,
    level = excluded.level, firm_value = excluded.firm_value, cafes = excluded.cafes,
    franchises = excluded.franchises, rep = excluded.rep, followers = excluded.followers,
    days = excluded.days, served = excluded.served, best_day = excluded.best_day,
    items = excluded.items, snapshot = excluded.snapshot,
    -- Une nouvelle partie (moins de jours qu'avant) repart sans marque de triche
    cheats = case when excluded.days < p.days then excluded.cheats else greatest(p.cheats, excluded.cheats) end,
    updated_at = now();
  return jsonb_build_object('ok', true, 'me', public.mp_me());
exception when unique_violation then
  return jsonb_build_object('ok', false, 'error', 'Ce pseudo est déjà pris. Essaie une variante.');
end $$;

-- 7. Classement (parties sans codes de triche, actives depuis 30 jours) ----
create or replace function public.mp_leaderboard(p_kind text default 'value')
returns jsonb
language sql stable security definer set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(r) order by r.pos), '[]'::jsonb)
  from (
    select row_number() over (order by s.score desc, s.firm_value desc, s.created_at) as pos,
           s.id, s.pseudo, s.firm_name, s.emoji, s.level, s.firm_value, s.cafes, s.franchises,
           s.rep, s.followers, s.tips_total
    from (
      select p.*, case p_kind when 'followers' then p.followers::numeric
                              when 'tips' then p.tips_total::numeric
                              else p.firm_value::numeric end as score
      from public.profiles p
      where not p.hidden and p.cheats = 0 and p.updated_at > now() - interval '30 days'
    ) s
    order by s.score desc, s.firm_value desc, s.created_at
    limit 50
  ) r;
$$;

-- 8. Annuaire des cafés (récents, au hasard ou recherche) ----------------
create or replace function public.mp_directory(p_mode text default 'recent', p_search text default null)
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
  select coalesce(jsonb_agg(to_jsonb(r) - 'k' order by r.k desc), '[]'::jsonb) into res
  from (
    select p.id, p.pseudo, p.firm_name, p.emoji, p.level, p.firm_value, p.cafes, p.franchises,
           p.rep, p.followers, p.tips_total, p.cheats > 0 as cheater, p.updated_at,
           case when p_mode = 'random' then random() else extract(epoch from p.updated_at) end as k
    from public.profiles p
    where not p.hidden and (q is null or p.pseudo ilike q or p.firm_name ilike q)
    order by k desc
    limit 30
  ) r;
  return res;
end $$;

-- 9. Visiter un café --------------------------------------------------------
create or replace function public.mp_profile(p_id uuid)
returns jsonb
language sql stable security definer set search_path = public
as $$
  select jsonb_build_object(
    'id', p.id, 'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji,
    'level', p.level, 'firm_value', p.firm_value, 'cafes', p.cafes, 'franchises', p.franchises,
    'rep', p.rep, 'followers', p.followers, 'days', p.days, 'served', p.served,
    'best_day', p.best_day, 'items', p.items, 'snapshot', p.snapshot,
    'tips_total', p.tips_total, 'cheater', p.cheats > 0,
    'created_at', p.created_at, 'updated_at', p.updated_at,
    'rank', case when p.cheats = 0 then (
      select count(*) + 1 from public.profiles q
      where q.cheats = 0 and not q.hidden and q.updated_at > now() - interval '30 days' and q.firm_value > p.firm_value) end,
    'tipped', exists (select 1 from public.tips t
                      where t.giver = auth.uid() and t.receiver = p.id
                        and t.day = (now() at time zone 'Europe/Paris')::date),
    'mine', p.id = auth.uid())
  from public.profiles p
  where p.id = p_id and (not p.hidden or p.id = auth.uid());
$$;

-- 10. Pourboires ------------------------------------------------------------
create or replace function public.mp_tip(p_target uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid   uuid := auth.uid();
  today date := (now() at time zone 'Europe/Paris')::date;
  n     int;
begin
  if uid is null or not exists (select 1 from public.profiles where id = uid) then
    return jsonb_build_object('ok', false, 'error', 'Rejoins d’abord le multijoueur.');
  end if;
  if p_target = uid then
    return jsonb_build_object('ok', false, 'error', 'Pas de pourboire à toi-même !');
  end if;
  if not exists (select 1 from public.profiles where id = p_target and not hidden) then
    return jsonb_build_object('ok', false, 'error', 'Ce café est introuvable.');
  end if;
  select count(*) into n from public.tips where giver = uid and day = today;
  if n >= 10 then
    return jsonb_build_object('ok', false, 'error', 'Tu as déjà laissé 10 pourboires aujourd’hui. Reviens demain !');
  end if;
  insert into public.tips (giver, receiver, day) values (uid, p_target, today) on conflict do nothing;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Tu as déjà laissé un pourboire à ce café aujourd’hui.');
  end if;
  update public.profiles set tips_total = tips_total + 1, tips_pending = least(tips_pending + 1, 50) where id = p_target;
  if random() < 0.02 then delete from public.tips where day < today - 7; end if;
  return jsonb_build_object('ok', true, 'left', 9 - n);
end $$;

create or replace function public.mp_claim_tips()
returns int
language plpgsql security definer set search_path = public
as $$
declare
  n int;
begin
  select tips_pending into n from public.profiles where id = auth.uid() for update;
  update public.profiles set tips_pending = 0 where id = auth.uid();
  return coalesce(n, 0);
end $$;

-- 11. Messages ---------------------------------------------------------------
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
  if p_room is null or not (p_room = 'terrasse' or (p_room ~ '^cafe:[0-9a-f-]{36}$'
      and exists (select 1 from public.profiles where id::text = substr(p_room, 6) and not hidden))) then
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
        order by id desc limit 50) m
  join public.profiles p on p.id = m.author
  where not p.hidden;
$$;

create or replace function public.mp_report(p_message bigint)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  a   uuid;
begin
  if uid is null or not exists (select 1 from public.profiles where id = uid) then
    return jsonb_build_object('ok', false, 'error', 'Rejoins d’abord le multijoueur pour signaler un message.');
  end if;
  select author into a from public.messages where id = p_message;
  if a is null then return jsonb_build_object('ok', false, 'error', 'Ce message n’existe plus.'); end if;
  if a = uid then return jsonb_build_object('ok', false, 'error', 'Tu ne peux pas signaler ton propre message.'); end if;
  insert into public.reports (message_id, reporter) values (p_message, uid) on conflict do nothing;
  if found then
    -- Masqué automatiquement au 3e signalement, en attendant la modération
    update public.messages set reports = reports + 1, hidden = hidden or reports + 1 >= 3 where id = p_message;
  end if;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.mp_report_profile(p_target uuid)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null or not exists (select 1 from public.profiles where id = uid) then
    return jsonb_build_object('ok', false, 'error', 'Rejoins d’abord le multijoueur pour signaler un café.');
  end if;
  if p_target = uid then return jsonb_build_object('ok', false, 'error', 'Tu ne peux pas signaler ton propre café.'); end if;
  insert into public.profile_reports (target, reporter) values (p_target, uid) on conflict do nothing;
  if found then
    -- Masqué automatiquement au 5e signalement, en attendant la modération
    update public.profiles set reports = reports + 1, hidden = hidden or reports + 1 >= 5 where id = p_target;
  end if;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.mp_leave()
returns jsonb
language plpgsql security definer set search_path = public
as $$
begin
  delete from public.profiles where id = auth.uid();
  return jsonb_build_object('ok', true);
end $$;

-- 12. Modération (réservée aux adresses de la table admins) ----------------
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
                       order by reports desc, updated_at desc limit 40) x)
  );
end $$;

create or replace function public.admin_mod_message(p_id bigint, p_hidden boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  update public.messages set hidden = p_hidden, reports = case when p_hidden then reports else 0 end where id = p_id;
end $$;

create or replace function public.admin_mod_ban(p_user uuid, p_days int)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  update public.profiles
     set banned_until = case when coalesce(p_days, 0) > 0 then now() + make_interval(days => p_days) end
   where id = p_user;
  if coalesce(p_days, 0) > 0 then
    update public.messages set hidden = true where author = p_user and created_at > now() - interval '1 day';
  end if;
end $$;

create or replace function public.admin_mod_profile(p_user uuid, p_hidden boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  update public.profiles set hidden = p_hidden, reports = case when p_hidden then reports else 0 end where id = p_user;
end $$;

-- 13. Droits : lecture pour tous, écriture pour les joueurs connectés -----
revoke all on function public.mp_me(), public.mp_leaderboard(text), public.mp_directory(text, text),
  public.mp_profile(uuid), public.mp_messages(text, bigint) from public;
grant execute on function public.mp_me(), public.mp_leaderboard(text), public.mp_directory(text, text),
  public.mp_profile(uuid), public.mp_messages(text, bigint) to anon, authenticated;

revoke all on function public.mp_publish(text, text, text, int, bigint, int, int, numeric, int, int, bigint, int, int, jsonb, int),
  public.mp_tip(uuid), public.mp_claim_tips(), public.mp_post(text, text), public.mp_report(bigint),
  public.mp_report_profile(uuid), public.mp_leave() from public, anon;
grant execute on function public.mp_publish(text, text, text, int, bigint, int, int, numeric, int, int, bigint, int, int, jsonb, int),
  public.mp_tip(uuid), public.mp_claim_tips(), public.mp_post(text, text), public.mp_report(bigint),
  public.mp_report_profile(uuid), public.mp_leave() to authenticated;

revoke all on function public.admin_mod_overview(), public.admin_mod_message(bigint, boolean),
  public.admin_mod_ban(uuid, int), public.admin_mod_profile(uuid, boolean) from public, anon;
grant execute on function public.admin_mod_overview(), public.admin_mod_message(bigint, boolean),
  public.admin_mod_ban(uuid, int), public.admin_mod_profile(uuid, boolean) to authenticated;
