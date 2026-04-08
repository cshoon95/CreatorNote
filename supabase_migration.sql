-- CreatorNote: Supabase Migration
-- Influencer sponsorship management tool
-- Run this in Supabase SQL Editor

-- ============================================================
-- STEP 1: Create ALL tables first
-- ============================================================

create extension if not exists "pgcrypto";

create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url   text,
  provider     text,
  created_at   timestamptz not null default now()
);

create table public.workspaces (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  owner_id   uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  role         text not null default 'member' check (role in ('owner', 'member')),
  joined_at    timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table public.invite_codes (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  code         text not null unique,
  created_by   uuid not null references public.profiles(id) on delete cascade,
  expires_at   timestamptz,
  max_uses     int not null default 0,
  used_count   int not null default 0,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  constraint code_format check (code ~ '^[A-Za-z0-9]{6}$')
);

create table public.sponsorships (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  created_by   uuid not null references public.profiles(id) on delete set null,
  brand_name   text not null,
  product_name text,
  details      text,
  amount       float8 not null default 0,
  start_date   timestamptz,
  end_date     timestamptz,
  status       text not null default 'preSubmit'
                 check (status in ('preSubmit', 'underReview', 'submitted', 'pendingSettlement', 'completed')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table public.settlements (
  id              uuid primary key default gen_random_uuid(),
  workspace_id    uuid not null references public.workspaces(id) on delete cascade,
  created_by      uuid not null references public.profiles(id) on delete set null,
  brand_name      text not null,
  amount          float8 not null default 0,
  fee             float8 not null default 0,
  tax             float8 not null default 0,
  settlement_date timestamptz,
  is_paid         boolean not null default false,
  memo            text,
  sponsorship_id  uuid references public.sponsorships(id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create table public.reels_notes (
  id                 uuid primary key default gen_random_uuid(),
  workspace_id       uuid not null references public.workspaces(id) on delete cascade,
  created_by         uuid not null references public.profiles(id) on delete set null,
  title              text not null,
  attributed_content bytea,
  plain_content      text not null default '',
  status             text not null default 'drafting'
                       check (status in ('drafting', 'readyToUpload', 'uploaded')),
  tags               text[] not null default '{}',
  is_pinned          boolean not null default false,
  sponsorship_id     uuid references public.sponsorships(id) on delete set null,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

create table public.general_notes (
  id                 uuid primary key default gen_random_uuid(),
  workspace_id       uuid not null references public.workspaces(id) on delete cascade,
  created_by         uuid not null references public.profiles(id) on delete set null,
  title              text not null,
  attributed_content bytea,
  plain_content      text not null default '',
  tags               text[] not null default '{}',
  is_pinned          boolean not null default false,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);

-- ============================================================
-- STEP 2: Enable RLS on all tables
-- ============================================================

alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.invite_codes enable row level security;
alter table public.sponsorships enable row level security;
alter table public.settlements enable row level security;
alter table public.reels_notes enable row level security;
alter table public.general_notes enable row level security;

-- ============================================================
-- STEP 3: RLS Policies (all tables exist now)
-- ============================================================

-- Profiles
create policy "profiles_select" on public.profiles for select using (true);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id);

-- Workspaces
create policy "workspaces_select" on public.workspaces
  for select using (id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "workspaces_insert" on public.workspaces
  for insert with check (owner_id = auth.uid());
create policy "workspaces_update" on public.workspaces
  for update using (owner_id = auth.uid());
create policy "workspaces_delete" on public.workspaces
  for delete using (owner_id = auth.uid());

-- Workspace Members
create policy "workspace_members_select" on public.workspace_members
  for select using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "workspace_members_insert" on public.workspace_members
  for insert with check (
    exists (select 1 from public.workspace_members wm where wm.workspace_id = workspace_members.workspace_id and wm.user_id = auth.uid() and wm.role = 'owner')
  );
create policy "workspace_members_delete" on public.workspace_members
  for delete using (
    user_id = auth.uid()
    or exists (select 1 from public.workspace_members wm where wm.workspace_id = workspace_members.workspace_id and wm.user_id = auth.uid() and wm.role = 'owner')
  );

-- Invite Codes
create policy "invite_codes_select" on public.invite_codes
  for select using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "invite_codes_insert" on public.invite_codes
  for insert with check (
    exists (select 1 from public.workspace_members wm where wm.workspace_id = invite_codes.workspace_id and wm.user_id = auth.uid() and wm.role = 'owner')
  );
create policy "invite_codes_update" on public.invite_codes
  for update using (
    exists (select 1 from public.workspace_members wm where wm.workspace_id = invite_codes.workspace_id and wm.user_id = auth.uid() and wm.role = 'owner')
  );

-- Sponsorships
create policy "sponsorships_select" on public.sponsorships
  for select using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "sponsorships_insert" on public.sponsorships
  for insert with check (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "sponsorships_update" on public.sponsorships
  for update using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "sponsorships_delete" on public.sponsorships
  for delete using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));

-- Settlements
create policy "settlements_select" on public.settlements
  for select using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "settlements_insert" on public.settlements
  for insert with check (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "settlements_update" on public.settlements
  for update using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "settlements_delete" on public.settlements
  for delete using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));

-- Reels Notes
create policy "reels_notes_select" on public.reels_notes
  for select using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "reels_notes_insert" on public.reels_notes
  for insert with check (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "reels_notes_update" on public.reels_notes
  for update using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "reels_notes_delete" on public.reels_notes
  for delete using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));

-- General Notes
create policy "general_notes_select" on public.general_notes
  for select using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "general_notes_insert" on public.general_notes
  for insert with check (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "general_notes_update" on public.general_notes
  for update using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));
create policy "general_notes_delete" on public.general_notes
  for delete using (workspace_id in (select workspace_id from public.workspace_members where user_id = auth.uid()));

-- ============================================================
-- 9. Auto-update updated_at trigger
-- ============================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_sponsorships_updated_at
  before update on public.sponsorships
  for each row execute function public.set_updated_at();

create trigger trg_settlements_updated_at
  before update on public.settlements
  for each row execute function public.set_updated_at();

create trigger trg_reels_notes_updated_at
  before update on public.reels_notes
  for each row execute function public.set_updated_at();

create trigger trg_general_notes_updated_at
  before update on public.general_notes
  for each row execute function public.set_updated_at();

-- ============================================================
-- 10. Auto-create profile on auth.users insert
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name, avatar_url, provider)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''),
    coalesce(new.raw_user_meta_data ->> 'avatar_url', ''),
    coalesce(new.raw_user_meta_data ->> 'provider', 'email')
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================
-- 11. Join workspace via invite code
-- ============================================================
create or replace function public.join_workspace_by_invite(invite_code text)
returns uuid as $$
declare
  v_invite   public.invite_codes%rowtype;
  v_user_id  uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select * into v_invite
  from public.invite_codes
  where code = invite_code
    and is_active = true
  for update;

  if not found then
    raise exception 'Invalid or inactive invite code';
  end if;

  if v_invite.expires_at is not null and v_invite.expires_at < now() then
    raise exception 'Invite code has expired';
  end if;

  if v_invite.max_uses > 0 and v_invite.used_count >= v_invite.max_uses then
    raise exception 'Invite code has reached maximum uses';
  end if;

  -- Check if already a member.
  if exists (
    select 1 from public.workspace_members
    where workspace_id = v_invite.workspace_id and user_id = v_user_id
  ) then
    return v_invite.workspace_id;
  end if;

  insert into public.workspace_members (workspace_id, user_id, role)
  values (v_invite.workspace_id, v_user_id, 'member');

  update public.invite_codes
  set used_count = used_count + 1
  where id = v_invite.id;

  return v_invite.workspace_id;
end;
$$ language plpgsql security definer;

-- ============================================================
-- 12. Indexes
-- ============================================================

-- Workspace members: fast membership lookups (covers RLS sub-selects).
create index idx_workspace_members_user_id on public.workspace_members(user_id);

-- Invite codes: lookup by code.
create index idx_invite_codes_code on public.invite_codes(code);

-- Sponsorships
create index idx_sponsorships_workspace_id on public.sponsorships(workspace_id);
create index idx_sponsorships_status       on public.sponsorships(status);
create index idx_sponsorships_brand_name   on public.sponsorships(brand_name);
create index idx_sponsorships_start_date   on public.sponsorships(start_date);

-- Settlements
create index idx_settlements_workspace_id   on public.settlements(workspace_id);
create index idx_settlements_sponsorship_id on public.settlements(sponsorship_id);
create index idx_settlements_is_paid        on public.settlements(is_paid);

-- Reels Notes
create index idx_reels_notes_workspace_id   on public.reels_notes(workspace_id);
create index idx_reels_notes_sponsorship_id on public.reels_notes(sponsorship_id);
create index idx_reels_notes_status         on public.reels_notes(status);
create index idx_reels_notes_tags           on public.reels_notes using gin(tags);

-- General Notes
create index idx_general_notes_workspace_id on public.general_notes(workspace_id);
create index idx_general_notes_tags         on public.general_notes using gin(tags);

-- 13. Pin feature for notes
alter table public.reels_notes add column if not exists is_pinned boolean not null default false;
alter table public.general_notes add column if not exists is_pinned boolean not null default false;
