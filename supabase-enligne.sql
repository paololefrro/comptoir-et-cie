-- Comptoir & Cie : joueurs en ligne en ce moment, et qui a relié son adresse e-mail
-- À exécuter une fois dans Supabase → SQL Editor (après supabase-stats.sql et supabase-multi.sql).

-- 1. Présence des comptes du jeu (e-mail ou multijoueur). Une ligne par compte : la dernière présence seulement.
create table if not exists public.presence (
  user_id  uuid primary key references auth.users (id) on delete cascade,
  seen_at  timestamptz not null default now(),
  device   text
);
create index if not exists presence_seen_idx on public.presence (seen_at desc);
alter table public.presence enable row level security;
revoke all on table public.presence from public, anon, authenticated;

-- Le jeu ouvert à l'écran l'appelle toutes les minutes
create or replace function public.cc_ping(p_device text default null)
returns void
language plpgsql volatile security definer set search_path = public
as $$
begin
  if auth.uid() is null then return; end if;
  insert into public.presence (user_id, seen_at, device)
  values (auth.uid(), now(), case when p_device in ('mobile', 'tablette', 'ordinateur') then p_device end)
  on conflict (user_id) do update
    set seen_at = excluded.seen_at, device = coalesce(excluded.device, public.presence.device);
end $$;
revoke all on function public.cc_ping(text) from public, anon;
grant execute on function public.cc_ping(text) to authenticated;

-- 2. Pour la page des statistiques : qui est en ligne, avec ou sans e-mail, et tous les comptes reliés à un e-mail
create or replace function public.admin_online()
returns jsonb
language plpgsql stable security definer set search_path = public, auth
as $$
begin
  if not public.is_admin() then raise exception 'Accès refusé.' using errcode = '42501'; end if;
  return jsonb_build_object(
    'generated_at', now(),
    'online', (select coalesce(jsonb_agg(jsonb_build_object(
          'email', case when coalesce(u.is_anonymous, false) then null else nullif(u.email, '') end,
          'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji, 'level', p.level,
          'day', s.day, 'money', s.money, 'device', x.device, 'seen_at', x.seen_at)
        order by (coalesce(u.is_anonymous, false) or coalesce(u.email, '') = ''), x.seen_at desc), '[]'::jsonb)
      from public.presence x
      join auth.users u on u.id = x.user_id
      left join public.profiles p on p.id = x.user_id
      left join public.saves s on s.user_id = x.user_id
      where x.seen_at > now() - interval '5 minutes'),
    'emails', (select count(*) from auth.users u
      where not coalesce(u.is_anonymous, false) and coalesce(u.email, '') <> ''
        and lower(u.email) not in (select lower(email) from public.admins)),
    'mp_no_email', (select count(*) from public.profiles p join auth.users u on u.id = p.id
      where coalesce(u.is_anonymous, false) or coalesce(u.email, '') = ''),
    'linked', (select coalesce(jsonb_agg(t.r order by t.k desc nulls last), '[]'::jsonb) from (
      select jsonb_build_object('email', u.email, 'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji,
               'level', p.level, 'day', s.day, 'money', s.money, 'created_at', u.created_at,
               'seen_at', greatest(x.seen_at, s.updated_at, p.updated_at, u.last_sign_in_at)) as r,
             greatest(x.seen_at, s.updated_at, p.updated_at, u.last_sign_in_at) as k
      from auth.users u
      left join public.presence x on x.user_id = u.id
      left join public.profiles p on p.id = u.id
      left join public.saves s on s.user_id = u.id
      where not coalesce(u.is_anonymous, false) and coalesce(u.email, '') <> ''
        and lower(u.email) not in (select lower(email) from public.admins)
      order by k desc nulls last limit 300) t)
  );
end $$;
revoke all on function public.admin_online() from public, anon;
grant execute on function public.admin_online() to authenticated;
