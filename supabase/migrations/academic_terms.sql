-- Create academic_terms table for admin configuration
create table if not exists academic_terms (
  id uuid primary key default gen_random_uuid(),
  term text not null check (term in ('Term 1', 'Term 2', 'Term 3')),
  year integer not null,
  start_date date not null,
  end_date date not null,
  stream text default 'Main',
  is_active boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique (term, year)
);

-- Enable RLS
alter table academic_terms enable row level security;

-- Only admin can manage academic terms
create policy academic_terms_admin_all on academic_terms
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

-- Teachers can read active term
create policy academic_terms_teacher_select on academic_terms
  for select using (auth.uid() is not null);

-- Function to get active term
create or replace function get_active_term()
returns table (
  id uuid,
  term text,
  year integer,
  start_date date,
  end_date date,
  stream text
)
language sql
security definer
as $$
  select id, term, year, start_date, end_date, stream
  from academic_terms
  where is_active = true
  limit 1;
$$;

-- Function to set active term (deactivates others)
create or replace function set_active_term(term_id uuid)
returns void
language plpgsql
security definer
as $$
begin
  update academic_terms set is_active = false where is_active = true;
  update academic_terms set is_active = true, updated_at = now() where id = term_id;
end;
$$;

-- Insert default term for 2025 Term 2
insert into academic_terms (term, year, start_date, end_date, is_active)
values ('Term 2', 2025, '2025-05-01'::date, '2025-08-31'::date, true)
on conflict (term, year) do nothing;
