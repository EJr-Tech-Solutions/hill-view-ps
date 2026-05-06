# Class Sync Fix - How to Apply

## Problem
Classes, pupils, and marks were not syncing properly because:
1. The app was using `users.class_id` (legacy single class) instead of `teacher_classes` table (many-to-many)
2. RLS policies didn't properly filter marks/pupils by teacher's assigned classes
3. The `app_user_class()` function wasn't updated to use `teacher_classes`

## Files Modified

### 1. `/home/elvis/EJr-DEVs/hillview/docs/index.html`
**Change**: Updated `loadAll()` function to properly use `teacher_classes` table
- Now loads teacher's class IDs from `teacher_classes` table first
- Filters pupils query to only fetch pupils from teacher's assigned classes
- Removed client-side filtering of all pupils (more efficient)

### 2. `/home/elvis/EJr-DEVs/hillview/supabase/schema.sql`
**Change**: Fixed typo in subjects table (`'nursery'` was misspelled)
- Line 43: `check (level in ('nursery', 'p1-p3', 'p4-p7'))` (fixed spelling)

### 3. New Migration Files Created

#### `/home/elvis/EJr-DEVs/hillview/supabase/migrations/20260507_fix_class_sync.sql`
This migration:
- Migrates any existing `users.class_id` data to `teacher_classes` table
- Drops and recreates RLS policies for `marks` and `pupils` to properly filter by teacher's classes
- Updates `app_user_class()` function to use `teacher_classes`
- Adds `get_user_class_ids()` helper function
- Updates `teacher_submission_status` and `pupil_report_summary` views

## How to Apply the Fix

### Option 1: Run the Migration (Recommended)
```bash
# In Supabase SQL Editor, run:
/home/elvis/EJr-DEVs/hillview/supabase/migrations/20260507_fix_class_sync.sql
```

### Option 2: Quick Fix (Minimal Changes)
```bash
# In Supabase SQL Editor, run:
/home/elvis/EJr-DEVs/hillview/docs/fix_class_sync.sql
```

### Option 3: Reset and Rebuild (If Database is Empty)
```bash
# 1. In Supabase SQL Editor, run the full schema:
/home/elvis/EJr-DEVs/hillview/supabase/schema.sql

# 2. Then run the update:
/home/elvis/EJr-DEVs/hillview/docs/update_schema.sql
```

## Verification Steps

After applying the fix:

1. **Check teacher_classes table has data**:
   ```sql
   SELECT COUNT(*) FROM teacher_classes;
   ```

2. **Verify a teacher can only see their classes' pupils**:
   - Login as teacher
   - Check that only pupils from assigned classes appear

3. **Test marks entry**:
   - Try to enter marks for a pupil not in teacher's class
   - Should fail with RLS policy violation

## Key Changes Summary

| Before | After |
|--------|-------|
| Used `users.class_id` for teacher's class | Uses `teacher_classes` table |
| Loaded all pupils, then filtered | Loads only pupils from teacher's classes |
| Marks RLS allowed all access for teachers | Marks RLS checks pupil's class via `teacher_classes` |
| `app_user_class()` used legacy field | `app_user_class()` uses `teacher_classes` |

## Next Steps

1. Apply the migration to Supabase
2. Redeploy the app (copy `index.html` to `docs/` if using GitHub Pages)
3. Test with a teacher account to verify they only see their assigned classes
4. Verify marks entry works correctly for assigned classes
