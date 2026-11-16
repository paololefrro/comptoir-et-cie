-- =====================================================================
-- Comptoir & Cie · cadeaux offerts par l'équipe depuis stats.html
-- (argent, abonnés, XP ou boost « tout au maximum »).
-- À exécuter après supabase-multi.sql (table gifts) et supabase-stats.sql (is_admin).
-- Relançable sans perte de données.
-- =====================================================================

alter table public.gifts add column if not exists amount bigint;
alter table public.gifts drop constraint if exists gifts_kind_check;
alter table public.gifts add constraint gifts_kind_check check (kind in ('max', 'money', 'followers', 'xp'));

-- Le joueur récupère ses cadeaux en attente (une seule fois chacun)
create or replace function public.claim_gifts()
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  res jsonb;
begin
  if auth.uid() is null then return '[]'::jsonb; end if;
  with c as (
    update public.gifts set claimed_at = now()
    where user_id = auth.uid() and claimed_at is null
    returning kind, note, amount
  )
  select coalesce(jsonb_agg(jsonb_build_object('kind', kind, 'note', note, 'amount', amount)), '[]'::jsonb) into res from c;
  return res;
end $$;

-- Trouver un joueur par son e-mail ou son pseudo du multijoueur
create or replace function public.admin_find_player(p_target text)
returns jsonb
language plpgsql stable security definer set search_path = public, auth
as $$
declare
  t   text := btrim(coalesce(p_target, ''));
  uid uuid;
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  if t = '' then return null; end if;
  if position('@' in t) > 0 then
    select id into uid from auth.users where lower(email) = lower(t) limit 1;
  else
    select id into uid from public.profiles where lower(pseudo) = lower(t) limit 1;
  end if;
  if uid is null then return null; end if;
  return (
    select jsonb_build_object(
      'id', u.id, 'email', u.email, 'anonymous', coalesce(u.is_anonymous, false),
      'created_at', u.created_at, 'last_sign_in_at', u.last_sign_in_at,
      'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji, 'level', p.level,
      'firm_value', p.firm_value, 'updated_at', p.updated_at, 'cheater', coalesce(p.cheats, 0) > 0,
      'has_save', exists (select 1 from public.saves s where s.user_id = u.id),
      'pending', (select count(*) from public.gifts g where g.user_id = u.id and g.claimed_at is null))
    from auth.users u
    left join public.profiles p on p.id = u.id
    where u.id = uid);
end $$;

-- Offrir un cadeau à un joueur (montants plafonnés)
create or replace function public.admin_gift(p_user uuid, p_kind text, p_amount bigint default null, p_note text default null)
returns jsonb
language plpgsql security definer set search_path = public, auth
as $$
declare
  amt bigint;
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  if p_kind not in ('max', 'money', 'followers', 'xp') then
    return jsonb_build_object('ok', false, 'error', 'Type de cadeau inconnu.');
  end if;
  if not exists (select 1 from auth.users where id = p_user) then
    return jsonb_build_object('ok', false, 'error', 'Ce joueur n’existe plus.');
  end if;
  amt := case p_kind
           when 'money'     then least(greatest(coalesce(p_amount, 0), 1), 100000000)
           when 'followers' then least(greatest(coalesce(p_amount, 0), 1), 10000000)
           when 'xp'        then least(greatest(coalesce(p_amount, 0), 1), 1000000)
         end;
  insert into public.gifts (user_id, kind, amount, note)
  values (p_user, p_kind, amt, left(nullif(btrim(coalesce(p_note, '')), ''), 120));
  return jsonb_build_object('ok', true, 'amount', amt);
end $$;

-- Les 20 derniers cadeaux envoyés
create or replace function public.admin_gifts_recent()
returns jsonb
language plpgsql stable security definer set search_path = public, auth
as $$
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  return (
    select coalesce(jsonb_agg(jsonb_build_object(
             'id', g.id, 'kind', g.kind, 'amount', g.amount, 'note', g.note,
             'created_at', g.created_at, 'claimed_at', g.claimed_at,
             'email', u.email, 'pseudo', p.pseudo) order by g.id desc), '[]'::jsonb)
    from (select * from public.gifts order by id desc limit 20) g
    left join auth.users u on u.id = g.user_id
    left join public.profiles p on p.id = g.user_id);
end $$;

revoke all on function public.claim_gifts() from public, anon;
grant execute on function public.claim_gifts() to authenticated;
revoke all on function public.admin_find_player(text), public.admin_gift(uuid, text, bigint, text), public.admin_gifts_recent() from public, anon;
grant execute on function public.admin_find_player(text), public.admin_gift(uuid, text, bigint, text), public.admin_gifts_recent() to authenticated;

-- 2. Plus de choix et envoi groupé ------------------------------------------
alter table public.gifts drop constraint if exists gifts_kind_check;
alter table public.gifts add constraint gifts_kind_check
  check (kind in ('max', 'money', 'followers', 'xp', 'levels', 'rep', 'stock', 'menu', 'shares'));

-- Plafond par type de cadeau (null pour les cadeaux sans quantité)
create or replace function public.gift_amount(p_kind text, p_amount bigint)
returns bigint language sql immutable
as $$
  select case p_kind
    when 'money'     then least(greatest(coalesce(p_amount, 0), 1), 100000000)
    when 'followers' then least(greatest(coalesce(p_amount, 0), 1), 10000000)
    when 'xp'        then least(greatest(coalesce(p_amount, 0), 1), 1000000)
    when 'levels'    then least(greatest(coalesce(p_amount, 0), 1), 11)
    when 'shares'    then least(greatest(coalesce(p_amount, 0), 1), 100)
  end;
$$;

-- Plusieurs cadeaux en un envoi : p_items = [{"kind":"money","amount":10000}, {"kind":"rep"}, …]
create or replace function public.admin_gift_many(p_user uuid, p_items jsonb, p_note text default null)
returns jsonb
language plpgsql security definer set search_path = public, auth
as $$
declare
  it jsonb;
  k  text;
  n  int := 0;
  nt text := left(nullif(btrim(coalesce(p_note, '')), ''), 120);
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  if not exists (select 1 from auth.users where id = p_user) then
    return jsonb_build_object('ok', false, 'error', 'Ce joueur n’existe plus.');
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    return jsonb_build_object('ok', false, 'error', 'Choisis au moins un cadeau.');
  end if;
  for it in select * from jsonb_array_elements(p_items) loop
    k := it->>'kind';
    if k not in ('max', 'money', 'followers', 'xp', 'levels', 'rep', 'stock', 'menu', 'shares') then
      return jsonb_build_object('ok', false, 'error', 'Type de cadeau inconnu : ' || coalesce(k, '?'));
    end if;
  end loop;
  for it in select * from jsonb_array_elements(p_items) loop
    k := it->>'kind';
    insert into public.gifts (user_id, kind, amount, note)
    values (p_user, k, public.gift_amount(k, nullif(it->>'amount', '')::bigint), nt);
    nt := null; -- le message n'accompagne que le premier cadeau
    n := n + 1;
  end loop;
  return jsonb_build_object('ok', true, 'count', n);
end $$;

revoke all on function public.gift_amount(text, bigint) from public, anon, authenticated;
revoke all on function public.admin_gift_many(uuid, jsonb, text) from public, anon;
grant execute on function public.admin_gift_many(uuid, jsonb, text) to authenticated;

-- 3. Comptes exemptés du « hors classement » ----------------------------------
--    Une vitrine exemptée reste classée même si la partie a utilisé des codes secrets.
--    Réservé au compte de l'équipe : update public.profiles set exempt = true where …
alter table public.profiles add column if not exists exempt boolean not null default false;

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
    -- Compte exempté : jamais hors classement ; nouvelle partie (moins de jours) : repart sans marque de triche
    cheats = case when p.exempt then 0
                  when excluded.days < p.days then excluded.cheats
                  else greatest(p.cheats, excluded.cheats) end,
    updated_at = now();
  return jsonb_build_object('ok', true, 'me', public.mp_me());
exception when unique_violation then
  return jsonb_build_object('ok', false, 'error', 'Ce pseudo est déjà pris. Essaie une variante.');
end $$;

-- 4. Niveaux jusqu'au 50 : jusqu'à 49 niveaux offerts d'un coup -------------------------
create or replace function public.gift_amount(p_kind text, p_amount bigint)
returns bigint language sql immutable
as $$
  select case p_kind
    when 'money'     then least(greatest(coalesce(p_amount, 0), 1), 100000000)
    when 'followers' then least(greatest(coalesce(p_amount, 0), 1), 10000000)
    when 'xp'        then least(greatest(coalesce(p_amount, 0), 1), 1000000)
    when 'levels'    then least(greatest(coalesce(p_amount, 0), 1), 49)
  end;
$$;
revoke all on function public.gift_amount(text, bigint) from public, anon, authenticated;
