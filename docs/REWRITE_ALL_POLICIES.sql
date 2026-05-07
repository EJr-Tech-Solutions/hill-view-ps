-- ============================================================
-- COMPLETE RLS POLICY REWRITE
-- Run this in Supabase SQL Editor
-- This drops ALL existing policies and creates working ones
-- ============================================================

-- ============================================================
-- STEP 1: Drop ALL existing policies on ALL tables
-- ============================================================

-- Users policies
DROP POLICY IF EXISTS users_admin_all ON users;
DROP POLICY IF EXISTS users_self_select ON users;

-- Classes policies
DROP POLICY IF EXISTS classes_admin_all ON classes;
DROP POLICY IF EXISTS classes_teacher_select ON classes;

-- Teacher_classes policies
DROP POLICY IF EXISTS teacher_classes_admin_all ON teacher_classes;
DROP POLICY IF EXISTS teacher_classes_teacher_select ON teacher_classes;
DROP POLICY IF EXISTS teacher_classes_teacher_insert ON teacher_classes;
DROP POLICY IF EXISTS teacher_classes_teacher_delete ON teacher_classes;

-- Pupils policies
DROP POLICY IF EXISTS pupils_admin_all ON pupils;
DROP POLICY IF EXISTS pupils_teacher_select ON pupils;
DROP POLICY IF EXISTS pupils_teacher_insert ON pupils;
DROP POLICY IF EXISTS pupils_teacher_update ON pupils;

-- Subjects policies
DROP POLICY IF EXISTS subjects_read_all ON subjects;
DROP POLICY IF EXISTS subjects_admin_all ON subjects;

-- Marks policies
DROP POLICY IF EXISTS marks_admin_all ON marks;
DROP POLICY IF EXISTS marks_teacher_all ON marks;
DROP POLICY IF EXISTS marks_teacher_select ON marks;
DROP POLICY IF EXISTS marks_teacher_insert ON marks;
DROP POLICY IF EXISTS marks_teacher_update ON marks;
DROP POLICY IF EXISTS marks_teacher_delete ON marks;
DROP POLICY IF EXISTS marks_select ON marks;
DROP POLICY IF EXISTS marks_insert ON marks;
DROP POLICY IF EXISTS marks_update ON marks;
DROP POLICY IF EXISTS marks_delete ON marks;
DROP POLICY IF EXISTS marks_modify ON marks;

-- Nursery color config policies
DROP POLICY IF EXISTS nursery_color_config_admin_all ON nursery_color_config;
DROP POLICY IF EXISTS nursery_color_config_teacher_all ON nursery_color_config;

-- Term settings policies
DROP POLICY IF EXISTS term_settings_admin_all ON term_settings;
DROP POLICY IF EXISTS term_settings_read_all ON term_settings;

-- Academic terms policies
DROP POLICY IF EXISTS academic_terms_admin_all ON academic_terms;
DROP POLICY IF EXISTS academic_terms_teacher_select ON academic_terms;

-- ============================================================
-- STEP 2: Create SIMPLE, WORKING policies
-- ============================================================

-- ============================================
-- USERS table
-- ============================================
CREATE POLICY users_admin_all ON users
  FOR ALL USING (
    auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  )
  WITH CHECK (
    auth.uid() IN (SELECT id FROM users WHERE role = 'admin')
  );

CREATE POLICY users_self_select ON users
  FOR SELECT USING (id = auth.uid());

-- ============================================
-- CLASSES table
-- ============================================
CREATE POLICY classes_admin_all ON classes
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

CREATE POLICY classes_teacher_select ON classes
  FOR SELECT USING (
    app_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = id
    )
  );

-- ============================================
-- TEACHER_CLASSES table
-- ============================================
CREATE POLICY teacher_classes_admin_all ON teacher_classes
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

CREATE POLICY teacher_classes_teacher_select ON teacher_classes
  FOR SELECT USING (teacher_id = auth.uid());

-- Allow teachers to insert (for self-registration) AND admin to insert (for creating teachers)
CREATE POLICY teacher_classes_insert ON teacher_classes
  FOR INSERT WITH CHECK (
    teacher_id = auth.uid()  -- Teacher inserting own record
    OR app_user_role() = 'admin'  -- Admin inserting for teachers
  );

CREATE POLICY teacher_classes_teacher_delete ON teacher_classes
  FOR DELETE USING (teacher_id = auth.uid());

-- ============================================
-- PUPILS table
-- ============================================
CREATE POLICY pupils_admin_all ON pupils
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

CREATE POLICY pupils_teacher_select ON pupils
  FOR SELECT USING (
    app_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = pupils.class_id
    )
  );

CREATE POLICY pupils_teacher_insert ON pupils
  FOR INSERT WITH CHECK (
    app_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = class_id
    )
  );

CREATE POLICY pupils_teacher_update ON pupils
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = pupils.class_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = class_id
    )
  );

-- ============================================
-- SUBJECTS table (read-only for all authenticated users)
-- ============================================
CREATE POLICY subjects_read_all ON subjects
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY subjects_admin_all ON subjects
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

-- ============================================
-- MARKS table - THE CRITICAL ONE
-- ============================================
CREATE POLICY marks_admin_all ON marks
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

-- Teachers can SELECT marks for pupils in their assigned classes
CREATE POLICY marks_teacher_select ON marks
  FOR SELECT USING (
    app_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM pupils p
      WHERE p.id = marks.pupil_id
        AND EXISTS (
          SELECT 1 FROM teacher_classes tc
          WHERE tc.teacher_id = auth.uid()
            AND tc.class_id = p.class_id
        )
    )
  );

-- Teachers can INSERT marks (must be their own and for pupils in their classes)
CREATE POLICY marks_teacher_insert ON marks
  FOR INSERT WITH CHECK (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM pupils p
      WHERE p.id = pupil_id
        AND EXISTS (
          SELECT 1 FROM teacher_classes tc
          WHERE tc.teacher_id = auth.uid()
            AND tc.class_id = p.class_id
        )
    )
  );

-- Teachers can UPDATE own marks for pupils in their classes
CREATE POLICY marks_teacher_update ON marks
  FOR UPDATE USING (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM pupils p
      WHERE p.id = marks.pupil_id
        AND EXISTS (
          SELECT 1 FROM teacher_classes tc
          WHERE tc.teacher_id = auth.uid()
            AND tc.class_id = p.class_id
        )
    )
  )
  WITH CHECK (teacher_id = auth.uid());

-- Teachers can DELETE own marks
CREATE POLICY marks_teacher_delete ON marks
  FOR DELETE USING (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM pupils p
      WHERE p.id = marks.pupil_id
        AND EXISTS (
          SELECT 1 FROM teacher_classes tc
          WHERE tc.teacher_id = auth.uid()
            AND tc.class_id = p.class_id
        )
    )
  );

-- ============================================
-- NURSERY_COLOR_CONFIG table
-- ============================================
CREATE POLICY nursery_color_config_admin_all ON nursery_color_config
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

CREATE POLICY nursery_color_config_teacher_all ON nursery_color_config
  FOR ALL USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

-- ============================================
-- TERM_SETTINGS table
-- ============================================
CREATE POLICY term_settings_admin_all ON term_settings
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

CREATE POLICY term_settings_read_all ON term_settings
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================
-- ACADEMIC_TERMS table
-- ============================================
CREATE POLICY academic_terms_admin_all ON academic_terms
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

CREATE POLICY academic_terms_teacher_select ON academic_terms
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- STEP 3: Verify all policies created
-- ============================================================
SELECT
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================
-- DONE!
-- ============================================================
SELECT 'ALL POLICIES REWRITTEN SUCCESSFULLY!' as status;
