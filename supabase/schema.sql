-- =============================================
-- SCHOOL MANAGEMENT SYSTEM - SUPABASE SCHEMA
-- Run this in your Supabase SQL Editor
-- =============================================

create extension if not exists "uuid-ossp";

-- ─── PROFILES (extends auth.users) ───────────────────────────────────────────
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  full_name text not null,
  role text not null check (role in ('admin','teacher','student','parent')),
  phone text,
  avatar_url text,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ─── CLASSES ─────────────────────────────────────────────────────────────────
create table if not exists classes (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  section text not null default 'A',
  grade_level int not null,
  room_number text,
  capacity int default 40,
  class_teacher_id uuid references profiles(id),
  academic_year text not null default '2024-25',
  created_at timestamptz default now()
);

-- ─── SUBJECTS ────────────────────────────────────────────────────────────────
create table if not exists subjects (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  code text not null,
  description text,
  credit_hours int default 3,
  created_at timestamptz default now()
);

create table if not exists class_subjects (
  id uuid default uuid_generate_v4() primary key,
  class_id uuid references classes(id) on delete cascade,
  subject_id uuid references subjects(id) on delete cascade,
  teacher_id uuid references profiles(id),
  unique(class_id, subject_id)
);

-- ─── STUDENTS ────────────────────────────────────────────────────────────────
create table if not exists students (
  id uuid default uuid_generate_v4() primary key,
  profile_id uuid references profiles(id) on delete set null,
  roll_number text not null unique,
  admission_number text unique,
  first_name text not null,
  last_name text not null,
  date_of_birth date not null,
  gender text check (gender in ('male','female','other')),
  blood_group text,
  address text,
  city text,
  state text,
  parent_id uuid references profiles(id),
  parent_name text,
  parent_phone text,
  parent_email text,
  class_id uuid references classes(id),
  admission_date date default current_date,
  status text default 'active' check (status in ('active','inactive','transferred','alumni')),
  photo_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ─── TEACHERS ────────────────────────────────────────────────────────────────
create table if not exists teachers (
  id uuid default uuid_generate_v4() primary key,
  profile_id uuid references profiles(id) on delete set null,
  employee_id text not null unique,
  first_name text not null,
  last_name text not null,
  date_of_birth date,
  gender text check (gender in ('male','female','other')),
  phone text,
  email text,
  address text,
  qualification text,
  specialization text,
  joining_date date default current_date,
  salary numeric(10,2),
  status text default 'active' check (status in ('active','inactive','on_leave')),
  photo_url text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ─── TIMETABLE ───────────────────────────────────────────────────────────────
create table if not exists timetable (
  id uuid default uuid_generate_v4() primary key,
  class_id uuid references classes(id) on delete cascade,
  subject_id uuid references subjects(id) on delete cascade,
  teacher_id uuid references profiles(id),
  day_of_week int check (day_of_week between 1 and 6), -- 1=Mon...6=Sat
  period_number int not null,
  start_time time not null,
  end_time time not null,
  room_number text,
  created_at timestamptz default now()
);

-- ─── ATTENDANCE ───────────────────────────────────────────────────────────────
create table if not exists student_attendance (
  id uuid default uuid_generate_v4() primary key,
  student_id uuid references students(id) on delete cascade,
  class_id uuid references classes(id),
  subject_id uuid references subjects(id),
  date date not null,
  status text not null check (status in ('present','absent','late','excused')),
  marked_by uuid references profiles(id),
  note text,
  created_at timestamptz default now(),
  unique(student_id, subject_id, date)
);

create table if not exists staff_attendance (
  id uuid default uuid_generate_v4() primary key,
  teacher_id uuid references teachers(id) on delete cascade,
  date date not null,
  check_in time,
  check_out time,
  status text not null check (status in ('present','absent','half_day','on_leave')),
  note text,
  created_at timestamptz default now(),
  unique(teacher_id, date)
);

-- ─── LEAVE REQUESTS ──────────────────────────────────────────────────────────
create table if not exists leave_requests (
  id uuid default uuid_generate_v4() primary key,
  requester_id uuid references profiles(id),
  requester_type text check (requester_type in ('teacher','student')),
  leave_type text default 'personal' check (leave_type in ('sick','personal','emergency','other')),
  start_date date not null,
  end_date date not null,
  reason text not null,
  status text default 'pending' check (status in ('pending','approved','rejected')),
  approved_by uuid references profiles(id),
  remarks text,
  created_at timestamptz default now()
);

-- ─── EXAMS ───────────────────────────────────────────────────────────────────
create table if not exists exams (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  exam_type text not null check (exam_type in ('quiz','assignment','midterm','final','project','practical')),
  class_id uuid references classes(id) on delete cascade,
  subject_id uuid references subjects(id) on delete cascade,
  exam_date date not null,
  start_time time,
  duration_minutes int,
  total_marks numeric(6,2) not null,
  passing_marks numeric(6,2),
  instructions text,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table if not exists exam_results (
  id uuid default uuid_generate_v4() primary key,
  exam_id uuid references exams(id) on delete cascade,
  student_id uuid references students(id) on delete cascade,
  marks_obtained numeric(6,2),
  grade text,
  percentage numeric(5,2),
  remarks text,
  is_absent boolean default false,
  entered_by uuid references profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(exam_id, student_id)
);

-- ─── FEES ────────────────────────────────────────────────────────────────────
create table if not exists fee_structures (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  class_id uuid references classes(id),
  amount numeric(10,2) not null,
  fee_type text not null check (fee_type in ('tuition','admission','exam','library','transport','hostel','other')),
  due_day int default 10,
  academic_year text not null default '2024-25',
  frequency text default 'monthly' check (frequency in ('one_time','monthly','quarterly','annually')),
  late_fine_per_day numeric(8,2) default 0,
  created_at timestamptz default now()
);

create table if not exists fee_payments (
  id uuid default uuid_generate_v4() primary key,
  student_id uuid references students(id) on delete cascade,
  fee_structure_id uuid references fee_structures(id),
  amount_paid numeric(10,2) not null,
  discount numeric(10,2) default 0,
  fine numeric(10,2) default 0,
  payment_date date default current_date,
  payment_method text default 'cash' check (payment_method in ('cash','card','online','bank_transfer','cheque')),
  transaction_id text,
  receipt_number text unique,
  month_year text,
  status text default 'paid' check (status in ('paid','partial','pending','overdue','waived')),
  collected_by uuid references profiles(id),
  notes text,
  created_at timestamptz default now()
);

-- ─── ANNOUNCEMENTS ───────────────────────────────────────────────────────────
create table if not exists announcements (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  content text not null,
  author_id uuid references profiles(id),
  type text default 'general' check (type in ('general','exam','holiday','event','urgent','fee')),
  target_audience text default 'all' check (target_audience in ('all','students','teachers','parents')),
  is_pinned boolean default false,
  published_at timestamptz default now(),
  expires_at timestamptz,
  created_at timestamptz default now()
);

-- ─── LIBRARY ─────────────────────────────────────────────────────────────────
create table if not exists books (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  author text not null,
  isbn text,
  category text,
  publisher text,
  publication_year int,
  total_copies int default 1,
  available_copies int default 1,
  shelf_location text,
  cover_url text,
  created_at timestamptz default now()
);

create table if not exists book_issues (
  id uuid default uuid_generate_v4() primary key,
  book_id uuid references books(id) on delete cascade,
  borrower_id uuid references profiles(id),
  borrower_name text,
  borrower_type text check (borrower_type in ('student','teacher')),
  issue_date date default current_date,
  due_date date not null,
  return_date date,
  fine_per_day numeric(6,2) default 1,
  fine_amount numeric(6,2) default 0,
  fine_paid boolean default false,
  status text default 'issued' check (status in ('issued','returned','overdue','lost')),
  issued_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- ─── TRANSPORT ───────────────────────────────────────────────────────────────
create table if not exists bus_routes (
  id uuid default uuid_generate_v4() primary key,
  route_name text not null,
  route_number text not null unique,
  driver_name text,
  driver_phone text,
  vehicle_number text,
  capacity int default 40,
  monthly_fee numeric(8,2) default 0,
  stops jsonb default '[]',
  created_at timestamptz default now()
);

create table if not exists student_transport (
  id uuid default uuid_generate_v4() primary key,
  student_id uuid references students(id) on delete cascade unique,
  route_id uuid references bus_routes(id) on delete set null,
  pickup_stop text,
  drop_stop text,
  created_at timestamptz default now()
);

-- ─── HOSTEL ──────────────────────────────────────────────────────────────────
create table if not exists hostel_rooms (
  id uuid default uuid_generate_v4() primary key,
  room_number text not null unique,
  floor int default 1,
  capacity int default 2,
  occupied int default 0,
  room_type text default 'shared' check (room_type in ('single','double','shared')),
  monthly_fee numeric(8,2) default 0,
  amenities jsonb default '[]',
  created_at timestamptz default now()
);

create table if not exists student_hostel (
  id uuid default uuid_generate_v4() primary key,
  student_id uuid references students(id) on delete cascade unique,
  room_id uuid references hostel_rooms(id) on delete set null,
  check_in_date date default current_date,
  check_out_date date,
  created_at timestamptz default now()
);

-- ─── HOMEWORK ────────────────────────────────────────────────────────────────
create table if not exists homework (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  description text,
  class_id uuid references classes(id) on delete cascade,
  subject_id uuid references subjects(id) on delete cascade,
  assigned_by uuid references profiles(id),
  assigned_date date default current_date,
  due_date date not null,
  max_marks numeric(6,2),
  status text default 'active' check (status in ('active','closed')),
  created_at timestamptz default now()
);

-- ─── NOTIFICATIONS ───────────────────────────────────────────────────────────
create table if not exists notifications (
  id uuid default uuid_generate_v4() primary key,
  recipient_id uuid references profiles(id) on delete cascade,
  title text not null,
  message text not null,
  type text default 'info' check (type in ('info','warning','success','attendance','fee','exam','announcement')),
  is_read boolean default false,
  created_at timestamptz default now()
);

-- ─── TRIGGERS ────────────────────────────────────────────────────────────────

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email,'@',1)),
    coalesce(new.raw_user_meta_data->>'role', 'student')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Auto calculate grade & percentage on results
create or replace function calculate_grade(pct numeric)
returns text as $$
begin
  if pct >= 90 then return 'A+';
  elsif pct >= 80 then return 'A';
  elsif pct >= 70 then return 'B+';
  elsif pct >= 60 then return 'B';
  elsif pct >= 50 then return 'C';
  elsif pct >= 40 then return 'D';
  else return 'F';
  end if;
end;
$$ language plpgsql;

create or replace function auto_grade()
returns trigger as $$
declare total numeric;
begin
  select total_marks into total from exams where id = new.exam_id;
  if new.marks_obtained is not null and total > 0 then
    new.percentage := round((new.marks_obtained / total) * 100, 2);
    new.grade := calculate_grade(new.percentage);
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_grade on exam_results;
create trigger set_grade
  before insert or update on exam_results
  for each row execute procedure auto_grade();

-- Update updated_at
create or replace function update_updated_at()
returns trigger as $$
begin new.updated_at = now(); return new; end;
$$ language plpgsql;

create trigger upd_students before update on students for each row execute procedure update_updated_at();
create trigger upd_teachers before update on teachers for each row execute procedure update_updated_at();
create trigger upd_profiles before update on profiles for each row execute procedure update_updated_at();

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
alter table profiles enable row level security;
alter table classes enable row level security;
alter table subjects enable row level security;
alter table class_subjects enable row level security;
alter table students enable row level security;
alter table teachers enable row level security;
alter table timetable enable row level security;
alter table student_attendance enable row level security;
alter table staff_attendance enable row level security;
alter table leave_requests enable row level security;
alter table exams enable row level security;
alter table exam_results enable row level security;
alter table fee_structures enable row level security;
alter table fee_payments enable row level security;
alter table announcements enable row level security;
alter table books enable row level security;
alter table book_issues enable row level security;
alter table bus_routes enable row level security;
alter table student_transport enable row level security;
alter table hostel_rooms enable row level security;
alter table student_hostel enable row level security;
alter table homework enable row level security;
alter table notifications enable row level security;

-- Helper function to get current user role
create or replace function get_my_role()
returns text as $$
  select role from profiles where id = auth.uid();
$$ language sql security definer;

-- Profiles
create policy "own profile" on profiles for select using (id = auth.uid());
create policy "admin all profiles" on profiles for all using (get_my_role() = 'admin');
create policy "update own" on profiles for update using (id = auth.uid());
create policy "teacher view profiles" on profiles for select using (get_my_role() = 'teacher');

-- Classes (all authenticated can read, admin manages)
create policy "read classes" on classes for select using (auth.role() = 'authenticated');
create policy "admin classes" on classes for all using (get_my_role() = 'admin');

-- Subjects
create policy "read subjects" on subjects for select using (auth.role() = 'authenticated');
create policy "admin subjects" on subjects for all using (get_my_role() = 'admin');

-- class_subjects
create policy "read class_subjects" on class_subjects for select using (auth.role() = 'authenticated');
create policy "admin class_subjects" on class_subjects for all using (get_my_role() = 'admin');
create policy "teacher class_subjects" on class_subjects for all using (get_my_role() = 'teacher');

-- Students
create policy "admin teacher students" on students for all using (get_my_role() in ('admin','teacher'));
create policy "own student record" on students for select using (profile_id = auth.uid());
create policy "parent view child" on students for select using (parent_id = auth.uid());

-- Teachers
create policy "admin teacher mgmt" on teachers for all using (get_my_role() = 'admin');
create policy "teacher own record" on teachers for select using (profile_id = auth.uid());
create policy "all view teachers" on teachers for select using (auth.role() = 'authenticated');

-- Timetable
create policy "read timetable" on timetable for select using (auth.role() = 'authenticated');
create policy "admin teacher timetable" on timetable for all using (get_my_role() in ('admin','teacher'));

-- Attendance
create policy "admin teacher attendance" on student_attendance for all using (get_my_role() in ('admin','teacher'));
create policy "student own attendance" on student_attendance for select using (
  exists (select 1 from students where id = student_id and profile_id = auth.uid())
);
create policy "parent attendance" on student_attendance for select using (
  exists (select 1 from students where id = student_id and parent_id = auth.uid())
);

-- Staff attendance
create policy "admin staff att" on staff_attendance for all using (get_my_role() = 'admin');
create policy "teacher own att" on staff_attendance for select using (
  exists (select 1 from teachers where id = teacher_id and profile_id = auth.uid())
);

-- Leave
create policy "own leave" on leave_requests for all using (requester_id = auth.uid());
create policy "admin leave" on leave_requests for all using (get_my_role() = 'admin');

-- Exams
create policy "admin teacher exams" on exams for all using (get_my_role() in ('admin','teacher'));
create policy "read exams" on exams for select using (auth.role() = 'authenticated');

-- Results
create policy "admin teacher results" on exam_results for all using (get_my_role() in ('admin','teacher'));
create policy "student own results" on exam_results for select using (
  exists (select 1 from students where id = student_id and profile_id = auth.uid())
);
create policy "parent results" on exam_results for select using (
  exists (select 1 from students where id = student_id and parent_id = auth.uid())
);

-- Fees
create policy "admin fees" on fee_structures for all using (get_my_role() = 'admin');
create policy "read fee_structures" on fee_structures for select using (auth.role() = 'authenticated');
create policy "admin payments" on fee_payments for all using (get_my_role() = 'admin');
create policy "student own payments" on fee_payments for select using (
  exists (select 1 from students where id = student_id and profile_id = auth.uid())
);
create policy "parent payments" on fee_payments for select using (
  exists (select 1 from students where id = student_id and parent_id = auth.uid())
);

-- Announcements
create policy "admin teacher announce" on announcements for all using (get_my_role() in ('admin','teacher'));
create policy "read announcements" on announcements for select using (auth.role() = 'authenticated');

-- Library
create policy "read books" on books for select using (auth.role() = 'authenticated');
create policy "admin books" on books for all using (get_my_role() = 'admin');
create policy "admin issues" on book_issues for all using (get_my_role() = 'admin');
create policy "own issue" on book_issues for select using (borrower_id = auth.uid());

-- Transport
create policy "read transport" on bus_routes for select using (auth.role() = 'authenticated');
create policy "admin transport" on bus_routes for all using (get_my_role() = 'admin');
create policy "read student_transport" on student_transport for select using (auth.role() = 'authenticated');
create policy "admin student_transport" on student_transport for all using (get_my_role() = 'admin');

-- Hostel
create policy "read hostel" on hostel_rooms for select using (auth.role() = 'authenticated');
create policy "admin hostel" on hostel_rooms for all using (get_my_role() = 'admin');
create policy "read student_hostel" on student_hostel for select using (auth.role() = 'authenticated');
create policy "admin student_hostel" on student_hostel for all using (get_my_role() = 'admin');

-- Homework
create policy "admin teacher hw" on homework for all using (get_my_role() in ('admin','teacher'));
create policy "read homework" on homework for select using (auth.role() = 'authenticated');

-- Notifications
create policy "own notifications" on notifications for all using (recipient_id = auth.uid());
create policy "admin notifications" on notifications for all using (get_my_role() = 'admin');

-- ─── SAMPLE DATA ─────────────────────────────────────────────────────────────
-- Note: Run this AFTER creating your admin user via Supabase Auth
-- Replace 'YOUR_ADMIN_USER_ID' with the actual UUID from auth.users

insert into classes (name, section, grade_level, room_number, academic_year) values
  ('Grade 10', 'A', 10, '101', '2024-25'),
  ('Grade 10', 'B', 10, '102', '2024-25'),
  ('Grade 11', 'A', 11, '201', '2024-25'),
  ('Grade 11', 'B', 11, '202', '2024-25'),
  ('Grade 12', 'A', 12, '301', '2024-25')
on conflict do nothing;

insert into subjects (name, code, credit_hours) values
  ('Mathematics', 'MTH', 4),
  ('Physics', 'PHY', 3),
  ('Chemistry', 'CHE', 3),
  ('English', 'ENG', 3),
  ('Computer Science', 'CS', 3),
  ('Biology', 'BIO', 3),
  ('History', 'HIS', 2),
  ('Geography', 'GEO', 2)
on conflict do nothing;

insert into fee_structures (name, fee_type, amount, frequency, academic_year) values
  ('Tuition Fee', 'tuition', 5000, 'monthly', '2024-25'),
  ('Admission Fee', 'admission', 10000, 'one_time', '2024-25'),
  ('Exam Fee', 'exam', 1500, 'quarterly', '2024-25'),
  ('Library Fee', 'library', 500, 'annually', '2024-25'),
  ('Transport Fee', 'transport', 2000, 'monthly', '2024-25')
on conflict do nothing;

insert into hostel_rooms (room_number, floor, capacity, room_type, monthly_fee) values
  ('101', 1, 2, 'double', 8000),
  ('102', 1, 2, 'double', 8000),
  ('103', 1, 1, 'single', 12000),
  ('201', 2, 3, 'shared', 6000),
  ('202', 2, 3, 'shared', 6000)
on conflict do nothing;

insert into bus_routes (route_name, route_number, driver_name, driver_phone, vehicle_number, capacity, monthly_fee, stops) values
  ('North Route', 'R1', 'John Driver', '555-0001', 'SCH-001', 40, 2000, '["Main Gate","Park Road","City Center","Mall Stop","School"]'),
  ('South Route', 'R2', 'Mike Driver', '555-0002', 'SCH-002', 40, 2000, '["South Gate","Railway Station","Market","School"]'),
  ('East Route', 'R3', 'Sam Driver', '555-0003', 'SCH-003', 35, 1800, '["East Colony","Hospital Road","School"]')
on conflict do nothing;

-- ─── MIGRATION: Admission Form Fields ────────────────────────────────────────
-- Run this block in Supabase SQL Editor if the students table already exists.
alter table students
  add column if not exists form_number            text,
  add column if not exists scholar_number         text,
  add column if not exists father_name            text,
  add column if not exists mother_name            text,
  add column if not exists guardian_name          text,
  add column if not exists office_phone           text,
  add column if not exists father_occupation      text,
  add column if not exists father_qualification   text,
  add column if not exists mother_qualification   text,
  add column if not exists udise_number           text,
  add column if not exists aadhar_number          text,
  add column if not exists bank_account_number    text,
  add column if not exists ifsc_code              text,
  add column if not exists last_passed_class      text,
  add column if not exists last_passed_year       text,
  add column if not exists last_passed_percentage text,
  add column if not exists last_passed_total      text,
  add column if not exists category               text
    check (category in ('general','obc','sc','st'));
