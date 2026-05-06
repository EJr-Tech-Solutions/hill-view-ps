-- ============================================================
-- Quick Fix: Class Sync Issues
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Migrate any legacy class_id data to teacher_classes
INSERT INTO teacher_classes (teacher_id, class_id)
SELECT u.id, u.class_id
FROM users u
WHERE u.class_id IS NOT NULL
  AND u.role = 'teacher'
  AND NOT EXISTS (
    SELECT 1 FROM teacher_classes tc
    WHERE tc.teacher_id = u.id AND tc.class_id = u.class_id
  );

-- 2. Drop the broken marks policy and create proper one
DROP POLICY IF EXISTS marks_teacher_all ON marks;

-- Teachers can only see marks for pupils in their assigned classes
CREATE POLICY marks_teacher_select ON marks
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN teacher_classes tc ON tc.teacher_id = u.id
      JOIN pupils p ON p.class_id = tc.class_id
      WHERE u.id = auth.uid()
        AND u.role = 'teacher'
        AND p.id = marks.pupil_id
    )
  );

-- 3. Fix pupils policy for teachers
DROP POLICY IF EXISTS pupils_teacher_select ON pupils;

CREATE POLICY pupils_teacher_select ON pupils
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN teacher_classes tc ON tc.teacher_id = u.id
      WHERE u.id = auth.uid()
        AND u.role = 'teacher'
        AND tc.class_id = pupils.class_id
    )
  );

-- 4. Verify the fix - check teacher_classes has data
SELECT 'teacher_classes count:' as info, COUNT(*) as count FROM teacher_classes
UNION ALL
SELECT 'users with class_id:' as info, COUNT(*) as count FROM users WHERE class_id IS NOT NULL AND role = 'teacher'
UNION ALL
SELECT 'pupils count:' as info, COUNT(*) as count FROM pupils;

-- Done!
SELECT 'Class sync fix applied!' as status;
