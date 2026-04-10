enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusExt on AttendanceStatus {
  String get value => ['present', 'absent', 'late', 'excused'][index];
  String get label => ['Present', 'Absent', 'Late', 'Excused'][index];
  int get colorValue => [0xFF4CAF50, 0xFFF44336, 0xFFFF9800, 0xFF2196F3][index];

  static AttendanceStatus fromString(String s) => AttendanceStatus.values
      .firstWhere((e) => e.value == s, orElse: () => AttendanceStatus.present);
}

class StudentAttendance {
  final String id;
  final String studentId;
  final String? classId;
  final String? subjectId;
  final DateTime date;
  final AttendanceStatus status;
  final String? markedBy;
  final String? note;
  final DateTime createdAt;

  const StudentAttendance({
    required this.id,
    required this.studentId,
    this.classId,
    this.subjectId,
    required this.date,
    required this.status,
    this.markedBy,
    this.note,
    required this.createdAt,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> j) => StudentAttendance(
        id: j['id'],
        studentId: j['student_id'],
        classId: j['class_id'],
        subjectId: j['subject_id'],
        date: DateTime.parse(j['date']),
        status: AttendanceStatusExt.fromString(j['status']),
        markedBy: j['marked_by'],
        note: j['note'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'class_id': classId,
        'subject_id': subjectId,
        'date': date.toIso8601String().split('T')[0],
        'status': status.value,
        'marked_by': markedBy,
        'note': note,
      };
}

enum StaffAttendanceStatus { present, absent, halfDay, onLeave }

extension StaffAttendanceStatusExt on StaffAttendanceStatus {
  String get value => ['present', 'absent', 'half_day', 'on_leave'][index];
  String get label => ['Present', 'Absent', 'Half Day', 'On Leave'][index];
  int get colorValue => [0xFF4CAF50, 0xFFF44336, 0xFFFF9800, 0xFF9E9E9E][index];

  static StaffAttendanceStatus fromString(String s) =>
      StaffAttendanceStatus.values.firstWhere((e) => e.value == s,
          orElse: () => StaffAttendanceStatus.present);
}

class StaffAttendance {
  final String id;
  final String teacherId;
  final DateTime date;
  final String? checkIn;
  final String? checkOut;
  final StaffAttendanceStatus status;
  final String? note;
  final DateTime createdAt;

  const StaffAttendance({
    required this.id,
    required this.teacherId,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory StaffAttendance.fromJson(Map<String, dynamic> j) => StaffAttendance(
        id: j['id'],
        teacherId: j['teacher_id'],
        date: DateTime.parse(j['date']),
        checkIn: j['check_in'],
        checkOut: j['check_out'],
        status: StaffAttendanceStatusExt.fromString(j['status']),
        note: j['note'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'teacher_id': teacherId,
        'date': date.toIso8601String().split('T')[0],
        'check_in': checkIn,
        'check_out': checkOut,
        'status': status.value,
        'note': note,
      };
}
