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
