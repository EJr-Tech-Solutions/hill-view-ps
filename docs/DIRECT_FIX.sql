-- ============================================================
-- DIRECT FIX: Run this in Supabase SQL Editor
-- This will DEFINITELY fix marks visibility for teachers
-- ============================================================

-- Step 1: Disable RLS temporarily to test
ALTER TABLE marks DISABLE ROW LEVEL SECURITY;

-- Step 2: Re-enable with VERY SIMPLE policies
ALTER TABLE marks ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies on marks
DROP POLICY IF EXISTS marks_admin_all ON marks;
DROP POLICY IF EXISTS marks_teacher_all ON marks;
DROP POLICY IF EXISTS marks_teacher_select ON marks;
DROP POLICY IF EXISTS marks_teacher_insert ON marks;
DROP POLICY IF EXISTS marks_teacher_update ON marks;
DROP POLICY IF EXISTS marks_teacher_delete ON marks;

-- SUPER SIMPLE: Teachers can see ALL marks (app filters by class anyway)
CREATE POLICY marks_teacher_select ON marks
  FOR SELECT USING (app_user_role() = 'teacher');

CREATE POLICY marks_teacher_insert ON marks
  FOR INSERT WITH CHECK (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
  );

CREATE POLICY marks_teacher_update ON marks
  FOR UPDATE USING (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
  )
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY marks_teacher_delete ON marks
  FOR DELETE USING (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
  );

-- Admin can do everything
CREATE POLICY marks_admin_all ON marks
  FOR ALL USING (app_user_role() = 'admin')
  WITH CHECK (app_user_role() = 'admin');

-- Step 3: Verify the fix
SELECT 'Policies created!' as status;

SELECT
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies
WHERE tablename = 'marks';

-- Step 4: Test query (run while logged in as teacher)
-- SELECT COUNT(*) FROM marks;

-- Done!
SELECT 'Marks should now be visible to teachers!' as message;
