# Specification — School Report Management System

## Overview

A web-based system for managing school report cards for nursery and primary students. The system supports two roles:

- **Admin** — full access: manage teachers, pupils, classes, subjects, marks, and generate reports.
- **Teacher** — restricted to assigned classes: enter marks, view pupils, generate class reports.

## Users & Authentication

### Auth Provider
Supabase Auth (email + password).

### User Types
| Type | Description |
|------|-------------|
| Admin | Full system access. Can create/edit/delete teachers and pupils, manage classes/subjects, view all data. |
| Teacher | Limited to assigned classes. Can enter/update marks, view pupils, generate reports for their classes. |

### User Creation Flow (Admin creates Teacher)

1. Admin fills teacher form (name, email, temporary password, assigned classes).
2. System calls `auth.signUp({ email, password, options: { data: { name, role } } })`.
3. System directly inserts a row into `users` with `id = auth.user.id`.
4. System inserts rows into `teacher_classes` for each assigned class.
5. System sends a password reset email (`resetPasswordForEmail`) with redirect to `#reset-password`.
6. Teacher receives the email, clicks the link, sets their own password, and logs in.

### Password Reset Flow

1. User receives reset email and clicks the link.
2. Link redirects to `/#reset-password` with auth tokens.
3. System exchanges tokens for a session.
4. User enters a new password (min 6 chars, confirmed).
5. System calls `auth.updateUser({ password })`.
6. User is signed out and redirected to login.

## Data Model

### `users`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key, matches auth.users.id |
| name | text | Full name |
| email | text | Unique email address |
| role | text | `'admin'` or `'teacher'` |
| class_id | uuid | Legacy: single class reference (nullable) |

### `classes`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| name | text | Unique class name (e.g., "P1 Red") |

### `teacher_classes`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| teacher_id | uuid | FK → users.id |
| class_id | uuid | FK → classes.id |
| unique(teacher_id, class_id) | — | Prevents duplicate assignments |

### `pupils`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| name | text | Pupil name |
| class_id | uuid | FK → classes.id |
| avatar | text | Optional image URL |
| house | text | House assignment |
| paycode | text | Payment code |

### `subjects`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| name | text | Subject name |
| level | text | `'nursery'`, `'p1-p3'`, or `'p4-p7'` |
| unique(name, level) | — | |

### `marks`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| pupil_id | uuid | FK → pupils.id |
| subject_id | uuid | FK → subjects.id |
| score | integer | 0–100 |
| teacher_id | uuid | FK → users.id |
| teacher_comment | text | Auto-generated or manual comment |
| unique(pupil_id, subject_id) | — | One mark per pupil per subject |

### `term_settings`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| term | text | `'Term 1'`, `'Term 2'`, `'Term 3'` |
| term_start | date | Term start date |
| term_end | date | Term end date |
| next_term_start | date | Optional |

### `nursery_color_config`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| teacher_id | uuid | FK → users.id |
| level | integer | 1–5 (nursery report levels) |
| color | text | Hex color for that level |
| unique(teacher_id, level) | — | |

## Functional Requirements

### Admin
- [x] View all classes, pupils, teachers, subjects
- [x] Create/edit/delete teachers (with class assignments)
- [x] Create/edit/delete pupils
- [x] View all marks
- [x] Generate report cards for any pupil
- [x] View class performance analytics
- [x] Manage term settings
- [x] Manage nursery color configurations

### Teacher
- [x] View only assigned classes
- [x] View only pupils in assigned classes
- [x] Enter and update marks for assigned classes
- [x] Auto-generate teacher comments based on scores
- [x] Generate report cards for pupils in assigned classes
- [x] View personal dashboard with submission status

## Non-Functional Requirements

- **Single-file SPA** — all client code in one HTML file.
- **No server-side rendering** — pure browser app served as static files.
- **RLS enforced** — all tables have row-level security policies.
- **Realtime updates** — Supabase subscriptions for live data refresh.
- **Printable reports** — report cards render as printable HTML/PDF.

## Constraints

- No `users_id_fkey` constraint between `users.id` and `auth.users.id` (dropped to prevent FK errors during creation).
- Teacher creation requires `users_admin_all` RLS policy allowing authenticated users to insert.
- The `app_user_class()` function has `security definer` to bypass RLS during policy evaluation.
