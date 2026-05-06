# Testing Checklist — Hill View School Report System

## Prerequisites

- Supabase project running at `https://gtguutliwmhntuigcqta.supabase.co`
- `supabase/schema.sql` has been run
- `supabase/seed.sql` has been run
- `docs/update_schema.sql` has been run (critical: drops `users_id_fkey`, fixes RLS policies)
- At least one admin user exists in both `auth.users` and `users` table

---

## 1. Database Schema

### 1.1 Tables exist
```sql
select table_name from information_schema.tables where table_schema='public' order by table_name;
-- Expected: classes, marks, nursery_color_config, pupils, subjects, teacher_classes, term_settings, users
```

### 1.2 FK constraints
```sql
select constraint_name, table_name, foreign_table_name from information_schema.referential_constraints where constraint_schema='public';
-- Expected: NO users_id_fkey (intentionally dropped)
-- All other FKs should exist (pupils→classes, marks→pupils/subjects/users, etc.)
```

### 1.3 RLS enabled on all tables
```sql
select tablename, rowsecurity from pg_tables where schemaname='public';
-- All tables should show rowsecurity = true
```

### 1.4 `app_user_class()` has security definer
```sql
select proname, prosecdef from pg_proc where proname='app_user_class';
-- prosecdef should be 't'
```

---

## 2. Authentication

### 2.1 Admin Login
1. Navigate to `docs/index.html` (or deployed URL)
2. Enter admin email + password
3. ✅ Redirects to overview dashboard
4. ✅ Navbar shows admin name and role

### 2.2 Teacher Login (existing teacher with valid users row)
1. Enter teacher email + password
2. ✅ Redirects to marks view (teacher's default)
3. ✅ Navbar shows teacher name
4. ✅ Only teacher's assigned classes appear

### 2.3 Invalid Login
1. Enter wrong email or password
2. ✅ Shows "Wrong email or password." error

### 2.4 Logout
1. Click logout button in navbar
2. ✅ Returns to login screen
3. ✅ State is cleared

---

## 3. Teacher CRUD

### 3.1 Create Teacher
1. Admin → Teachers view → "Create Teacher"
2. Fill: name, email, password, select at least one class
3. Click "Create Teacher"
4. ✅ Success toast: "Teacher created! Password reset email sent to ..."
5. ✅ New teacher appears in the list
6. ✅ Check `users` table — row exists with matching auth ID
7. ✅ Check `teacher_classes` — rows exist for selected classes
8. ✅ Check inbox — password reset email received

### 3.2 Edit Teacher
1. Click edit on existing teacher
2. Change name or class assignment
3. Click "Save Changes"
4. ✅ Success toast
5. ✅ Changes visible in list
6. ✅ `teacher_classes` updated (old rows deleted, new inserted)

### 3.3 Delete Teacher
1. Click delete on a teacher
2. Confirm dialog
3. ✅ Success toast: "Teacher removed."
4. ✅ Teacher removed from list
5. ✅ `users` row deleted
6. ✅ `teacher_classes` rows cascade-deleted
7. ⚠️ Auth user still exists (manual deletion in dashboard)

### 3.4 Create Teacher without class assignment
1. Create teacher, select no classes
2. ✅ No error — teacher created with null class_id
3. ⚠️ Teacher won't see any pupils until assigned classes

---

## 4. Password Reset Flow

### 4.1 Teacher receives reset email
1. Teacher clicks link in email
2. ✅ Redirects to "Set Your Password" form
3. ✅ URL contains auth tokens

### 4.2 Set new password
1. Enter password (min 6 chars) + confirm
2. Click "Set Password"
3. ✅ Success toast: "Password set! You can now sign in."
4. ✅ Signed out automatically
5. ✅ Redirected to login page

### 4.3 Invalid password
1. Enter password < 6 chars
2. ✅ Error: "Password must be at least 6 characters"

### 4.4 Mismatched passwords
1. Enter different values in both fields
2. ✅ Error: "Passwords do not match"

### 4.5 Expired link
1. Use old reset link
2. ✅ Error: "Error setting password. Link may have expired."

---

## 5. Pupil CRUD

### 5.1 View Pupils
1. Admin or teacher → Pupils view
2. ✅ List shows pupils filtered by role:
   - Admin: all pupils
   - Teacher: only pupils in assigned classes

### 5.2 Create Pupil
1. Click "Add Pupil"
2. Enter name, select class
3. ✅ Pupil appears in list

### 5.3 Edit Pupil
1. Click edit on a pupil
2. Change name or class
3. ✅ Changes saved and visible

### 5.4 Delete Pupil
1. Click delete on a pupil
2. Confirm
3. ✅ Pupil removed
4. ⚠️ Associated marks should cascade-delete (verify FK)

### 5.5 Upload Avatar
1. Click avatar upload for a pupil
2. Select image file
3. ✅ Avatar displayed in list
4. ✅ Uploaded to Cloudinary

---

## 6. Marks Entry

### 6.1 Admin Marks Entry
1. Admin → Marks view → select class
2. ✅ Table shows all pupils × subjects for class level
3. ✅ Enter scores, save
4. ✅ "Successfully saved X mark(s)!" toast
5. ✅ Database updated

### 6.2 Teacher Marks Entry
1. Teacher → Marks view
2. ✅ Only teacher's assigned classes shown
3. ✅ Enter scores, save
4. ✅ `teacher_id` auto-filled by trigger
5. ✅ Success toast

### 6.3 Invalid Score
1. Enter score < 0 or > 100
2. ✅ Database constraint rejects (check error handling)

### 6.4 Auto Comments
1. Enter marks that produce an average
2. ✅ Comments auto-generated based on score bands

### 6.5 Unsaved Changes Warning
1. Edit marks without saving
2. ✅ Unsaved indicator visible

---

## 7. Reports

### 7.1 Primary School Report
1. Admin/teacher → Reports view
2. Select a P1-P7 pupil
3. ✅ Report shows:
   - Pupil name, class, avatar
   - All subjects with scores
   - Grades (D1-D2, C3-C4, P5-P7, F9)
   - Total score, average, position
   - UNEB grade (for P7)
   - Term info

### 7.2 Nursery Report
1. Select a KG/Nursery pupil
2. ✅ Report shows simplified nursery format
3. ✅ Color customization applies if configured

### 7.3 Print Report
1. Click print on a report
2. ✅ Opens printable HTML in new window
3. ✅ Browser print dialog opens (Ctrl/Cmd+P)

### 7.4 Generate All Reports
1. Click "Generate All" (admin only)
2. ✅ Reports generated for all pupils in selected class

---

## 8. Admin Dashboard (Overview)

### 8.1 Class Performance
1. Admin → Overview
2. ✅ Chart shows class averages
3. ✅ Best and weakest pupils listed

### 8.2 Teacher Submission Status
1. ✅ Table shows each teacher's mark-entry progress
2. ✅ Subjects entered vs total subjects

---

## 9. Settings

### 9.1 Term Settings
1. Admin → Settings
2. ✅ Current term settings displayed
3. ✅ Can edit term name, dates
4. ✅ Save persists to database

---

## 10. Realtime Updates

### 10.1 Pupil Updates
1. Open app in two browser windows
2. Add/edit a pupil in window 1
3. ✅ Window 2 reflects the change (polling every 8s)

### 10.2 Teacher Updates
1. Add/edit a teacher in window 1
2. ✅ Window 2 reflects the change

---

## Known Issues & Limitations

1. **No FK on users.id** — orphaned `users` rows are possible if auth user is deleted
2. **Session invalidation** — `resetPasswordForEmail` can invalidate the admin's session if called during their active session
3. **Single-file SPA** — not modular, harder to maintain
4. **No env injection** — Supabase URL/key hardcoded in template
5. **Polling-based realtime** — not true WebSocket subscriptions, 8-second delay
6. **Duplicate rows** — if `handle_new_user` trigger was ever installed AND direct insert is used, duplicate `users` rows can exist
7. **Teacher classes insert errors silently swallowed** — `console.warn` only, no user feedback

---

## SQL Verification Queries

Run these to verify the system state:

```sql
-- Check for duplicate users rows
select id, email, count(*) from users group by id, email having count(*) > 1;

-- Check for orphaned users (no matching auth user)
select id, email from users where id not in (select id from auth.users);

-- Check for users without auth accounts (should be empty)
select u.id, u.email from users u left join auth.users au on u.id = au.id where au.id is null;

-- Verify teacher_classes integrity
select tc.id, tc.teacher_id, tc.class_id
from teacher_classes tc
left join users u on u.id = tc.teacher_id
where u.id is null;

-- List all users with roles
select u.id, u.name, u.email, u.role, u.class_id,
       array_agg(tc.class_id) filter (where tc.class_id is not null) as assigned_classes
from users u
left join teacher_classes tc on tc.teacher_id = u.id
group by u.id, u.name, u.email, u.role, u.class_id;

-- Check RLS policies on users table
select policyname, cmd, qual, with_check from pg_policies where tablename = 'users';
```
