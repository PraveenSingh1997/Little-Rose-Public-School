import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─── Enums ────────────────────────────────────────────────────────────────────

enum Gender { male, female, other }

extension GenderExt on Gender {
  String get label => ['Male', 'Female', 'Other'][index];
}

enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusExt on AttendanceStatus {
  String get label => ['Present', 'Absent', 'Late', 'Excused'][index];
  int get colorValue => [0xFF4CAF50, 0xFFF44336, 0xFFFF9800, 0xFF2196F3][index];
}

enum ExamType { quiz, assignment, midterm, finalExam, project }

extension ExamTypeExt on ExamType {
  String get label => ['Quiz', 'Assignment', 'Midterm', 'Final Exam', 'Project'][index];
}

enum AnnouncementType { general, exam, holiday, event, urgent }

extension AnnouncementTypeExt on AnnouncementType {
  String get label => ['General', 'Exam', 'Holiday', 'Event', 'Urgent'][index];
  int get colorValue =>
      [0xFF607D8B, 0xFF9C27B0, 0xFF4CAF50, 0xFF2196F3, 0xFFF44336][index];
  String get icon => ['📢', '📝', '🏖️', '🎉', '🚨'][index];
}

// ─── Student ──────────────────────────────────────────────────────────────────

class Student {
  final String id;
  String name;
  String rollNo;
  String className;
  String section;
  String? parentName;
  String? phone;
  String? email;
  DateTime dob;
  DateTime enrollmentDate;
  Gender gender;
  bool isActive;

  Student({
    String? id,
    required this.name,
    required this.rollNo,
    required this.className,
    this.section = 'A',
    this.parentName,
    this.phone,
    this.email,
    required this.dob,
    DateTime? enrollmentDate,
    this.gender = Gender.male,
    this.isActive = true,
  })  : id = id ?? _uuid.v4(),
        enrollmentDate = enrollmentDate ?? DateTime.now();

  int get age {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rollNo': rollNo,
        'className': className,
        'section': section,
        'parentName': parentName,
        'phone': phone,
        'email': email,
        'dob': dob.toIso8601String(),
        'enrollmentDate': enrollmentDate.toIso8601String(),
        'gender': gender.index,
        'isActive': isActive,
      };

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        name: j['name'],
        rollNo: j['rollNo'],
        className: j['className'],
        section: j['section'] ?? 'A',
        parentName: j['parentName'],
        phone: j['phone'],
        email: j['email'],
        dob: DateTime.parse(j['dob']),
        enrollmentDate: DateTime.parse(j['enrollmentDate']),
        gender: Gender.values[j['gender'] ?? 0],
        isActive: j['isActive'] ?? true,
      );
}

// ─── Teacher ──────────────────────────────────────────────────────────────────

class Teacher {
  final String id;
  String name;
  String email;
  String phone;
  String qualification;
  String subjectSpecialization;
  DateTime joiningDate;
  bool isActive;

  Teacher({
    String? id,
    required this.name,
    required this.email,
    required this.phone,
    required this.qualification,
    required this.subjectSpecialization,
    DateTime? joiningDate,
    this.isActive = true,
  })  : id = id ?? _uuid.v4(),
        joiningDate = joiningDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'qualification': qualification,
        'subjectSpecialization': subjectSpecialization,
        'joiningDate': joiningDate.toIso8601String(),
        'isActive': isActive,
      };

  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
        id: j['id'],
        name: j['name'],
        email: j['email'],
        phone: j['phone'],
        qualification: j['qualification'],
        subjectSpecialization: j['subjectSpecialization'],
        joiningDate: DateTime.parse(j['joiningDate']),
        isActive: j['isActive'] ?? true,
      );
}

// ─── Subject ──────────────────────────────────────────────────────────────────

class Subject {
  final String id;
  String name;
  String code;
  String className;
  String? teacherId;
  int creditHours;

  Subject({
    String? id,
    required this.name,
    required this.code,
    required this.className,
    this.teacherId,
    this.creditHours = 3,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'className': className,
        'teacherId': teacherId,
        'creditHours': creditHours,
      };

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: j['id'],
        name: j['name'],
        code: j['code'],
        className: j['className'],
        teacherId: j['teacherId'],
        creditHours: j['creditHours'] ?? 3,
      );
}

// ─── Attendance ───────────────────────────────────────────────────────────────

class AttendanceRecord {
  final String id;
  String studentId;
  String subjectId;
  DateTime date;
  AttendanceStatus status;
  String? note;

  AttendanceRecord({
    String? id,
    required this.studentId,
    required this.subjectId,
    required this.date,
    required this.status,
    this.note,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'subjectId': subjectId,
        'date': date.toIso8601String(),
        'status': status.index,
        'note': note,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['id'],
        studentId: j['studentId'],
        subjectId: j['subjectId'],
        date: DateTime.parse(j['date']),
        status: AttendanceStatus.values[j['status']],
        note: j['note'],
      );
}

// ─── Grade ────────────────────────────────────────────────────────────────────

class Grade {
  final String id;
  String studentId;
  String subjectId;
  double marks;
  double totalMarks;
  ExamType examType;
  DateTime date;
  String? remarks;

  Grade({
    String? id,
    required this.studentId,
    required this.subjectId,
    required this.marks,
    required this.totalMarks,
    required this.examType,
    DateTime? date,
    this.remarks,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  double get percentage => totalMarks > 0 ? (marks / totalMarks) * 100 : 0;

  String get letterGrade {
    final p = percentage;
    if (p >= 90) return 'A+';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B+';
    if (p >= 60) return 'B';
    if (p >= 50) return 'C';
    if (p >= 40) return 'D';
    return 'F';
  }

  int get gradeColor {
    final p = percentage;
    if (p >= 80) return 0xFF4CAF50;
    if (p >= 60) return 0xFF2196F3;
    if (p >= 40) return 0xFFFF9800;
    return 0xFFF44336;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'subjectId': subjectId,
        'marks': marks,
        'totalMarks': totalMarks,
        'examType': examType.index,
        'date': date.toIso8601String(),
        'remarks': remarks,
      };

  factory Grade.fromJson(Map<String, dynamic> j) => Grade(
        id: j['id'],
        studentId: j['studentId'],
        subjectId: j['subjectId'],
        marks: (j['marks'] as num).toDouble(),
        totalMarks: (j['totalMarks'] as num).toDouble(),
        examType: ExamType.values[j['examType']],
        date: DateTime.parse(j['date']),
        remarks: j['remarks'],
      );
}

// ─── Announcement ─────────────────────────────────────────────────────────────

class Announcement {
  final String id;
  String title;
  String content;
  String author;
  DateTime date;
  AnnouncementType type;
  bool isPinned;

  Announcement({
    String? id,
    required this.title,
    required this.content,
    required this.author,
    DateTime? date,
    this.type = AnnouncementType.general,
    this.isPinned = false,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'author': author,
        'date': date.toIso8601String(),
        'type': type.index,
        'isPinned': isPinned,
      };

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'],
        title: j['title'],
        content: j['content'],
        author: j['author'],
        date: DateTime.parse(j['date']),
        type: AnnouncementType.values[j['type']],
        isPinned: j['isPinned'] ?? false,
      );
}
