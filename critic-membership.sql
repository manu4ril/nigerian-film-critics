-- Nigerian Film Critics: verified critic profile management
-- Run this AFTER critic-membership.sql

alter table public.critics
  add column if not exists expertise text default '',
  add column if not exists links text default '';

drop policy if exists "critics own profile update" on public.critics;
create policy "critics own profile update"
on public.critics for update
using (
  user_id = auth.uid()
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'critic'
  )
)
with check (
  user_id = auth.uid()
  and exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'critic'
  )
);

create or replace function public.approve_critic_application(
  application_id bigint,
  admin_notes_value text default null
)
returns void
language plpgsql
security definer set search_path = public
as $$
declare
  a public.critic_applications%rowtype;
begin
  if not exists (select 1 from public.admins where user_id = auth.uid()) then
    raise exception 'Administrator access required';
  end if;

  select * into a
  from public.critic_applications
  where id = application_id
  for update;

  if not found then
    raise exception 'Critic application not found';
  end if;

  update public.profiles
  set role = 'critic',
      display_name = a.full_name,
      bio = coalesce(a.bio, ''),
      updated_at = now()
  where id = a.user_id;

  insert into public.critics (user_id, name, bio, avatar_url, expertise, links)
  values (a.user_id, a.full_name, coalesce(a.bio, ''), '', coalesce(a.expertise, ''), coalesce(a.links, ''))
  on conflict (user_id) do update
  set name = excluded.name,
      bio = excluded.bio,
      expertise = excluded.expertise,
      links = excluded.links;

  update public.critic_applications
  set status = 'approved',
      admin_notes = admin_notes_value,
      reviewed_at = now()
  where id = a.id;
end;
$$;

revoke all on function public.approve_critic_application(bigint,text) from public;
grant execute on function public.approve_critic_application(bigint,text) to authenticated;
