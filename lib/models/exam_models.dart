enum ExamType { quiz, assignment, midterm, finalExam, project, practical }

extension ExamTypeExt on ExamType {
  String get value => ['quiz', 'assignment', 'midterm', 'final', 'project', 'practical'][index];
  String get label => ['Quiz', 'Assignment', 'Midterm', 'Final Exam', 'Project', 'Practical'][index];
  static ExamType fromString(String s) =>
      ExamType.values.firstWhere((e) => e.value == s, orElse: () => ExamType.quiz);
}

class Exam {
  final String id;
  final String name;
  final ExamType examType;
  final String classId;
  final String subjectId;
  final DateTime examDate;
  final String? startTime;
  final int? durationMinutes;
  final double totalMarks;
  final double? passingMarks;
  final String? instructions;
  final String? createdBy;
  final DateTime createdAt;

  const Exam({
    required this.id,
    required this.name,
    required this.examType,
    required this.classId,
    required this.subjectId,
    required this.examDate,
    this.startTime,
    this.durationMinutes,
    required this.totalMarks,
    this.passingMarks,
    this.instructions,
    this.createdBy,
    required this.createdAt,
  });

  factory Exam.fromJson(Map<String, dynamic> j) => Exam(
        id: j['id'],
        name: j['name'],
        examType: ExamTypeExt.fromString(j['exam_type']),
        classId: j['class_id'],
        subjectId: j['subject_id'],
        examDate: DateTime.parse(j['exam_date']),
        startTime: j['start_time'],
        durationMinutes: j['duration_minutes'],
        totalMarks: (j['total_marks'] as num).toDouble(),
        passingMarks:
            j['passing_marks'] != null ? (j['passing_marks'] as num).toDouble() : null,
        instructions: j['instructions'],
        createdBy: j['created_by'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'exam_type': examType.value,
        'class_id': classId,
        'subject_id': subjectId,
        'exam_date': examDate.toIso8601String().split('T')[0],
        'start_time': startTime,
        'duration_minutes': durationMinutes,
        'total_marks': totalMarks,
        'passing_marks': passingMarks,
        'instructions': instructions,
        'created_by': createdBy,
      };
}

class ExamResult {
  final String id;
  final String examId;
  final String studentId;
  final double? marksObtained;
  final String? grade;
  final double? percentage;
  final String? remarks;
  final bool isAbsent;
  final String? enteredBy;
  final DateTime createdAt;

  const ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    this.marksObtained,
    this.grade,
    this.percentage,
    this.remarks,
    this.isAbsent = false,
    this.enteredBy,
    required this.createdAt,
  });

  int get gradeColorValue {
    final p = percentage ?? 0;
    if (p >= 80) return 0xFF4CAF50;
    if (p >= 60) return 0xFF2196F3;
    if (p >= 40) return 0xFFFF9800;
    return 0xFFF44336;
  }

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
        id: j['id'],
        examId: j['exam_id'],
        studentId: j['student_id'],
        marksObtained:
            j['marks_obtained'] != null ? (j['marks_obtained'] as num).toDouble() : null,
        grade: j['grade'],
        percentage:
            j['percentage'] != null ? (j['percentage'] as num).toDouble() : null,
        remarks: j['remarks'],
        isAbsent: j['is_absent'] ?? false,
        enteredBy: j['entered_by'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'exam_id': examId,
        'student_id': studentId,
        'marks_obtained': marksObtained,
        'remarks': remarks,
        'is_absent': isAbsent,
        'entered_by': enteredBy,
      };
}
