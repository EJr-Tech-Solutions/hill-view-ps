-- ============================================================
-- Minimal Schema Update (keeps all existing data)
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Add missing columns to pupils if they don't exist
alter table pupils add column if not exists avatar text;
alter table pupils add column if not exists house text;
alter table pupils add column if not exists paycode text;

-- 2. Add teacher_comment column to marks if it doesn't exist
alter table marks add column if not exists teacher_comment text;

-- 3. Create teacher_classes table if it doesn't exist
create table if not exists teacher_classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references users (id) on delete cascade,
  class_id uuid not null references classes (id) on delete cascade,
  unique (teacher_id, class_id)
);

-- 4. Enable RLS on teacher_classes if not enabled
alter table teacher_classes enable row level security;

-- 5. Add indexes
create index if not exists idx_teacher_classes_teacher on teacher_classes (teacher_id);
create index if not exists idx_teacher_classes_class on teacher_classes (class_id);

-- 6. Drop existing marks teacher policies and recreate (KEY FIX)
drop policy if exists marks_teacher_all on marks;
drop policy if exists marks_teacher_select on marks;
drop policy if exists marks_teacher_insert on marks;
drop policy if exists marks_teacher_update on marks;

create policy marks_teacher_all on marks
  for all using (app_user_role() = 'teacher')
  with check (app_user_role() = 'teacher');

-- 6b. Fix users policy for admin user creation (prevents FK/race issues)
drop policy if exists users_admin_all on users;
create policy users_admin_all on users
  for all using (
    auth.uid() in (select id from users where role = 'admin')
  )
  with check (
    auth.uid() in (select id from users where role = 'admin')
  );

-- 6c. Drop FK constraint on users.id -> auth.users.id to prevent race conditions
alter table users drop constraint if exists users_id_fkey;

-- 7. Teacher classes policies
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

-- 8. Drop app_user_class function with CASCADE (will drop dependent policies)
drop function if exists app_user_class() cascade;

-- 9. Recreate app_user_class function
create function app_user_class()
returns uuid
language sql
stable
security definer
as $$
  select class_id from users where id = auth.uid() and role = 'admin'
  union
  select tc.class_id from teacher_classes tc where tc.teacher_id = auth.uid()
  limit 1;
$$;

-- 10. Recreate policies that depend on app_user_class()
create policy classes_teacher_select on classes
  for select using (id = app_user_class());

create policy pupils_teacher_select on pupils
  for select using (
    app_user_role() = 'teacher'
    and exists (
      select 1 from teacher_classes tc
      where tc.teacher_id = auth.uid()
        and tc.class_id = pupils.class_id
    )
  );

create policy pupils_teacher_insert on pupils
  for insert with check (
    app_user_role() = 'teacher'
    and exists (
      select 1 from teacher_classes tc
      where tc.teacher_id = auth.uid()
        and tc.class_id = pupils.class_id
    )
  );

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

-- 11. Update pupil_report_subjects view to include teacher_comment
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

-- 12. Create nursery_color_config if not exists
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