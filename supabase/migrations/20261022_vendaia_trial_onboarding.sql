-- VendaIA - trial onboarding isolated per organization.
-- Apply ONLY to a dedicated VendaIA Supabase project after reviewing the core schema.
alter table public.organizations
  add column if not exists created_by uuid references auth.users(id);
alter table public.subscriptions
  add column if not exists trial_started_at timestamptz,
  add column if not exists trial_ends_at timestamptz;
create unique index if not exists vendaia_one_subscription_per_org
  on public.subscriptions(organization_id);
create index if not exists vendaia_subscription_trial_expiry
  on public.subscriptions(trial_ends_at) where status='trialing';
-- Prevent a user from manipulating expiry dates via the public Data API.
revoke insert,update,delete on public.subscriptions from anon,authenticated;
-- A locked-down enrollment function validates identity and creates trial state.
-- The calling user never supplies dates or pricing.
create or replace function public.start_my_trial(company_name text, chosen_plan text)
returns table(organization_id uuid, trial_ends_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
declare actor uuid; org uuid; expiry timestamptz; 
begin
 actor := (select auth.uid());
 if actor is null then raise exception 'Authentication required'; end if;
 if coalesce((select (auth.jwt()->>'is_anonymous')::boolean),false) then
   raise exception 'Verified account required';
 end if;
 if length(trim(coalesce(company_name,''))) < 2 or length(company_name)>120 then
   raise exception 'Invalid company name';
 end if;
 if chosen_plan not in ('start','pro') then raise exception 'Invalid plan'; end if;
 -- One trial per authenticated user; server-side guard (not complete anti-abuse for multiple accounts).
 if exists(select 1 from public.organization_members where user_id=actor) then
   raise exception 'Account already belongs to an organization';
 end if;
 expiry := now()+interval '7 days';
 insert into public.organizations(name,created_by) values(trim(company_name),actor) returning id into org;
 insert into public.organization_members(organization_id,user_id,role) values(org,actor,'owner');
 insert into public.subscriptions(organization_id,plan_id,status,trial_started_at,trial_ends_at)
 values(org,chosen_plan,'trialing',now(),expiry);
 return query select org,expiry;
end;
$$;
revoke all on function public.start_my_trial(text,text) from public,anon;
grant execute on function public.start_my_trial(text,text) to authenticated;
-- The trial is expired based on the DB clock; no cron required to check access.
create or replace view public.my_subscription_status with (security_invoker=true) as
 select s.id,s.organization_id,s.plan_id,s.status,s.trial_started_at,s.trial_ends_at,
 (s.status='trialing' and s.trial_ends_at>now()) as trial_active
 from public.subscriptions s;
grant select on public.my_subscription_status to authenticated;
-- Run a scheduled job or webhook later for status cleanup; access decisions MUST check the time.
