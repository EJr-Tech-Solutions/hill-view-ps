-- ============================================================
-- Minimal Schema Update (keeps all existing data)
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Add missing columns to pupils if they don't exist
alter table pupils add column if not exists avatar text;
alter table pupils add column if not exists house text;
alter table pupils add column if not exists paycode text;

-- 1b. Add avatar column to users if it doesn't exist
alter table users add column if not exists avatar text;

-- 2. Add teacher_comment column to marks if it doesn't exist
alter table marks add column if not exists teacher_comment text;

-- 3. Drop FK constraint on users.id -> auth.users.id to prevent race conditions
alter table users drop constraint if exists users_id_fkey;

-- 4. Create teacher_classes table if it doesn't exist
create table if not exists teacher_classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references users (id) on delete cascade,
  class_id uuid not null references classes (id) on delete cascade,
  unique (teacher_id, class_id)
);

-- 5. Enable RLS on teacher_classes if not enabled
alter table teacher_classes enable row level security;

-- 6. Add indexes
create index if not exists idx_teacher_classes_teacher on teacher_classes (teacher_id);
create index if not exists idx_teacher_classes_class on teacher_classes (class_id);

-- 7. Create academic_terms table if it doesn't exist
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

alter table academic_terms enable row level security;

-- 8. Drop existing marks teacher policies and recreate
drop policy if exists marks_teacher_all on marks;
drop policy if exists marks_teacher_select on marks;
drop policy if exists marks_teacher_insert on marks;
drop policy if exists marks_teacher_update on marks;

create policy marks_teacher_all on marks
  for all using (app_user_role() = 'teacher')
  with check (app_user_role() = 'teacher');

-- 9. Fix users policy for admin user creation (prevents FK/race issues)
drop policy if exists users_admin_all on users;
create policy users_admin_all on users
  for all using (
    auth.uid() in (select id from users where role = 'admin')
  )
  with check (
    auth.uid() in (select id from users where role = 'admin')
  );

-- 10. Add admin CRUD policy for subjects
drop policy if exists subjects_admin_all on subjects;
create policy subjects_admin_all on subjects
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

-- 11. Academic terms policies
drop policy if exists academic_terms_admin_all on academic_terms;
drop policy if exists academic_terms_teacher_select on academic_terms;

create policy academic_terms_admin_all on academic_terms
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy academic_terms_teacher_select on academic_terms
  for select using (auth.uid() is not null);

-- 12. Teacher classes policies
drop policy if exists teacher_classes_admin_all on teacher_classes;
drop policy if exists teacher_classes_teacher_select on teacher_classes;
drop policy if exists teacher_classes_teacher_insert on teacher_classes;
drop policy if exists teacher_classes_teacher_delete on teacher_classes;

create policy teacher_classes_admin_all on teacher_classes
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy teacher_classes_teacher_select on teacher_classes
  for select using (teacher_id = auth.uid());

create policy teacher_classes_teacher_insert on teacher_classes
  for insert with check (teacher_id = auth.uid());

create policy teacher_classes_teacher_delete on teacher_classes
  for delete using (teacher_id = auth.uid());

-- 13. Drop app_user_class function with CASCADE (will drop dependent policies)
drop function if exists app_user_class() cascade;

-- 14. Recreate helper functions with security definer
drop function if exists app_user_role() cascade;
create function app_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from users where id = auth.uid();
$$;

create function app_user_class()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select class_id from users where id = auth.uid() and role = 'admin'
  union
  select tc.class_id from teacher_classes tc where tc.teacher_id = auth.uid()
  limit 1;
$$;

-- 15. Set security definer on set_mark_teacher
drop trigger if exists mark_teacher_trigger on marks;
drop function if exists set_mark_teacher() cascade;

create or replace function set_mark_teacher()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.teacher_id is null then
    new.teacher_id := auth.uid();
  end if;
  return new;
end;
$$;

create trigger mark_teacher_trigger
before insert on marks
for each row execute procedure set_mark_teacher();

-- 16. Recreate policies that depend on app_user_class()
drop policy if exists classes_teacher_select on classes;
create policy classes_teacher_select on classes
  for select using (
    app_user_role() = 'teacher'
    and exists (
      select 1 from teacher_classes tc
      where tc.teacher_id = auth.uid()
        and tc.class_id = id
    )
  );

drop policy if exists pupils_teacher_select on classes;
create policy pupils_teacher_select on pupils
  for select using (
    app_user_role() = 'teacher'
    and exists (
      select 1 from teacher_classes tc
      where tc.teacher_id = auth.uid()
        and tc.class_id = pupils.class_id
    )
  );

drop policy if exists pupils_teacher_insert on pupils;
create policy pupils_teacher_insert on pupils
  for insert with check (
    app_user_role() = 'teacher'
    and exists (
      select 1 from teacher_classes tc
      where tc.teacher_id = auth.uid()
        and tc.class_id = pupils.class_id
    )
  );

drop policy if exists pupils_teacher_update on pupils;
create policy pupils_teacher_update on pupils
  for update using (
    exists (
      select 1 from teacher_classes tc
      where tc.teacher_id = auth.uid()
        and tc.class_id = pupils.class_id
    )
  )
  with check (
    exists (
      select 1 from teacher_classes tc
      where tc.teacher_id = auth.uid()
        and tc.class_id = pupils.class_id
    )
  );

-- 17. Add academic_terms helper functions
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
set search_path = public
as $$
  select id, term, year, start_date, end_date, stream
  from academic_terms
  where is_active = true
  limit 1;
$$;

create or replace function set_active_term(term_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update academic_terms set is_active = false where is_active = true;
  update academic_terms set is_active = true, updated_at = now() where id = term_id;
end;
$$;

-- 18. Update pupil_report_subjects view to include teacher_comment
drop view if exists pupil_report_subjects;
create view pupil_report_subjects as
select
  p.id as pupil_id,
  p.name as pupil_name,
  c.id as class_id,
  c.name as class_name,
  s.name as subject_name,
  m.score,
  m.teacher_comment
from pupils p
join classes c on c.id = p.class_id
join marks m on m.pupil_id = p.id
join subjects s on s.id = m.subject_id;

-- 19. Fix teacher_submission_status view (was joining on legacy class_id, now uses teacher_classes)
drop view if exists teacher_submission_status;
create or replace view teacher_submission_status as
with class_subject_counts as (
  select
    c.id as class_id,
    count(s.id) as subject_count
  from classes c
  join subjects s on (
    (c.name like 'KG%' and s.level = 'nursery')
    or ((c.name like 'P1%' or c.name like 'P2%' or c.name like 'P3%') and s.level = 'p1-p3')
    or ((c.name like 'P4%' or c.name like 'P5%' or c.name like 'P6%' or c.name like 'P7%') and s.level = 'p4-p7')
  )
  group by c.id
),
teacher_marks as (
  select
    u.id as teacher_id,
    u.name as teacher_name,
    tc.class_id,
    c.name as class_name,
    count(distinct m.subject_id) as subjects_entered
  from users u
  join teacher_classes tc on tc.teacher_id = u.id
  join classes c on c.id = tc.class_id
  left join marks m on m.teacher_id = u.id and m.pupil_id in (
    select p.id from pupils p where p.class_id = tc.class_id
  )
  where u.role = 'teacher'
  group by u.id, u.name, tc.class_id, c.name
  union
  select
    u.id as teacher_id,
    u.name as teacher_name,
    tc.class_id,
    c.name as class_name,
    0 as subjects_entered
  from users u
  join teacher_classes tc on tc.teacher_id = u.id
  join classes c on c.id = tc.class_id
  where u.role = 'teacher'
    and not exists (
      select 1 from marks m
      join pupils p on p.id = m.pupil_id
      where m.teacher_id = u.id and p.class_id = tc.class_id
    )
)
select
  teacher_marks.teacher_name,
  teacher_marks.class_name,
  max(teacher_marks.subjects_entered) as subjects_entered,
  class_subject_counts.subject_count
from teacher_marks
join class_subject_counts on class_subject_counts.class_id = teacher_marks.class_id
group by teacher_marks.teacher_name, teacher_marks.class_name, class_subject_counts.subject_count;

-- 20. Create nursery_color_config if not exists
create table if not exists nursery_color_config (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references users (id) on delete cascade,
  level integer not null check (level between 1 and 5),
  color text not null,
  unique (teacher_id, level)
);

alter table nursery_color_config enable row level security;

drop policy if exists nursery_color_config_admin_all on nursery_color_config;
drop policy if exists nursery_color_config_teacher_all on nursery_color_config;

create policy nursery_color_config_admin_all on nursery_color_config
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy nursery_color_config_teacher_all on nursery_color_config
  for all using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

-- Done!
select 'Schema update complete!' as status;
