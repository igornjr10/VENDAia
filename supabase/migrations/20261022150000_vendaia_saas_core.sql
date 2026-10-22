-- Proposta inicial de esquema multiempresa. Revisar antes de aplicar em produção.
create extension if not exists pgcrypto;
create table if not exists public.organizations (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 created_at timestamptz not null default now()
);
create table if not exists public.organization_members (
 organization_id uuid not null references public.organizations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null default 'member' check(role in ('owner','admin','member')),
 primary key (organization_id,user_id)
);
create table if not exists public.subscription_plans (
 id text primary key,
 name text not null,
 monthly_price_cents integer not null check(monthly_price_cents >= 0)
);
insert into public.subscription_plans(id,name,monthly_price_cents)
values ('start','VendaIA Start',9700),('pro','VendaIA Pro',29700)
on conflict(id) do update set name=excluded.name,monthly_price_cents=excluded.monthly_price_cents;
create table if not exists public.subscriptions (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 plan_id text not null references public.subscription_plans(id),
 status text not null default 'pending' check(status in ('pending','trialing','active','past_due','canceled')),
 external_customer_id text,
 external_subscription_id text,
 current_period_end timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.agents (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,
 instructions text not null default '',
 is_active boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.contacts (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 name text,
 phone text,
 created_at timestamptz not null default now()
);
create table if not exists public.conversations (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 contact_id uuid not null references public.contacts(id) on delete cascade,
 status text not null default 'open',
 created_at timestamptz not null default now(),
 unique(id,organization_id)
);
create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 conversation_id uuid not null,
 body text not null,
 direction text not null check(direction in ('inbound','outbound')),
 created_at timestamptz not null default now(),
 foreign key (conversation_id, organization_id) references public.conversations(id,organization_id) on delete cascade
);
create table if not exists public.usage_events (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 event_type text not null,
 quantity integer not null default 1 check(quantity>0),
 created_at timestamptz not null default now()
);
-- RLS by default-deny; policies intentionally grant SELECT only.
-- All writes to billing, usage and conversation data must go through a validated backend.
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.agents enable row level security;
alter table public.contacts enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.usage_events enable row level security;
create policy "members read organizations" on public.organizations for select to authenticated
using (exists (select 1 from public.organization_members m where m.organization_id=id and m.user_id=(select auth.uid())));
create policy "members read memberships" on public.organization_members for select to authenticated
using (user_id=(select auth.uid()));
create policy "read plan catalog" on public.subscription_plans for select to anon,authenticated using(true);
create policy "members read subscriptions" on public.subscriptions for select to authenticated
using (exists(select 1 from public.organization_members m where m.organization_id=subscriptions.organization_id and m.user_id=(select auth.uid())));
create policy "members read agents" on public.agents for select to authenticated
using (exists(select 1 from public.organization_members m where m.organization_id=agents.organization_id and m.user_id=(select auth.uid())));
create policy "members read contacts" on public.contacts for select to authenticated
using (exists(select 1 from public.organization_members m where m.organization_id=contacts.organization_id and m.user_id=(select auth.uid())));
create policy "members read conversations" on public.conversations for select to authenticated
using (exists(select 1 from public.organization_members m where m.organization_id=conversations.organization_id and m.user_id=(select auth.uid())));
create policy "members read messages" on public.messages for select to authenticated
using (exists(select 1 from public.organization_members m where m.organization_id=messages.organization_id and m.user_id=(select auth.uid())));
create policy "members read usage" on public.usage_events for select to authenticated
using (exists(select 1 from public.organization_members m where m.organization_id=usage_events.organization_id and m.user_id=(select auth.uid())));
