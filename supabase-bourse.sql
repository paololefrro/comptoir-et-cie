-- =====================================================================
-- Comptoir & Cie · Bourse entre joueurs
-- Un joueur coté propose des actions de son café ; les autres joueurs les
-- achètent au cours qu'il a publié. L'argent va à la société qui vend (versé
-- à sa prochaine connexion ou fin de journée) et les dividendes vont aux
-- joueurs actionnaires.
-- À exécuter après supabase-multi.sql, supabase-multi2.sql et supabase-cadeaux.sql.
-- Relançable sans perte de données.
-- =====================================================================

-- 1. Tables (aucun accès direct : tout passe par les fonctions mp_stock_*) ------
create table if not exists public.stock_listings (
  company     uuid primary key references public.profiles (id) on delete cascade,
  price       numeric(16,2) not null check (price > 0),
  prev_price  numeric(16,2),
  div_rate    numeric(4,3)  not null default 0 check (div_rate between 0 and 0.5),
  shares      bigint not null default 100000,
  offer       bigint not null default 0 check (offer >= 0),
  sold        bigint not null default 0,
  hist        jsonb  not null default '[]'::jsonb,
  last_div_at timestamptz,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.stock_holdings (
  holder     uuid not null references public.profiles (id) on delete cascade,
  company    uuid not null references public.stock_listings (company) on delete cascade,
  qty        bigint not null check (qty > 0),
  cost       numeric(18,2) not null default 0,
  updated_at timestamptz not null default now(),
  primary key (holder, company)
);
create index if not exists stock_holdings_company on public.stock_holdings (company);

-- Sommes et mouvements en attente, récupérés par le jeu avec mp_stock_claim
--   sale   : actions de la société achetées par un joueur (argent pour la société)
--   back   : un joueur a revendu ses actions au marché (la société les compte chez les investisseurs)
--   div    : dividende reçu d'un café dont on a des actions
--   refund : remboursement au dernier cours quand un café quitte le multijoueur
create table if not exists public.stock_payouts (
  id         bigserial primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  kind       text not null check (kind in ('sale', 'back', 'div', 'refund')),
  amount     numeric(18,2) not null default 0,
  qty        bigint not null default 0,
  other      uuid,
  created_at timestamptz not null default now()
);
create index if not exists stock_payouts_user on public.stock_payouts (user_id);

alter table public.stock_listings enable row level security;
alter table public.stock_holdings enable row level security;
alter table public.stock_payouts  enable row level security;
revoke all on public.stock_listings, public.stock_holdings, public.stock_payouts from anon, authenticated;
revoke all on sequence public.stock_payouts_id_seq from anon, authenticated;

-- 2. Un café qui quitte le multijoueur rembourse ses actionnaires au dernier cours
create or replace function public.stock_refund_holders()
returns trigger
language plpgsql security definer set search_path = public, auth
as $$
begin
  insert into public.stock_payouts (user_id, kind, amount, qty, other)
  select h.holder, 'refund', round(h.qty * old.price, 2), h.qty, old.company
  from public.stock_holdings h
  where h.company = old.company and h.holder <> old.company
    and exists (select 1 from auth.users u where u.id = h.holder);
  return old;
end $$;

drop trigger if exists stock_listings_refund on public.stock_listings;
create trigger stock_listings_refund before delete on public.stock_listings
for each row execute function public.stock_refund_holders();

-- 3. Le compte peut-il échanger des actions ? (null = oui, sinon le message d'erreur)
create or replace function public.stock_ok(p_user uuid)
returns text
language sql stable security definer set search_path = public
as $$
  select case
    when p.id is null then 'Rejoins d’abord le multijoueur (onglet En ligne).'
    when p.banned_until is not null and p.banned_until > now() then 'Ton compte est suspendu pour le moment.'
    when p.cheats > 0 and not p.exempt then 'Les parties qui ont utilisé des codes secrets ne peuvent pas échanger d’actions avec les joueurs.'
  end
  from (select p_user as uid) u
  left join public.profiles p on p.id = u.uid;
$$;

-- 4. Publier son cours, son dividende et ajouter ou retirer des actions en vente
create or replace function public.mp_stock_update(p_price numeric, p_div numeric, p_shares bigint,
                                                  p_hist jsonb default '[]'::jsonb, p_offer_delta bigint default 0)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  err text := public.stock_ok(auth.uid());
  l   public.stock_listings;
  fv  bigint;
  pr  numeric;
  sh  bigint := least(greatest(coalesce(p_shares, 100000), 100000), 1000000000);
  dv  numeric := least(greatest(coalesce(p_div, 0), 0), 0.5);
  h   jsonb := case when jsonb_typeof(p_hist) = 'array' and pg_column_size(p_hist) < 2000 then p_hist else '[]'::jsonb end;
begin
  if err is not null then return jsonb_build_object('ok', false, 'error', err); end if;
  if p_price is null or p_price <= 0 then
    return jsonb_build_object('ok', false, 'error', 'Cours invalide.');
  end if;
  select firm_value into fv from public.profiles where id = uid;
  -- Garde-fou : le cours ne dépasse pas 5 fois la valeur de la vitrine répartie sur les actions
  pr := greatest(round(least(p_price, greatest(coalesce(fv, 0), 100000) * 5.0 / sh), 2), 0.01);
  select * into l from public.stock_listings where company = uid for update;
  if not found then
    insert into public.stock_listings (company, price, prev_price, div_rate, shares, offer, hist)
    values (uid, pr, case when jsonb_typeof(h -> -2) = 'number' then (h ->> -2)::numeric end,
            dv, sh, least(greatest(coalesce(p_offer_delta, 0), 0), 1000000000), h)
    returning * into l;
  else
    -- Et il ne peut pas être divisé ou multiplié par plus de 2 d'une mise à jour à l'autre
    pr := least(greatest(pr, l.price * 0.5), l.price * 2);
    update public.stock_listings set
      prev_price = case when pr <> l.price then l.price else prev_price end,
      price = pr, div_rate = dv, shares = sh, hist = h,
      offer = least(greatest(l.offer + coalesce(p_offer_delta, 0), 0), 1000000000),
      updated_at = now()
    where company = uid
    returning * into l;
  end if;
  return jsonb_build_object('ok', true, 'offer', l.offer, 'sold', l.sold, 'price', l.price);
end $$;

-- 5. Les cafés cotés (offres en cours d'abord)
create or replace function public.mp_stock_market()
returns jsonb
language sql stable security definer set search_path = public
as $$
  select coalesce(jsonb_agg(r.j order by r.ord), '[]'::jsonb)
  from (
    select jsonb_build_object(
             'id', l.company, 'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji,
             'price', l.price, 'prev_price', l.prev_price, 'div_rate', l.div_rate,
             'offer', l.offer, 'sold', l.sold, 'hist', l.hist, 'me', l.company = auth.uid(),
             'mine', coalesce((select h.qty from public.stock_holdings h
                               where h.holder = auth.uid() and h.company = l.company), 0),
             'holders', (select count(*) from public.stock_holdings h where h.company = l.company)) as j,
           row_number() over (order by (l.offer > 0) desc, l.price * l.shares desc) as ord
    from public.stock_listings l
    join public.profiles p on p.id = l.company
    where l.company = auth.uid()
       or (not p.hidden and (p.cheats = 0 or p.exempt) and l.updated_at > now() - interval '30 days')
    order by ord
    limit 60
  ) r;
$$;

-- 6. Les actions de joueurs que je détiens
create or replace function public.mp_stock_portfolio()
returns jsonb
language sql stable security definer set search_path = public
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'company', h.company, 'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji,
           'qty', h.qty, 'cost', h.cost, 'price', l.price, 'prev_price', l.prev_price, 'div_rate', l.div_rate)
         order by h.qty * l.price desc), '[]'::jsonb)
  from public.stock_holdings h
  join public.stock_listings l on l.company = h.company
  join public.profiles p on p.id = h.company
  where h.holder = auth.uid();
$$;

-- 7. Acheter des actions proposées par un joueur (au cours publié, vérifié ici)
create or replace function public.mp_stock_buy(p_company uuid, p_qty bigint, p_price numeric)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  err text := public.stock_ok(auth.uid());
  l   public.stock_listings;
  q   bigint := coalesce(p_qty, 0);
  t   numeric;
begin
  if err is not null then return jsonb_build_object('ok', false, 'error', err); end if;
  if p_company = uid then
    return jsonb_build_object('ok', false, 'error', 'Pour reprendre tes propres actions, utilise « Racheter tes actions ».');
  end if;
  if q < 1 then return jsonb_build_object('ok', false, 'error', 'Quantité invalide.'); end if;
  select * into l from public.stock_listings where company = p_company for update;
  if not found or not exists (select 1 from public.profiles
                              where id = p_company and not hidden and (cheats = 0 or exempt)) then
    return jsonb_build_object('ok', false, 'error', 'Ce café n’est plus coté.');
  end if;
  if l.offer < q then
    return jsonb_build_object('ok', false, 'error', case when l.offer = 0 then 'Plus aucune action en vente pour ce café.'
                                                         else 'Il ne reste que ' || l.offer || ' actions en vente.' end);
  end if;
  if p_price is null or abs(l.price - p_price) > 0.005 then
    return jsonb_build_object('ok', false, 'error', 'Le cours vient de changer : vérifie le nouveau prix.', 'price', l.price);
  end if;
  t := round(q * l.price, 2);
  update public.stock_listings set offer = offer - q, sold = sold + q where company = p_company;
  insert into public.stock_holdings as sh (holder, company, qty, cost) values (uid, p_company, q, t)
  on conflict (holder, company) do update
    set qty = sh.qty + excluded.qty, cost = sh.cost + excluded.cost, updated_at = now();
  insert into public.stock_payouts (user_id, kind, amount, qty, other) values (p_company, 'sale', t, q, uid);
  return jsonb_build_object('ok', true, 'total', t, 'price', l.price);
end $$;

-- 8. Revendre au marché au cours du jour, moins 2 % de frais
create or replace function public.mp_stock_sell(p_company uuid, p_qty bigint)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  h   public.stock_holdings;
  pr  numeric;
  q   bigint;
  a   numeric;
begin
  if uid is null then return jsonb_build_object('ok', false, 'error', 'Connexion impossible. Recharge la page.'); end if;
  select * into h from public.stock_holdings where holder = uid and company = p_company for update;
  if not found then return jsonb_build_object('ok', false, 'error', 'Tu n’as pas d’actions de ce café.'); end if;
  q := least(greatest(coalesce(p_qty, 0), 0), h.qty);
  if q < 1 then return jsonb_build_object('ok', false, 'error', 'Quantité invalide.'); end if;
  select price into pr from public.stock_listings where company = p_company;
  a := round(q * pr * 0.98, 2);
  if q = h.qty then
    delete from public.stock_holdings where holder = uid and company = p_company;
  else
    update public.stock_holdings set qty = qty - q, cost = round(cost * (qty - q)::numeric / qty, 2), updated_at = now()
    where holder = uid and company = p_company;
  end if;
  insert into public.stock_payouts (user_id, kind, amount, qty, other) values (p_company, 'back', 0, q, uid);
  return jsonb_build_object('ok', true, 'amount', a);
end $$;

-- 9. Verser le dividende du soir aux joueurs actionnaires (5 % du cours au plus)
create or replace function public.mp_stock_dividend(p_per_share numeric)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  err text := public.stock_ok(auth.uid());
  l   public.stock_listings;
  ps  numeric;
  n   int;
begin
  if err is not null then return jsonb_build_object('ok', false, 'error', err); end if;
  select * into l from public.stock_listings where company = uid for update;
  if not found then return jsonb_build_object('ok', false, 'error', 'Ton café n’est pas coté.'); end if;
  if l.last_div_at is not null and l.last_div_at > now() - interval '30 seconds' then
    return jsonb_build_object('ok', false, 'error', 'Dividende déjà versé.');
  end if;
  ps := least(greatest(coalesce(p_per_share, 0), 0), l.price * 0.05);
  if l.div_rate = 0 or ps <= 0 then return jsonb_build_object('ok', true, 'holders', 0); end if;
  insert into public.stock_payouts (user_id, kind, amount, qty, other)
  select h.holder, 'div', round(h.qty * ps, 2), h.qty, uid
  from public.stock_holdings h
  where h.company = uid and round(h.qty * ps, 2) > 0;
  get diagnostics n = row_count;
  update public.stock_listings set last_div_at = now() where company = uid;
  return jsonb_build_object('ok', true, 'holders', n);
end $$;

-- 10. Récupérer ventes, dividendes et remboursements en attente (une seule fois chacun)
create or replace function public.mp_stock_claim()
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  r   jsonb;
begin
  if uid is null then return jsonb_build_object('n', 0); end if;
  with d as (delete from public.stock_payouts where user_id = uid returning kind, amount, qty)
  select jsonb_build_object(
           'n', count(*),
           'sale_qty',      coalesce(sum(qty)    filter (where kind = 'sale'), 0),
           'sale_amount',   coalesce(sum(amount) filter (where kind = 'sale'), 0),
           'back_qty',      coalesce(sum(qty)    filter (where kind = 'back'), 0),
           'div_amount',    coalesce(sum(amount) filter (where kind = 'div'), 0),
           'refund_amount', coalesce(sum(amount) filter (where kind = 'refund'), 0))
  into r from d;
  return r || jsonb_build_object('offer', (select offer from public.stock_listings where company = uid));
end $$;

revoke all on function public.stock_refund_holders(), public.stock_ok(uuid) from public, anon, authenticated;
revoke all on function public.mp_stock_update(numeric, numeric, bigint, jsonb, bigint), public.mp_stock_market(),
  public.mp_stock_portfolio(), public.mp_stock_buy(uuid, bigint, numeric), public.mp_stock_sell(uuid, bigint),
  public.mp_stock_dividend(numeric), public.mp_stock_claim() from public, anon;
grant execute on function public.mp_stock_update(numeric, numeric, bigint, jsonb, bigint), public.mp_stock_market(),
  public.mp_stock_portfolio(), public.mp_stock_buy(uuid, bigint, numeric), public.mp_stock_sell(uuid, bigint),
  public.mp_stock_dividend(numeric), public.mp_stock_claim() to authenticated;

-- 11. Plus de cadeau « parts de fondateur » (l'héritage a été remplacé par la Bourse)
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
    if k not in ('max', 'money', 'followers', 'xp', 'levels', 'rep', 'stock', 'menu') then
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

revoke all on function public.admin_gift_many(uuid, jsonb, text) from public, anon;
grant execute on function public.admin_gift_many(uuid, jsonb, text) to authenticated;

-- 12. Actions bradées ----------------------------------------------------------
--     Le vendeur peut proposer ses actions moins cher que le cours (jusqu'à -50 %),
--     à tout le monde ou seulement aux membres de son club. Le cours, lui, ne change pas.
alter table public.stock_listings add column if not exists discount numeric(4,3) not null default 0;
alter table public.stock_listings drop constraint if exists stock_listings_discount_check;
alter table public.stock_listings add constraint stock_listings_discount_check check (discount between 0 and 0.5);
alter table public.stock_listings add column if not exists disc_club boolean not null default false;

-- Prix payé par un acheteur : le cours bradé si la remise le concerne, sinon le cours
create or replace function public.stock_price_for(l public.stock_listings, p_buyer uuid)
returns numeric
language sql stable security definer set search_path = public
as $$
  select case when l.discount > 0 and (not l.disc_club or exists (
           select 1 from public.profiles b join public.profiles s on s.id = l.company
           where b.id = p_buyer and b.club_id is not null and b.club_id = s.club_id))
         then greatest(round(l.price * (1 - l.discount), 2), 0.01) else l.price end;
$$;
revoke all on function public.stock_price_for(public.stock_listings, uuid) from public, anon, authenticated;

drop function if exists public.mp_stock_update(numeric, numeric, bigint, jsonb, bigint);
create or replace function public.mp_stock_update(p_price numeric, p_div numeric, p_shares bigint,
                                                  p_hist jsonb default '[]'::jsonb, p_offer_delta bigint default 0,
                                                  p_discount numeric default null, p_disc_club boolean default null)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  err text := public.stock_ok(auth.uid());
  l   public.stock_listings;
  fv  bigint;
  pr  numeric;
  sh  bigint := least(greatest(coalesce(p_shares, 100000), 100000), 1000000000);
  dv  numeric := least(greatest(coalesce(p_div, 0), 0), 0.5);
  dc  numeric := case when p_discount is null then null else least(greatest(p_discount, 0), 0.5) end;
  h   jsonb := case when jsonb_typeof(p_hist) = 'array' and pg_column_size(p_hist) < 2000 then p_hist else '[]'::jsonb end;
begin
  if err is not null then return jsonb_build_object('ok', false, 'error', err); end if;
  if p_price is null or p_price <= 0 then
    return jsonb_build_object('ok', false, 'error', 'Cours invalide.');
  end if;
  select firm_value into fv from public.profiles where id = uid;
  pr := greatest(round(least(p_price, greatest(coalesce(fv, 0), 100000) * 5.0 / sh), 2), 0.01);
  select * into l from public.stock_listings where company = uid for update;
  if not found then
    insert into public.stock_listings (company, price, prev_price, div_rate, shares, offer, hist, discount, disc_club)
    values (uid, pr, case when jsonb_typeof(h -> -2) = 'number' then (h ->> -2)::numeric end,
            dv, sh, least(greatest(coalesce(p_offer_delta, 0), 0), 1000000000), h, coalesce(dc, 0), coalesce(p_disc_club, false))
    returning * into l;
  else
    pr := least(greatest(pr, l.price * 0.5), l.price * 2);
    update public.stock_listings set
      prev_price = case when pr <> l.price then l.price else prev_price end,
      price = pr, div_rate = dv, shares = sh, hist = h,
      offer = least(greatest(l.offer + coalesce(p_offer_delta, 0), 0), 1000000000),
      discount = coalesce(dc, l.discount), disc_club = coalesce(p_disc_club, l.disc_club),
      updated_at = now()
    where company = uid
    returning * into l;
  end if;
  return jsonb_build_object('ok', true, 'offer', l.offer, 'sold', l.sold, 'price', l.price,
                            'discount', l.discount, 'disc_club', l.disc_club);
end $$;

create or replace function public.mp_stock_market()
returns jsonb
language sql stable security definer set search_path = public
as $$
  select coalesce(jsonb_agg(r.j order by r.ord), '[]'::jsonb)
  from (
    select jsonb_build_object(
             'id', l.company, 'pseudo', p.pseudo, 'firm_name', p.firm_name, 'emoji', p.emoji,
             'price', l.price, 'prev_price', l.prev_price, 'div_rate', l.div_rate,
             'offer', l.offer, 'sold', l.sold, 'hist', l.hist, 'me', l.company = auth.uid(),
             'discount', l.discount, 'disc_club', l.disc_club,
             'my_price', public.stock_price_for(l, auth.uid()),
             'mine', coalesce((select h.qty from public.stock_holdings h
                               where h.holder = auth.uid() and h.company = l.company), 0),
             'holders', (select count(*) from public.stock_holdings h where h.company = l.company)) as j,
           row_number() over (order by (l.offer > 0) desc, l.price * l.shares desc) as ord
    from public.stock_listings l
    join public.profiles p on p.id = l.company
    where l.company = auth.uid()
       or (not p.hidden and (p.cheats = 0 or p.exempt) and l.updated_at > now() - interval '30 days')
    order by ord
    limit 60
  ) r;
$$;

create or replace function public.mp_stock_buy(p_company uuid, p_qty bigint, p_price numeric)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  uid uuid := auth.uid();
  err text := public.stock_ok(auth.uid());
  l   public.stock_listings;
  q   bigint := coalesce(p_qty, 0);
  pe  numeric;
  t   numeric;
begin
  if err is not null then return jsonb_build_object('ok', false, 'error', err); end if;
  if p_company = uid then
    return jsonb_build_object('ok', false, 'error', 'Pour reprendre tes propres actions, utilise « Racheter tes actions ».');
  end if;
  if q < 1 then return jsonb_build_object('ok', false, 'error', 'Quantité invalide.'); end if;
  select * into l from public.stock_listings where company = p_company for update;
  if not found or not exists (select 1 from public.profiles
                              where id = p_company and not hidden and (cheats = 0 or exempt)) then
    return jsonb_build_object('ok', false, 'error', 'Ce café n’est plus coté.');
  end if;
  if l.offer < q then
    return jsonb_build_object('ok', false, 'error', case when l.offer = 0 then 'Plus aucune action en vente pour ce café.'
                                                         else 'Il ne reste que ' || l.offer || ' actions en vente.' end);
  end if;
  pe := public.stock_price_for(l, uid);
  if p_price is null or abs(pe - p_price) > 0.005 then
    return jsonb_build_object('ok', false, 'error', 'Le prix vient de changer : vérifie le nouveau prix.', 'price', pe);
  end if;
  t := round(q * pe, 2);
  update public.stock_listings set offer = offer - q, sold = sold + q where company = p_company;
  insert into public.stock_holdings as sh (holder, company, qty, cost) values (uid, p_company, q, t)
  on conflict (holder, company) do update
    set qty = sh.qty + excluded.qty, cost = sh.cost + excluded.cost, updated_at = now();
  insert into public.stock_payouts (user_id, kind, amount, qty, other) values (p_company, 'sale', t, q, uid);
  return jsonb_build_object('ok', true, 'total', t, 'price', pe);
end $$;

revoke all on function public.mp_stock_update(numeric, numeric, bigint, jsonb, bigint, numeric, boolean),
  public.mp_stock_market(), public.mp_stock_buy(uuid, bigint, numeric) from public, anon;
grant execute on function public.mp_stock_update(numeric, numeric, bigint, jsonb, bigint, numeric, boolean),
  public.mp_stock_market(), public.mp_stock_buy(uuid, bigint, numeric) to authenticated;
