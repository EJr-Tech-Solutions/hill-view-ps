# School Report Management System

A single-page application for nursery and primary school report management, served as static HTML via GitHub Pages with Supabase for backend (Postgres + Auth + RLS).

## Stack
- Static HTML/CSS/JS SPA (no framework)
- Supabase JS SDK (browser client)
- Supabase: Postgres, Auth, Row Level Security, Realtime
- Cloudinary (avatar uploads)
- GitHub Pages (hosting from `docs/`)

## Key Behaviors
- Roles (`admin` / `teacher`) are stored in the `users` table.
- Teachers can only access pupils in classes assigned via `teacher_classes`.
- Admins have full access to all tables.
- Marks are entered raw; averages, positions, and UNEB grading are computed automatically in SQL views.
- Report cards render as printable HTML.

## Architecture
- `docs/index.template.html` — single-file SPA (source of truth)
- `docs/index.html` — built copy deployed to GitHub Pages
- `supabase/schema.sql` — canonical database schema
- `supabase/seed.sql` — seed data (classes, subjects)
- `docs/update_schema.sql` — migration script for schema updates

## Setup

### 1. Create a Supabase project

### 2. Run the database schema

Run these in the Supabase SQL Editor:

```sql
supabase/schema.sql
supabase/seed.sql
```

### 3. Configure environment

Edit `docs/index.template.html` directly — the Supabase URL and anon key are configured inline near the top of the file:

```javascript
const db = supabase.createClient('YOUR_SUPABASE_URL', 'YOUR_SUPABASE_ANON_KEY');
```

### 4. Deploy

```bash
npm run build:docs
git add docs/index.html
git commit -m "Deploy"
git push
```

The `docs/index.html` is served by GitHub Pages.

## User Management

### Creating Teachers (Admin Flow)

1. Admin logs in and opens the Teachers section.
2. Click "Create Teacher" → fill in name, email, password, and assign classes.
3. On save:
   - `auth.signUp()` creates the auth user.
   - A direct insert adds a row to the `users` table.
   - Rows are inserted into `teacher_classes` for each assigned class.
   - A password reset email is sent so the teacher can set their own password.

### Teacher Login

1. Teacher receives the password reset email and clicks the link.
2. They are redirected to the "Set Your Password" form.
3. After setting a password, they are redirected to the login page.
4. Login uses email + the password they set.

### Important

- `users.id` must match `auth.users.id` (handled automatically by the teacher creation flow).
- The `users_id_fkey` foreign key constraint between `users.id` and `auth.users.id` has been **dropped** to avoid FK/race-condition issues during user creation.

## Routes (Hash-Based)

The SPA uses hash routing:

| Hash | Screen |
|------|--------|
| `#` (empty) | Login or dashboard (if session exists) |
| `#reset-password` | Password set/reset form |

## Security

Row Level Security is enabled on all core tables:

- `classes` — admins: all; teachers: only assigned classes
- `users` — admins: all; users: own row only
- `pupils` — admins: all; teachers: only assigned classes
- `marks` — admins: all; teachers: read/write for their classes
- `teacher_classes` — admins: all; teachers: own assignments

See `supabase/schema.sql` and `docs/update_schema.sql` for full policy definitions.

## Reporting

Report cards render as printable HTML and can be exported as PDF via the browser print dialog (Ctrl/Cmd+P).

## Development

```bash
# Rebuild docs/index.html from template
npm run build:docs
```

Edit `docs/index.template.html` directly. There are no framework dependencies — all logic is vanilla JS in a single file.
