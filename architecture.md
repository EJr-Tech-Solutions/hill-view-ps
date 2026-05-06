# Architecture — School Report Management System

## Overview

A static single-page application served from GitHub Pages (`docs/`) that connects directly to Supabase for database, authentication, and realtime functionality.

```
┌─────────────────────────┐
│    GitHub Pages          │
│  (docs/index.html)       │
│                          │
│  ┌───────────────────┐   │
│  │  SPA (Vanilla JS)  │   │
│  │  - Router (hash)   │   │
│  │  - CRUD UI         │   │
│  │  - Report Gen      │   │
│  └─────────┬─────────┘   │
└────────────┼─────────────┘
             │ HTTPS
             ▼
┌─────────────────────────┐
│      Supabase            │
│  ┌─────────┐ ┌────────┐ │
│  │ Postgres │ │  Auth  │ │
│  │ (tables  │ │ (users │ │
│  │  + RLS)  │ │  JWT)  │ │
│  └─────────┘ └────────┘ │
│  ┌────────────────────┐ │
│  │     Realtime       │ │
│  │  (subscriptions)   │ │
│  └────────────────────┘ │
└─────────────────────────┘
```

## Components

### Client (`docs/index.template.html`)

Single HTML file (~3200 lines) containing:

- **State management** — global `S` object with reactive rendering.
- **Router** — hash-based (`#reset-password`, `#`).
- **Views** — login, teacher CRUD, pupil CRUD, marks entry, report generation.
- **Supabase client** — initialized with anon key for browser use.
- **Realtime** — polling-based subscriptions for live data.
- **Cloudinary** — avatar upload via direct browser upload.

### Database Schema (`supabase/schema.sql`)

#### Tables
| Table | Purpose |
|-------|---------|
| `users` | Auth profiles with role |
| `classes` | Class definitions |
| `teacher_classes` | Many-to-many teacher-class assignments |
| `pupils` | Student records |
| `subjects` | Subject definitions with level |
| `marks` | Score records |
| `term_settings` | Academic term configuration |
| `nursery_color_config` | Per-teacher nursery report colors |

#### Views
| View | Purpose |
|------|---------|
| `pupil_report_subjects` | Join pupil + marks + subjects for report cards |
| `pupil_report_summary` | Aggregates with positions and UNEB grading |
| `class_performance` | Class-level analytics |
| `teacher_submission_status` | Teacher mark-entry completion tracking |

#### Functions
| Function | Purpose |
|----------|---------|
| `app_user_role()` | Returns role of authenticated user |
| `app_user_class()` | Returns class of authenticated user (with `security definer`) |
| `set_mark_teacher()` | Trigger: auto-fills `teacher_id` on mark insert |

### Migrations (`docs/update_schema.sql`)

Handles incremental schema updates:
- Adding `teacher_classes` table
- Updating RLS policies
- Recreating `app_user_class()` with `security definer`
- Adding `nursery_color_config` table

## Security Architecture

### Row Level Security

Every table has RLS enabled. Policies are role-aware:

```
Admin (users.role = 'admin')
  → all tables, all operations

Teacher (users.role = 'teacher')
  → SELECT classes WHERE class_id matches teacher_classes
  → SELECT/INSERT/UPDATE pupils WHERE class matches assignments
  → all marks for own class
  → own teacher_classes assignments
```

### Key Policy: `users_admin_all`

```sql
create policy users_admin_all on users
  for all using (
    auth.uid() in (select id from users where role = 'admin')
  )
  with check (
    auth.uid() in (select id from users where role = 'admin')
  );
```

This ensures only existing admins can create new users. The subquery works because the checking admin already has a row in `users`.

### Security Definer Functions

`app_user_class()` and `set_mark_teacher()` use `security definer` to bypass RLS during policy evaluation and trigger execution.

## User Creation Flow

```
Admin creates teacher
  │
  ├─ auth.signUp() ──→ creates auth.users row
  │                      (user not yet in public.users)
  │
  ├─ INSERT into public.users
  │    (id = auth.user.id, name, email, role, class_id)
  │
  ├─ INSERT into teacher_classes (N rows)
  │
  ├─ auth.resetPasswordForEmail()
  │    └─ sends email with link → /#reset-password
  │
  └─ done

Teacher receives email
  │
  ├─ clicks link → /#reset-password?access_token=...
  │
  ├─ setSession(access_token, refresh_token)
  │
  ├─ UI shows "Set Your Password" form
  │
  ├─ auth.updateUser({ password })
  │
  ├─ signOut()
  │
  └─ redirect to login
```

## Deployment

```
Source: docs/index.template.html
Build:  npm run build:docs → copies to docs/index.html
Host:   GitHub Pages (docs/ branch or folder)
```

The build step is a simple copy. The template contains the Supabase URL and anon key inline (not injected from env at build time).

## Limitations

- **Single file** — all JS/CSS/HTML in one file, not modular.
- **No SSR** — pure client-side rendering, no server-side code.
- **No env injection** — Supabase credentials are hardcoded in the template.
- **FK dropped** — `users.id` no longer has a foreign key to `auth.users.id`, so orphaned rows are possible.
- **Session race conditions** — `resetPasswordForEmail` can invalidate the admin's session if called in the same context.
