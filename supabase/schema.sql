-- Enable extensions
create extension if not exists "pgcrypto";

-- Core tables
create table if not exists classes (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table if not exists users (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  email text not null unique,
  role text not null check (role in ('admin', 'teacher')),
  class_id uuid references classes (id)
);

-- Teacher can teach multiple classes
create table if not exists teacher_classes (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references users (id) on delete cascade,
  class_id uuid not null references classes (id) on delete cascade,
  unique (teacher_id, class_id)
);

create table if not exists pupils (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  class_id uuid not null references classes (id) on delete cascade,
  avatar text,
  house text,
  paycode text
);

create table if not exists subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  level text not null check (level in ('nursery', 'p1-p3', 'p4-p7')),
  unique (name, level)
);

create table if not exists marks (
  id uuid primary key default gen_random_uuid(),
  pupil_id uuid not null references pupils (id) on delete cascade,
  subject_id uuid not null references subjects (id) on delete cascade,
  score integer not null check (score between 0 and 100),
  teacher_id uuid not null references users (id),
  teacher_comment text,
  unique (pupil_id, subject_id)
);

create index if not exists idx_pupils_class on pupils (class_id);
create index if not exists idx_marks_pupil on marks (pupil_id);
create index if not exists idx_marks_teacher on marks (teacher_id);
create index if not exists idx_teacher_classes_teacher on teacher_classes (teacher_id);
create index if not exists idx_teacher_classes_class on teacher_classes (class_id);

-- Nursery report color customization per teacher
create table if not exists nursery_color_config (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references users (id) on delete cascade,
  level integer not null check (level between 1 and 5),
  color text not null,
  unique (teacher_id, level)
);

create table if not exists term_settings (
  id uuid primary key default gen_random_uuid(),
  term text not null check (term in ('Term 1', 'Term 2', 'Term 3')),
  term_start date not null,
  term_end date not null,
  next_term_start date
);

-- Helper functions for RLS
create or replace function app_user_role()
returns text
language sql
stable
as $$
  select role from users where id = auth.uid();
$$;

create or replace function app_user_class()
returns uuid
language sql
stable
as $$
  select class_id from users where id = auth.uid() and role = 'admin'
  union
  select tc.class_id from teacher_classes tc where tc.teacher_id = auth.uid()
  limit 1;
$$;

-- Auto-attach teacher_id for mark inserts
create or replace function set_mark_teacher()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Preserve explicit teacher_id for seed/admin inserts.
  if new.teacher_id is null then
    new.teacher_id := auth.uid();
  end if;
  return new;
end;
$$;

drop trigger if exists mark_teacher_trigger on marks;
create trigger mark_teacher_trigger
before insert on marks
for each row execute procedure set_mark_teacher();

-- Row Level Security
alter table classes enable row level security;
alter table users enable row level security;
alter table pupils enable row level security;
alter table subjects enable row level security;
alter table marks enable row level security;

-- Classes policies
create policy classes_admin_all on classes
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy classes_teacher_select on classes
  for select using (
    app_user_role() = 'teacher'
    and exists (
      select 1 from teacher_classes tc
      where tc.teacher_id = auth.uid()
        and tc.class_id = id
    )
  );

-- Users policies
create policy users_admin_all on users
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy users_self_select on users
  for select using (id = auth.uid());

-- Pupils policies
create policy pupils_admin_all on pupils
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

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

-- Subjects policies
create policy subjects_read_all on subjects
  for select using (auth.uid() is not null);

-- Teacher Classes policies
alter table teacher_classes enable row level security;

create policy teacher_classes_admin_all on teacher_classes
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy teacher_classes_teacher_select on teacher_classes
  for select using (teacher_id = auth.uid());

create policy teacher_classes_teacher_insert on teacher_classes
  for insert with check (teacher_id = auth.uid());

create policy teacher_classes_teacher_delete on teacher_classes
  for delete using (teacher_id = auth.uid());

-- Nursery Color Config policies
alter table nursery_color_config enable row level security;

create policy nursery_color_config_admin_all on nursery_color_config
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy nursery_color_config_teacher_all on nursery_color_config
  for all using (teacher_id = auth.uid())
  with check (teacher_id = auth.uid());

-- Marks policies
create policy marks_admin_all on marks
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy marks_teacher_all on marks
  for all using (
    app_user_role() = 'teacher'
  );

-- Term Settings policies
alter table term_settings enable row level security;

create policy term_settings_admin_all on term_settings
  for all using (app_user_role() = 'admin')
  with check (app_user_role() = 'admin');

create policy term_settings_read_all on term_settings
  for select using (auth.uid() is not null);

-- Views for analytics and reporting
create or replace view pupil_report_subjects as
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

create or replace view pupil_report_summary as
with totals as (
  select
    p.id as pupil_id,
    p.name as pupil_name,
    c.id as class_id,
    c.name as class_name,
    sum(m.score) as total_score,
    avg(m.score) as average_score
  from pupils p
  join classes c on c.id = p.class_id
  join marks m on m.pupil_id = p.id
  group by p.id, c.id
),
positions as (
  select
    *,
    dense_rank() over (partition by class_id order by average_score desc) as position
  from totals
),
p7_aggregates as (
  select
    p.id as pupil_id,
    s.name as subject_name,
    case
      when m.score between 90 and 100 then 1
      when m.score between 80 and 89 then 2
      when m.score between 70 and 79 then 3
      when m.score between 60 and 69 then 4
      when m.score between 50 and 59 then 5
      when m.score between 40 and 49 then 6
      when m.score between 30 and 39 then 7
      else 8
    end as aggregate
  from pupils p
  join classes c on c.id = p.class_id
  join marks m on m.pupil_id = p.id
  join subjects s on s.id = m.subject_id
  where c.name like 'P7%'
),
final_aggregates as (
  select
    pupil_id,
    sum(aggregate) as total_aggregate
  from (
    select
      pupil_id,
      aggregate,
      row_number() over (partition by pupil_id order by aggregate asc) as rn
    from p7_aggregates
  ) ranked
  where rn <= 4
  group by pupil_id
),
uneb_grades as (
  select
    pupil_id,
    total_aggregate,
    case
      when total_aggregate = 4 then 'D1'
      when total_aggregate between 5 and 6 then 'D2'
      when total_aggregate between 7 and 8 then 'C3'
      when total_aggregate between 9 and 10 then 'C4'
      when total_aggregate between 11 and 12 then 'P5'
      when total_aggregate between 13 and 14 then 'P6'
      when total_aggregate between 15 and 16 then 'P7'
      else 'F9'
    end as uneb_grade
  from final_aggregates
)
select
  positions.pupil_id,
  positions.pupil_name,
  positions.class_id,
  positions.class_name,
  positions.total_score,
  positions.average_score,
  positions.position,
  uneb_grades.uneb_grade
from positions
left join uneb_grades on uneb_grades.pupil_id = positions.pupil_id;

create or replace view class_performance as
select
  summary.class_id,
  summary.class_name,
  avg(summary.average_score) as average_score,
  (select pupil_name from pupil_report_summary s
    where s.class_id = summary.class_id
    order by s.average_score desc limit 1) as best_pupil,
  (select pupil_name from pupil_report_summary s
    where s.class_id = summary.class_id
    order by s.average_score asc limit 1) as weakest_pupil
from pupil_report_summary summary
group by summary.class_id, summary.class_name;

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
    c.id as class_id,
    c.name as class_name,
    count(distinct m.subject_id) as subjects_entered
  from users u
  join classes c on c.id = u.class_id
  left join marks m on m.teacher_id = u.id
  where u.role = 'teacher'
  group by u.id, c.id
)
select
  teacher_marks.teacher_name,
  teacher_marks.class_name,
  teacher_marks.subjects_entered,
  class_subject_counts.subject_count
from teacher_marks
join class_subject_counts on class_subject_counts.class_id = teacher_marks.class_id;
