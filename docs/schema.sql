-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.academic_terms (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  term text NOT NULL CHECK (term = ANY (ARRAY['Term 1'::text, 'Term 2'::text, 'Term 3'::text])),
  year integer NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  stream text DEFAULT 'Main'::text,
  is_active boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT academic_terms_pkey PRIMARY KEY (id)
);
CREATE TABLE public.app_settings (
  key text NOT NULL,
  value text NOT NULL,
  CONSTRAINT app_settings_pkey PRIMARY KEY (key)
);
CREATE TABLE public.classes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  CONSTRAINT classes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.marks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  pupil_id uuid NOT NULL,
  subject_id uuid NOT NULL,
  score integer NOT NULL CHECK (score >= 0 AND score <= 100),
  teacher_id uuid NOT NULL,
  teacher_comment text,
  CONSTRAINT marks_pkey PRIMARY KEY (id),
  CONSTRAINT marks_pupil_id_fkey FOREIGN KEY (pupil_id) REFERENCES public.pupils(id),
  CONSTRAINT marks_subject_id_fkey FOREIGN KEY (subject_id) REFERENCES public.subjects(id),
  CONSTRAINT marks_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.users(id)
);
CREATE TABLE public.nursery_color_config (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  level integer NOT NULL CHECK (level >= 1 AND level <= 5),
  color text NOT NULL,
  CONSTRAINT nursery_color_config_pkey PRIMARY KEY (id),
  CONSTRAINT nursery_color_config_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.users(id)
);
CREATE TABLE public.pupils (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  class_id uuid NOT NULL,
  avatar text,
  house text,
  paycode text,
  avatar_url text,
  CONSTRAINT pupils_pkey PRIMARY KEY (id),
  CONSTRAINT pupils_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.classes(id)
);
CREATE TABLE public.subjects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  level text NOT NULL CHECK (level = ANY (ARRAY['nursery'::text, 'p1-p3'::text, 'p4-p7'::text])),
  CONSTRAINT subjects_pkey PRIMARY KEY (id)
);
CREATE TABLE public.teacher_classes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  teacher_id uuid NOT NULL,
  class_id uuid NOT NULL,
  CONSTRAINT teacher_classes_pkey PRIMARY KEY (id),
  CONSTRAINT teacher_classes_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES public.users(id),
  CONSTRAINT teacher_classes_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.classes(id)
);
CREATE TABLE public.term_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  term text NOT NULL CHECK (term = ANY (ARRAY['Term 1'::text, 'Term 2'::text, 'Term 3'::text])),
  term_start date,
  term_end date,
  next_term_start date,
  CONSTRAINT term_settings_pkey PRIMARY KEY (id)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  role text NOT NULL CHECK (role = ANY (ARRAY['admin'::text, 'teacher'::text])),
  class_id uuid,
  avatar_url text,
  contact text,
  avatar text,
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_class_id_fkey FOREIGN KEY (class_id) REFERENCES public.classes(id)
);
