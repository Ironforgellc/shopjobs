-- ============================================================
-- ShopJobs Database Schema
-- Run this in your Supabase SQL editor (Dashboard → SQL Editor)
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ── Orders ────────────────────────────────────────────────────────────────────
create table orders (
  id            uuid primary key default uuid_generate_v4(),
  so_number     text not null,
  customer      text,
  description   text,
  due_date      date,
  status        text not null default 'todo',  -- todo | inprog | ready | shipped
  pct_complete  integer not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ── Jobs ──────────────────────────────────────────────────────────────────────
create table jobs (
  id            uuid primary key default uuid_generate_v4(),
  order_id      uuid not null references orders(id) on delete cascade,
  part_number   text not null,
  name          text not null,
  type          text not null,  -- weld | part | asm
  material      text,
  weight        text,
  qty           integer not null default 1,
  dwg_file      text,
  dwg_page      text,
  dwg_url       text,           -- populated when Google Drive link is added
  raw_material  text,           -- for standalone parts
  dimensions    jsonb,          -- { len } or { w, l }
  status        text not null default 'todo',
  pct_complete  integer not null default 0,
  work_centers  text[],         -- ordered list of work center ids
  steps         jsonb,          -- array of { wc, label, tag, status }
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ── Tasks (child parts of weldments) ─────────────────────────────────────────
create table tasks (
  id            uuid primary key default uuid_generate_v4(),
  job_id        uuid not null references jobs(id) on delete cascade,
  mark          text not null,
  description   text not null,
  raw_material  text,
  dimensions    jsonb,          -- { len } or { w, l }
  qty           integer not null default 1,
  is_hw         boolean not null default false,
  bend          boolean not null default false,
  status        text not null default 'todo',  -- todo | inprog | done
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ── Auto-update updated_at ────────────────────────────────────────────────────
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger orders_updated_at before update on orders for each row execute function update_updated_at();
create trigger jobs_updated_at   before update on jobs   for each row execute function update_updated_at();
create trigger tasks_updated_at  before update on tasks  for each row execute function update_updated_at();

-- ── Row Level Security ────────────────────────────────────────────────────────
alter table orders enable row level security;
alter table jobs   enable row level security;
alter table tasks  enable row level security;

-- All authenticated users can read everything
create policy "Authenticated users can read orders" on orders for select to authenticated using (true);
create policy "Authenticated users can read jobs"   on jobs   for select to authenticated using (true);
create policy "Authenticated users can read tasks"  on tasks  for select to authenticated using (true);

-- All authenticated users can update task status and job steps
create policy "Authenticated users can update tasks" on tasks for update to authenticated using (true);
create policy "Authenticated users can update jobs"  on jobs  for update to authenticated using (true);

-- Only admins can insert/delete (enforced via user metadata role = 'admin')
create policy "Admins can insert orders" on orders for insert to authenticated
  with check ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
create policy "Admins can insert jobs" on jobs for insert to authenticated
  with check ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
create policy "Admins can insert tasks" on tasks for insert to authenticated
  with check ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');
create policy "Admins can delete orders" on orders for delete to authenticated
  using ((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Storage bucket for drawings ───────────────────────────────────────────────
insert into storage.buckets (id, name, public) values ('drawings', 'drawings', true)
  on conflict do nothing;

create policy "Authenticated users can read drawings" on storage.objects
  for select to authenticated using (bucket_id = 'drawings');
create policy "Admins can upload drawings" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'drawings' and (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── Enable realtime ───────────────────────────────────────────────────────────
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table jobs;
alter publication supabase_realtime add table tasks;
