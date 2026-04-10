class SchoolClass {
  final String id;
  final String name;
  final String section;
  final int gradeLevel;
  final String? roomNumber;
  final int capacity;
  final String? classTeacherId;
  final String academicYear;
  final DateTime createdAt;

  const SchoolClass({
    required this.id,
    required this.name,
    required this.section,
    required this.gradeLevel,
    this.roomNumber,
    this.capacity = 40,
    this.classTeacherId,
    required this.academicYear,
    required this.createdAt,
  });

  String get displayName => '$name - $section';

  factory SchoolClass.fromJson(Map<String, dynamic> j) => SchoolClass(
        id: j['id'],
        name: j['name'],
        section: j['section'] ?? 'A',
        gradeLevel: j['grade_level'],
        roomNumber: j['room_number'],
        capacity: j['capacity'] ?? 40,
        classTeacherId: j['class_teacher_id'],
        academicYear: j['academic_year'] ?? '2024-25',
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'section': section,
        'grade_level': gradeLevel,
        'room_number': roomNumber,
        'capacity': capacity,
        'class_teacher_id': classTeacherId,
        'academic_year': academicYear,
      };
}

class Subject {
  final String id;
  final String name;
  final String code;
  final String? description;
  final int creditHours;
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.creditHours = 3,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: j['id'],
        name: j['name'],
        code: j['code'],
        description: j['description'],
        creditHours: j['credit_hours'] ?? 3,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'description': description,
        'credit_hours': creditHours,
      };
}

class ClassSubject {
  final String id;
  final String classId;
  final String subjectId;
  final String? teacherId;

  const ClassSubject({
    required this.id,
    required this.classId,
    required this.subjectId,
    this.teacherId,
  });

  factory ClassSubject.fromJson(Map<String, dynamic> j) => ClassSubject(
        id: j['id'],
        classId: j['class_id'],
        subjectId: j['subject_id'],
        teacherId: j['teacher_id'],
      );

  Map<String, dynamic> toJson() => {
        'class_id': classId,
        'subject_id': subjectId,
        'teacher_id': teacherId,
      };
}

class TimetableEntry {
  final String id;
  final String classId;
  final String subjectId;
  final String? teacherId;
  final int dayOfWeek; // 1=Mon ... 6=Sat
  final int periodNumber;
  final String startTime;
  final String endTime;
  final String? roomNumber;

  const TimetableEntry({
    required this.id,
    required this.classId,
    required this.subjectId,
    this.teacherId,
    required this.dayOfWeek,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    this.roomNumber,
  });

  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  String get dayName => dayOfWeek >= 1 && dayOfWeek <= 6 ? dayNames[dayOfWeek - 1] : '?';

  factory TimetableEntry.fromJson(Map<String, dynamic> j) => TimetableEntry(
        id: j['id'],
        classId: j['class_id'],
        subjectId: j['subject_id'],
        teacherId: j['teacher_id'],
        dayOfWeek: j['day_of_week'],
        periodNumber: j['period_number'],
        startTime: j['start_time'],
        endTime: j['end_time'],
        roomNumber: j['room_number'],
      );

  Map<String, dynamic> toJson() => {
        'class_id': classId,
        'subject_id': subjectId,
        'teacher_id': teacherId,
        'day_of_week': dayOfWeek,
        'period_number': periodNumber,
        'start_time': startTime,
        'end_time': endTime,
        'room_number': roomNumber,
      };
}

class Homework {
  final String id;
  final String title;
  final String? description;
  final String classId;
  final String subjectId;
  final String? assignedBy;
  final DateTime assignedDate;
  final DateTime dueDate;
  final double? maxMarks;
  final String status;
  final DateTime createdAt;

  const Homework({
    required this.id,
    required this.title,
    this.description,
    required this.classId,
    required this.subjectId,
    this.assignedBy,
    required this.assignedDate,
    required this.dueDate,
    this.maxMarks,
    this.status = 'active',
    required this.createdAt,
  });

  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status == 'active';

  factory Homework.fromJson(Map<String, dynamic> j) => Homework(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        classId: j['class_id'],
        subjectId: j['subject_id'],
        assignedBy: j['assigned_by'],
        assignedDate: DateTime.parse(j['assigned_date']),
        dueDate: DateTime.parse(j['due_date']),
        maxMarks: j['max_marks'] != null ? (j['max_marks'] as num).toDouble() : null,
        status: j['status'] ?? 'active',
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'class_id': classId,
        'subject_id': subjectId,
        'assigned_by': assignedBy,
        'assigned_date': assignedDate.toIso8601String().split('T')[0],
        'due_date': dueDate.toIso8601String().split('T')[0],
        'max_marks': maxMarks,
        'status': status,
      };
}
