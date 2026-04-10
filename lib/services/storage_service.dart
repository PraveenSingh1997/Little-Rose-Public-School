import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  List<Student> students = [];
  List<Teacher> teachers = [];
  List<Subject> subjects = [];
  List<AttendanceRecord> attendance = [];
  List<Grade> grades = [];
  List<Announcement> announcements = [];

  bool _seeded = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    students = _decode(prefs.getString('students'), Student.fromJson);
    teachers = _decode(prefs.getString('teachers'), Teacher.fromJson);
    subjects = _decode(prefs.getString('subjects'), Subject.fromJson);
    attendance = _decode(prefs.getString('attendance'), AttendanceRecord.fromJson);
    grades = _decode(prefs.getString('grades'), Grade.fromJson);
    announcements = _decode(prefs.getString('announcements'), Announcement.fromJson);

    if (!_seeded && students.isEmpty) {
      _seedData();
      _seeded = true;
      await saveAll();
    }
  }

  List<T> _decode<T>(String? raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStudents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('students', jsonEncode(students.map((e) => e.toJson()).toList()));
  }

  Future<void> saveTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teachers', jsonEncode(teachers.map((e) => e.toJson()).toList()));
  }

  Future<void> saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subjects', jsonEncode(subjects.map((e) => e.toJson()).toList()));
  }

  Future<void> saveAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('attendance', jsonEncode(attendance.map((e) => e.toJson()).toList()));
  }

  Future<void> saveGrades() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('grades', jsonEncode(grades.map((e) => e.toJson()).toList()));
  }

  Future<void> saveAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('announcements', jsonEncode(announcements.map((e) => e.toJson()).toList()));
  }

  Future<void> saveAll() async {
    await Future.wait([
      saveStudents(),
      saveTeachers(),
      saveSubjects(),
      saveAttendance(),
      saveGrades(),
      saveAnnouncements(),
    ]);
  }

  // ─── Seed Data ──────────────────────────────────────────────────────────────

  void _seedData() {
    teachers = [
      Teacher(
        name: 'Dr. Sarah Johnson',
        email: 'sarah.johnson@school.edu',
        phone: '555-0101',
        qualification: 'PhD Mathematics',
        subjectSpecialization: 'Mathematics',
        joiningDate: DateTime(2019, 8, 1),
      ),
      Teacher(
        name: 'Mr. David Williams',
        email: 'david.williams@school.edu',
        phone: '555-0102',
        qualification: 'MSc Physics',
        subjectSpecialization: 'Physics',
        joiningDate: DateTime(2020, 1, 15),
      ),
      Teacher(
        name: 'Ms. Emily Chen',
        email: 'emily.chen@school.edu',
        phone: '555-0103',
        qualification: 'MA English Literature',
        subjectSpecialization: 'English',
        joiningDate: DateTime(2021, 6, 1),
      ),
      Teacher(
        name: 'Mr. Raj Patel',
        email: 'raj.patel@school.edu',
        phone: '555-0104',
        qualification: 'BSc Computer Science',
        subjectSpecialization: 'Computer Science',
        joiningDate: DateTime(2022, 3, 10),
      ),
    ];

    subjects = [
      Subject(
        name: 'Mathematics',
        code: 'MTH101',
        className: 'Grade 10',
        teacherId: teachers[0].id,
        creditHours: 4,
      ),
      Subject(
        name: 'Physics',
        code: 'PHY101',
        className: 'Grade 10',
        teacherId: teachers[1].id,
        creditHours: 3,
      ),
      Subject(
        name: 'English',
        code: 'ENG101',
        className: 'Grade 10',
        teacherId: teachers[2].id,
        creditHours: 3,
      ),
      Subject(
        name: 'Computer Science',
        code: 'CS101',
        className: 'Grade 10',
        teacherId: teachers[3].id,
        creditHours: 3,
      ),
      Subject(
        name: 'Mathematics',
        code: 'MTH201',
        className: 'Grade 11',
        teacherId: teachers[0].id,
        creditHours: 4,
      ),
      Subject(
        name: 'Physics',
        code: 'PHY201',
        className: 'Grade 11',
        teacherId: teachers[1].id,
        creditHours: 3,
      ),
    ];

    students = [
      Student(
        name: 'Alice Thompson',
        rollNo: 'G10-001',
        className: 'Grade 10',
        section: 'A',
        parentName: 'Robert Thompson',
        phone: '555-1001',
        email: 'alice@example.com',
        dob: DateTime(2009, 3, 15),
        gender: Gender.female,
        enrollmentDate: DateTime(2023, 9, 1),
      ),
      Student(
        name: 'Bob Martinez',
        rollNo: 'G10-002',
        className: 'Grade 10',
        section: 'A',
        parentName: 'Carlos Martinez',
        phone: '555-1002',
        dob: DateTime(2009, 7, 22),
        gender: Gender.male,
        enrollmentDate: DateTime(2023, 9, 1),
      ),
      Student(
        name: 'Clara Singh',
        rollNo: 'G10-003',
        className: 'Grade 10',
        section: 'B',
        parentName: 'Amir Singh',
        phone: '555-1003',
        email: 'clara@example.com',
        dob: DateTime(2009, 11, 5),
        gender: Gender.female,
        enrollmentDate: DateTime(2023, 9, 1),
      ),
      Student(
        name: 'Daniel Lee',
        rollNo: 'G10-004',
        className: 'Grade 10',
        section: 'B',
        parentName: 'James Lee',
        phone: '555-1004',
        dob: DateTime(2009, 1, 30),
        gender: Gender.male,
        enrollmentDate: DateTime(2023, 9, 1),
      ),
      Student(
        name: 'Emma Wilson',
        rollNo: 'G11-001',
        className: 'Grade 11',
        section: 'A',
        parentName: 'Michael Wilson',
        phone: '555-1005',
        email: 'emma@example.com',
        dob: DateTime(2008, 5, 18),
        gender: Gender.female,
        enrollmentDate: DateTime(2022, 9, 1),
      ),
      Student(
        name: 'Felix Brown',
        rollNo: 'G11-002',
        className: 'Grade 11',
        section: 'A',
        parentName: 'George Brown',
        phone: '555-1006',
        dob: DateTime(2008, 9, 10),
        gender: Gender.male,
        enrollmentDate: DateTime(2022, 9, 1),
      ),
    ];

    // Seed some grades
    final today = DateTime.now();
    grades = [
      Grade(studentId: students[0].id, subjectId: subjects[0].id, marks: 88, totalMarks: 100, examType: ExamType.midterm, date: today.subtract(const Duration(days: 30))),
      Grade(studentId: students[0].id, subjectId: subjects[1].id, marks: 76, totalMarks: 100, examType: ExamType.midterm, date: today.subtract(const Duration(days: 30))),
      Grade(studentId: students[1].id, subjectId: subjects[0].id, marks: 92, totalMarks: 100, examType: ExamType.midterm, date: today.subtract(const Duration(days: 30))),
      Grade(studentId: students[1].id, subjectId: subjects[2].id, marks: 65, totalMarks: 100, examType: ExamType.midterm, date: today.subtract(const Duration(days: 30))),
      Grade(studentId: students[2].id, subjectId: subjects[0].id, marks: 55, totalMarks: 100, examType: ExamType.quiz, date: today.subtract(const Duration(days: 7))),
      Grade(studentId: students[4].id, subjectId: subjects[4].id, marks: 95, totalMarks: 100, examType: ExamType.midterm, date: today.subtract(const Duration(days: 30))),
    ];

    // Seed attendance for today
    for (final student in students.where((s) => s.className == 'Grade 10')) {
      attendance.add(AttendanceRecord(
        studentId: student.id,
        subjectId: subjects[0].id,
        date: DateTime(today.year, today.month, today.day),
        status: student.rollNo == 'G10-002' ? AttendanceStatus.absent : AttendanceStatus.present,
      ));
    }

    announcements = [
      Announcement(
        title: 'Mid-Term Exam Schedule Released',
        content: 'The mid-term examination schedule has been released. Exams will begin from next Monday. All students are required to carry their admit cards. Please check the notice board for room allocations.',
        author: 'Principal Office',
        type: AnnouncementType.exam,
        isPinned: true,
        date: today.subtract(const Duration(days: 2)),
      ),
      Announcement(
        title: 'Annual Sports Day – April 20',
        content: 'The Annual Sports Day will be held on April 20th. All students are encouraged to participate. Registration forms are available at the sports office. Last date to register is April 15.',
        author: 'Sports Department',
        type: AnnouncementType.event,
        date: today.subtract(const Duration(days: 4)),
      ),
      Announcement(
        title: 'School Closed on Friday',
        content: 'The school will remain closed on Friday due to a public holiday. Regular classes will resume on Monday.',
        author: 'Administration',
        type: AnnouncementType.holiday,
        date: today.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
