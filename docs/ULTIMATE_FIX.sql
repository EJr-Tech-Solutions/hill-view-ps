-- ============================================================
-- ULTIMATE FIX: Clean ALL and recreate
-- Run this ONCE in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- STEP 1: Drop ALL existing policies dynamically
-- ============================================================
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
  END LOOP;
END
$$;

-- Verify all policies dropped
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public') THEN
    RAISE NOTICE 'Some policies still exist!';
  ELSE
    RAISE NOTICE 'All policies dropped successfully!';
  END IF;
END
$$;

-- ============================================================
-- STEP 2: Create helper function (no recursion)
-- ============================================================
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin');
$$;

-- ============================================================
-- STEP 3: Create ALL policies with UNIQUE names
-- ============================================================

-- USERS
CREATE POLICY usr_admin_all ON users
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY usr_self_select ON users
  FOR SELECT USING (id = auth.uid());

-- CLASSES
CREATE POLICY cls_admin_all ON classes
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY cls_teacher_select ON classes
  FOR SELECT USING (
    is_admin() = false
    AND EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = id
    )
  );

-- TEACHER_CLASSES
CREATE POLICY tc_admin_all ON teacher_classes
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY tc_teacher_select ON teacher_classes
  FOR SELECT USING (teacher_id = auth.uid());

CREATE POLICY tc_insert ON teacher_classes
  FOR INSERT WITH CHECK (teacher_id = auth.uid() OR is_admin());

CREATE POLICY tc_teacher_delete ON teacher_classes
  FOR DELETE USING (teacher_id = auth.uid());

-- PUPILS
CREATE POLICY pup_admin_all ON pupils
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY pup_teacher_select ON pupils
  FOR SELECT USING (
    is_admin() = false
    AND EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = pupils.class_id
    )
  );

CREATE POLICY pup_teacher_insert ON pupils
  FOR INSERT WITH CHECK (
    is_admin() = false
    AND EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = class_id
    )
  );

CREATE POLICY pup_teacher_update ON pupils
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = pupils.class_id
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM teacher_classes tc
      WHERE tc.teacher_id = auth.uid()
        AND tc.class_id = class_id
    )
  );

-- SUBJECTS
CREATE POLICY sub_read_all ON subjects
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY sub_admin_all ON subjects
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

-- MARKS (CRITICAL)
CREATE POLICY mrk_admin_all ON marks
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY mrk_teacher_select ON marks
  FOR SELECT USING (
    is_admin() = false
    AND teacher_id = auth.uid()
  );

CREATE POLICY mrk_teacher_insert ON marks
  FOR INSERT WITH CHECK (
    is_admin() = false
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

CREATE POLICY mrk_teacher_update ON marks
  FOR UPDATE USING (
    is_admin() = false
    AND teacher_id = auth.uid()
  ) WITH CHECK (teacher_id = auth.uid());

CREATE POLICY mrk_teacher_delete ON marks
  FOR DELETE USING (
    is_admin() = false
    AND teacher_id = auth.uid()
  );

-- NURSERY_COLOR_CONFIG
CREATE POLICY ncc_admin_all ON nursery_color_config
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY ncc_teacher_all ON nursery_color_config
  FOR ALL USING (teacher_id = auth.uid()) WITH CHECK (teacher_id = auth.uid());

-- TERM_SETTINGS
CREATE POLICY ts_admin_all ON term_settings
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY ts_read_all ON term_settings
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ACADEMIC_TERMS
CREATE POLICY at_admin_all ON academic_terms
  FOR ALL USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY at_teacher_select ON academic_terms
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- STEP 4: Verify policies created
-- ============================================================
SELECT 'Policies created:' as status;
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================================
-- STEP 5: Fix views (if needed)
-- ============================================================
DROP VIEW IF EXISTS teacher_submission_status;
DROP VIEW IF EXISTS class_performance;
DROP VIEW IF EXISTS pupil_report_summary;

-- Recreate pupil_report_summary
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

-- Recreate class_performance
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

-- Recreate teacher_submission_status
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

-- ============================================================
-- DONE!
-- ============================================================
SELECT 'ALL FIXES APPLIED SUCCESSFULLY!' as status;
