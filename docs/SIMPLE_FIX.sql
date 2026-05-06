-- ============================================================
-- SIMPLE FIX: Makes marks visible to teachers
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Drop ALL marks policies (clean slate)
DROP POLICY IF EXISTS marks_admin_all ON marks;
DROP POLICY IF EXISTS marks_teacher_all ON marks;
DROP POLICY IF EXISTS marks_teacher_select ON marks;
DROP POLICY IF EXISTS marks_teacher_insert ON marks;
DROP POLICY IF EXISTS marks_teacher_update ON marks;
DROP POLICY IF EXISTS marks_teacher_delete ON marks;

-- 2. Super simple policies - let the APP handle class filtering
-- Teachers can see ALL marks (the JS code already filters by class)
CREATE POLICY marks_teacher_select ON marks
  FOR SELECT USING (app_user_role() = 'teacher');

-- Teachers can only insert/update/delete their OWN marks
CREATE POLICY marks_teacher_insert ON marks
  FOR INSERT WITH CHECK (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
  );

CREATE POLICY marks_teacher_update ON marks
  FOR UPDATE USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY marks_teacher_delete ON marks
  FOR DELETE USING (teacher_id = auth.uid());

-- 3. Admin can do everything
CREATE POLICY marks_admin_all ON marks
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

-- 4. Verify
SELECT 'Done! Teachers can now see marks.' as status;

SELECT policyname, cmd FROM pg_policies WHERE tablename = 'marks';
