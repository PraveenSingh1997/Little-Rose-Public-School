# School Management System

A full-featured School Management System built with **Flutter** and **Supabase**, supporting Windows, Web, Android, and iOS.

## Features

| Module | Description |
|--------|-------------|
| Dashboard | Overview stats — students, teachers, classes, announcements |
| Students | Full CRUD, search, class assignment, parent info |
| Teachers | Employee management, qualifications, specialization |
| Classes & Subjects | Grade/section management, subject assignment |
| Timetable | Period-wise schedule grouped by day |
| Attendance | Bulk attendance marking (Present / Absent / Late / Excused) |
| Exams | Exam scheduling with auto grade calculation |
| Fees | Fee structures + payment collection with receipts |
| Library | Book inventory + issue/return with fine tracking |
| Transport | Bus routes and stop management |
| Hostel | Room allocation with occupancy tracking |
| Homework | Assignment management with overdue indicators |
| Announcements | Targeted announcements (all / students / teachers / parents) |
| Notifications | In-app notifications with read/unread state |
| Profile | View/edit profile, password reset, sign out |

## Tech Stack

- **Flutter** 3.x — Material Design 3
- **Supabase** — Auth, PostgreSQL database, Row Level Security
- **Provider** — State management (ChangeNotifier pattern)
- **Repository pattern** — All DB calls isolated in `repositories.dart`

## Roles

| Role | Access |
|------|--------|
| `admin` | Full access to all modules |
| `teacher` | Students, attendance, exams, homework, timetable |
| `student` | View own attendance, results, homework, notifications |
| `parent` | View child's attendance, results, fee payments |

## Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/school-management.git
cd school-management
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

```bash
cp lib/config/supabase_config.example.dart lib/config/supabase_config.dart
```

Edit `lib/config/supabase_config.dart` and fill in your Supabase project URL and anon key:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 4. Set up the database

Run the SQL in `supabase/schema.sql` in your **Supabase SQL Editor**.

### 5. Run the app

```bash
# Windows
flutter run -d windows

# Web
flutter run -d chrome

# Android
flutter run -d android
```

## First-time Setup

1. Register a new account via the app
2. In **Supabase → Table Editor → profiles**, set your user's `role` to `admin`
3. Log in — you now have full admin access

## Project Structure

```
lib/
├── config/          # Supabase config
├── models/          # Data models (Student, Teacher, Exam, etc.)
├── providers/       # ChangeNotifier providers (one per feature)
├── repositories/    # All Supabase queries
├── screens/
│   ├── admin/       # Dashboard
│   ├── students/
│   ├── teachers/
│   ├── classes/     # Classes, Subjects, Timetable
│   ├── attendance/
│   ├── exams/
│   ├── fees/
│   ├── library/
│   ├── transport/
│   ├── hostel/
│   ├── homework/
│   ├── announcements/
│   ├── notifications/
│   └── profile/
└── main.dart
supabase/
└── schema.sql       # Full database schema with RLS policies
```

## License

MIT
