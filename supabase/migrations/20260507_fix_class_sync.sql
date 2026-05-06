-- ============================================================
-- Migration: Fix Class Sync Issues
-- Date: 2026-05-07
-- ============================================================
-- This migration fixes the class syncing issues between:
-- - users (legacy class_id column)
-- - teacher_classes (proper many-to-many)
-- - pupils (class_id FK)
-- - marks (linked via pupils)
-- ============================================================

-- 1. First, migrate any data from users.class_id to teacher_classes
INSERT INTO teacher_classes (teacher_id, class_id)
SELECT u.id, u.class_id
FROM users u
WHERE u.class_id IS NOT NULL
  AND u.role = 'teacher'
  AND NOT EXISTS (
    SELECT 1 FROM teacher_classes tc
    WHERE tc.teacher_id = u.id AND tc.class_id = u.class_id
  );

-- 2. Drop existing problematic RLS policies
DROP POLICY IF EXISTS marks_teacher_all ON marks;
DROP POLICY IF EXISTS marks_teacher_select ON marks;
DROP POLICY IF EXISTS marks_teacher_insert ON marks;
DROP POLICY IF EXISTS marks_teacher_update ON marks;
DROP POLICY IF EXISTS marks_teacher_delete ON marks;

DROP POLICY IF EXISTS pupils_teacher_select ON pupils;
DROP POLICY IF EXISTS pupils_teacher_insert ON pupils;
DROP POLICY IF EXISTS pupils_teacher_update ON pupils;

DROP POLICY IF EXISTS classes_teacher_select ON classes;

-- 3. Create proper RLS policies for marks (teacher can only access their classes' marks)
DROP POLICY IF EXISTS marks_teacher_all ON marks;
DROP POLICY IF EXISTS marks_teacher_select ON marks;
DROP POLICY IF EXISTS marks_teacher_insert ON marks;
DROP POLICY IF EXISTS marks_teacher_update ON marks;
DROP POLICY IF EXISTS marks_teacher_delete ON marks;

-- Simplified marks policy: teacher can see marks for pupils in their assigned classes
CREATE POLICY marks_teacher_select ON marks
  FOR SELECT USING (
    app_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1
      FROM pupils p
      WHERE p.id = marks.pupil_id
        AND EXISTS (
          SELECT 1
          FROM teacher_classes tc
          WHERE tc.teacher_id = auth.uid()
            AND tc.class_id = p.class_id
        )
    )
  );

CREATE POLICY marks_teacher_insert ON marks
  FOR INSERT WITH CHECK (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM pupils p
      WHERE p.id = pupil_id
        AND EXISTS (
          SELECT 1
          FROM teacher_classes tc
          WHERE tc.teacher_id = auth.uid()
            AND tc.class_id = p.class_id
        )
    )
  );

CREATE POLICY marks_teacher_update ON marks
  FOR UPDATE USING (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM pupils p
      WHERE p.id = marks.pupil_id
        AND EXISTS (
          SELECT 1
          FROM teacher_classes tc
          WHERE tc.teacher_id = auth.uid()
            AND tc.class_id = p.class_id
        )
    )
  )
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY marks_teacher_delete ON marks
  FOR DELETE USING (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM pupils p
      WHERE p.id = marks.pupil_id
        AND EXISTS (
          SELECT 1
          FROM teacher_classes tc
          WHERE tc.teacher_id = auth.uid()
            AND tc.class_id = p.class_id
        )
    )
  );

CREATE POLICY marks_teacher_insert ON marks
  FOR INSERT WITH CHECK (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM pupils p
      JOIN teacher_classes tc ON tc.class_id = p.class_id
      WHERE p.id = pupil_id
        AND tc.teacher_id = auth.uid()
    )
  );

CREATE POLICY marks_teacher_update ON marks
  FOR UPDATE USING (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM pupils p
      JOIN teacher_classes tc ON tc.class_id = p.class_id
      WHERE p.id = marks.pupil_id
        AND tc.teacher_id = auth.uid()
    )
  )
  WITH CHECK (teacher_id = auth.uid());

CREATE POLICY marks_teacher_delete ON marks
  FOR DELETE USING (
    app_user_role() = 'teacher'
    AND teacher_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM pupils p
      JOIN teacher_classes tc ON tc.class_id = p.class_id
      WHERE p.id = marks.pupil_id
        AND tc.teacher_id = auth.uid()
    )
  );

-- 4. Create proper RLS policies for pupils (teacher can only access their classes' pupils)
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
    app_user_role() = 'teacher'
    AND EXISTS (
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

-- 5. Create proper RLS policy for classes (teacher can only see their assigned classes)
CREATE POLICY classes_teacher_select ON classes
  FOR SELECT USING (
    app_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = id
    )
  );

-- 6. Update the app_user_class() function to use teacher_classes
DROP FUNCTION IF EXISTS app_user_class() CASCADE;

CREATE OR REPLACE FUNCTION app_user_class()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- Get class from teacher_classes for teachers
  SELECT tc.class_id
  FROM teacher_classes tc
  WHERE tc.teacher_id = auth.uid()
  LIMIT 1;
$$;

-- 7. Create a helper function to get ALL classes for a user
CREATE OR REPLACE FUNCTION get_user_class_ids()
RETURNS TABLE(class_id uuid)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- For teachers: return all assigned classes
  SELECT tc.class_id
  FROM teacher_classes tc
  WHERE tc.teacher_id = auth.uid()

  UNION

  -- For admin: return all classes (or NULL if no assignment)
  SELECT c.id
  FROM classes c
  WHERE EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  );
$$;

-- 8. Update teacher_submission_status view to properly use teacher_classes
DROP VIEW IF EXISTS teacher_submission_status;

CREATE OR REPLACE VIEW teacher_submission_status AS
WITH class_subject_counts AS (
  SELECT
    c.id AS class_id,
    COUNT(s.id) AS subject_count
  FROM classes c
  JOIN subjects s ON (
    (c.name LIKE 'KG%' AND s.level = 'nursery')
    OR ((c.name LIKE 'P1%' OR c.name LIKE 'P2%' OR c.name LIKE 'P3%') AND s.level = 'p1-p3')
    OR ((c.name LIKE 'P4%' OR c.name LIKE 'P5%' OR c.name LIKE 'P6%' OR c.name LIKE 'P7%') AND s.level = 'p4-p7')
  )
  GROUP BY c.id
),
teacher_marks AS (
  SELECT
    u.id AS teacher_id,
    u.name AS teacher_name,
    tc.class_id,
    c.name AS class_name,
    COUNT(DISTINCT m.subject_id) AS subjects_entered
  FROM users u
  JOIN teacher_classes tc ON tc.teacher_id = u.id
  JOIN classes c ON c.id = tc.class_id
  LEFT JOIN marks m ON m.teacher_id = u.id AND m.pupil_id IN (
    SELECT p.id FROM pupils p WHERE p.class_id = tc.class_id
  )
  WHERE u.role = 'teacher'
  GROUP BY u.id, u.name, tc.class_id, c.name

  UNION

  SELECT
    u.id AS teacher_id,
    u.name AS teacher_name,
    tc.class_id,
    c.name AS class_name,
    0 AS subjects_entered
  FROM users u
  JOIN teacher_classes tc ON tc.teacher_id = u.id
  JOIN classes c ON c.id = tc.class_id
  WHERE u.role = 'teacher'
    AND NOT EXISTS (
      SELECT 1 FROM marks m
      JOIN pupils p ON p.id = m.pupil_id
      WHERE m.teacher_id = u.id AND p.class_id = tc.class_id
    )
)
SELECT
  teacher_marks.teacher_name,
  teacher_marks.class_name,
  MAX(teacher_marks.subjects_entered) AS subjects_entered,
  class_subject_counts.subject_count
FROM teacher_marks
JOIN class_subject_counts ON class_subject_counts.class_id = teacher_marks.class_id
GROUP BY teacher_marks.teacher_name, teacher_marks.class_name, class_subject_counts.subject_count;

-- 9. Update pupil_report_summary view to be consistent
-- (This view is used for reports - ensure it works with proper joins)
-- First drop dependent views
DROP VIEW IF EXISTS class_performance;
DROP VIEW IF EXISTS pupil_report_summary;

CREATE OR REPLACE VIEW pupil_report_summary AS
WITH totals AS (
  SELECT
    p.id AS pupil_id,
    p.name AS pupil_name,
    c.id AS class_id,
    c.name AS class_name,
    SUM(m.score) AS total_score,
    AVG(m.score) AS average_score
  FROM pupils p
  JOIN classes c ON c.id = p.class_id
  JOIN marks m ON m.pupil_id = p.id
  GROUP BY p.id, c.id
),
positions AS (
  SELECT
    *,
    DENSE_RANK() OVER (PARTITION BY class_id ORDER BY average_score DESC) AS position
  FROM totals
),
p7_aggregates AS (
  SELECT
    p.id AS pupil_id,
    s.name AS subject_name,
    CASE
      WHEN m.score BETWEEN 90 AND 100 THEN 1
      WHEN m.score BETWEEN 80 AND 89 THEN 2
      WHEN m.score BETWEEN 70 AND 79 THEN 3
      WHEN m.score BETWEEN 60 AND 69 THEN 4
      WHEN m.score BETWEEN 50 AND 59 THEN 5
      WHEN m.score BETWEEN 40 AND 49 THEN 6
      WHEN m.score BETWEEN 30 AND 39 THEN 7
      ELSE 8
    END AS aggregate
  FROM pupils p
  JOIN classes c ON c.id = p.class_id
  JOIN marks m ON m.pupil_id = p.id
  JOIN subjects s ON s.id = m.subject_id
  WHERE c.name LIKE 'P7%'
),
final_aggregates AS (
  SELECT
    pupil_id,
    SUM(aggregate) AS total_aggregate
  FROM (
    SELECT
      pupil_id,
      aggregate,
      ROW_NUMBER() OVER (PARTITION BY pupil_id ORDER BY aggregate ASC) AS rn
    FROM p7_aggregates
  ) ranked
  WHERE rn <= 4
  GROUP BY pupil_id
),
uneb_grades AS (
  SELECT
    pupil_id,
    total_aggregate,
    CASE
      WHEN total_aggregate = 4 THEN 'D1'
      WHEN total_aggregate BETWEEN 5 AND 6 THEN 'D2'
      WHEN total_aggregate BETWEEN 7 AND 8 THEN 'C3'
      WHEN total_aggregate BETWEEN 9 AND 10 THEN 'C4'
      WHEN total_aggregate BETWEEN 11 AND 12 THEN 'P5'
      WHEN total_aggregate BETWEEN 13 AND 14 THEN 'P6'
      WHEN total_aggregate BETWEEN 15 AND 16 THEN 'P7'
      ELSE 'F9'
    END AS uneb_grade
  FROM final_aggregates
)
SELECT
  positions.pupil_id,
  positions.pupil_name,
  positions.class_id,
  positions.class_name,
  positions.total_score,
  positions.average_score,
  positions.position,
  uneb_grades.uneb_grade
FROM positions
LEFT JOIN uneb_grades ON uneb_grades.pupil_id = positions.pupil_id;

-- 10. Recreate class_performance view (depends on pupil_report_summary)
CREATE OR REPLACE VIEW class_performance AS
SELECT
  summary.class_id,
  summary.class_name,
  AVG(summary.average_score) AS average_score,
  (SELECT pupil_name FROM pupil_report_summary s
    WHERE s.class_id = summary.class_id
    ORDER BY s.average_score DESC LIMIT 1) AS best_pupil,
  (SELECT pupil_name FROM pupil_report_summary s
    WHERE s.class_id = summary.class_id
    ORDER BY s.average_score ASC LIMIT 1) AS weakest_pupil
FROM pupil_report_summary summary
GROUP BY summary.class_id, summary.class_name;

-- Done!
SELECT 'Class sync migration completed successfully!' AS status;
