-- ============================================================
-- Fix Marks Visibility for Teachers
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Drop ALL existing marks policies (clean slate)
DROP POLICY IF EXISTS marks_teacher_all ON marks;
DROP POLICY IF EXISTS marks_teacher_select ON marks;
DROP POLICY IF EXISTS marks_teacher_insert ON marks;
DROP POLICY IF EXISTS marks_teacher_update ON marks;
DROP POLICY IF EXISTS marks_teacher_delete ON marks;

-- 2. Create simple, working policies for teachers

-- Teacher can SELECT marks for pupils in their assigned classes
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

-- Teacher can INSERT marks (must be for pupils in their classes, and teacher_id = self)
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

-- Teacher can UPDATE own marks for pupils in their classes
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

-- Teacher can DELETE own marks for pupils in their classes
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

-- 3. Verify teacher_classes table has data
SELECT 'teacher_classes entries:' as info, COUNT(*) as count FROM teacher_classes;

-- 4. Verify pupils have class_id set
SELECT 'pupils with class_id:' as info, COUNT(*) as count FROM pupils WHERE class_id IS NOT NULL;

-- 5. Verify marks exist
SELECT 'total marks:' as info, COUNT(*) as count FROM marks;

-- Done!
SELECT 'Marks visibility fix applied! Teachers should now see marks.' as status;
