import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_models.dart';
import '../models/academic_models.dart';
import '../models/student_models.dart';
import '../models/teacher_models.dart';
import '../models/attendance_models.dart';
import '../models/exam_models.dart';
import '../models/finance_models.dart';
import '../models/misc_models.dart';

final _db = Supabase.instance.client;

// ─── Auth Repository ──────────────────────────────────────────────────────────

class AuthRepository {
  Future<UserProfile?> signIn(String email, String password) async {
    final res = await _db.auth.signInWithPassword(email: email, password: password);
    if (res.user == null) return null;
    return getProfile(res.user!.id);
  }

  Future<UserProfile?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final res = await _db.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );
    if (res.user == null) return null;
    await Future.delayed(const Duration(milliseconds: 500));
    return getProfile(res.user!.id);
  }

  Future<void> signOut() => _db.auth.signOut();

  Future<UserProfile?> getProfile(String userId) async {
    final data = await _db.from('profiles').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile(String userId, Map<String, dynamic> updates) async {
    final data = await _db
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();
    return UserProfile.fromJson(data);
  }

  Future<void> resetPassword(String email) =>
      _db.auth.resetPasswordForEmail(email);

  User? get currentUser => _db.auth.currentUser;
  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;
}

// ─── Student Repository ────────────────────────────────────────────────────────

class StudentRepository {
  Future<List<Student>> getAll({String? classId, String? status}) async {
    var query = _db.from('students').select();
    if (classId != null) query = query.eq('class_id', classId);
    if (status != null) query = query.eq('status', status);
    final data = await query.order('first_name');
    return data.map((e) => Student.fromJson(e)).toList();
  }

  Future<Student?> getById(String id) async {
    final data = await _db.from('students').select().eq('id', id).maybeSingle();
    return data != null ? Student.fromJson(data) : null;
  }

  Future<Student?> getByProfileId(String profileId) async {
    final data = await _db
        .from('students')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    return data != null ? Student.fromJson(data) : null;
  }

  Future<List<Student>> getByParent(String parentId) async {
    final data = await _db
        .from('students')
        .select()
        .eq('parent_id', parentId)
        .order('first_name');
    return data.map((e) => Student.fromJson(e)).toList();
  }

  Future<Student> create(Map<String, dynamic> data) async {
    final res = await _db.from('students').insert(data).select().single();
    return Student.fromJson(res);
  }

  Future<Student> update(String id, Map<String, dynamic> data) async {
    final res = await _db
        .from('students')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Student.fromJson(res);
  }

  Future<void> delete(String id) =>
      _db.from('students').update({'status': 'inactive'}).eq('id', id);

  Future<int> getCount({String status = 'active'}) async {
    final res = await _db
        .from('students')
        .select()
        .eq('status', status)
        .count(CountOption.exact);
    return res.count;
  }
}

// ─── Teacher Repository ────────────────────────────────────────────────────────

class TeacherRepository {
  Future<List<Teacher>> getAll({String? status}) async {
    var query = _db.from('teachers').select();
    if (status != null) query = query.eq('status', status);
    final data = await query.order('first_name');
    return data.map((e) => Teacher.fromJson(e)).toList();
  }

  Future<Teacher?> getById(String id) async {
    final data = await _db.from('teachers').select().eq('id', id).maybeSingle();
    return data != null ? Teacher.fromJson(data) : null;
  }

  Future<Teacher?> getByProfileId(String profileId) async {
    final data = await _db
        .from('teachers')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();
    return data != null ? Teacher.fromJson(data) : null;
  }

  Future<Teacher> create(Map<String, dynamic> data) async {
    final res = await _db.from('teachers').insert(data).select().single();
    return Teacher.fromJson(res);
  }

  Future<Teacher> update(String id, Map<String, dynamic> data) async {
    final res = await _db
        .from('teachers')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Teacher.fromJson(res);
  }

  Future<void> delete(String id) =>
      _db.from('teachers').update({'status': 'inactive'}).eq('id', id);
}

// ─── Class Repository ─────────────────────────────────────────────────────────

class ClassRepository {
  Future<List<SchoolClass>> getAll() async {
    final data = await _db.from('classes').select().order('grade_level').order('section');
    return data.map((e) => SchoolClass.fromJson(e)).toList();
  }

  Future<SchoolClass?> getById(String id) async {
    final data = await _db.from('classes').select().eq('id', id).maybeSingle();
    return data != null ? SchoolClass.fromJson(data) : null;
  }

  Future<SchoolClass> create(Map<String, dynamic> data) async {
    final res = await _db.from('classes').insert(data).select().single();
    return SchoolClass.fromJson(res);
  }

  Future<SchoolClass> update(String id, Map<String, dynamic> data) async {
    final res = await _db.from('classes').update(data).eq('id', id).select().single();
    return SchoolClass.fromJson(res);
  }

  Future<void> delete(String id) => _db.from('classes').delete().eq('id', id);

  Future<List<Subject>> getSubjectsForClass(String classId) async {
    final data = await _db
        .from('class_subjects')
        .select('subjects(*)')
        .eq('class_id', classId);
    return data
        .map((e) => Subject.fromJson(e['subjects'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> assignSubject(String classId, String subjectId, String? teacherId) async {
    await _db.from('class_subjects').upsert({
      'class_id': classId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
    });
  }
}

// ─── Subject Repository ────────────────────────────────────────────────────────

class SubjectRepository {
  Future<List<Subject>> getAll() async {
    final data = await _db.from('subjects').select().order('name');
    return data.map((e) => Subject.fromJson(e)).toList();
  }

  Future<Subject> create(Map<String, dynamic> data) async {
    final res = await _db.from('subjects').insert(data).select().single();
    return Subject.fromJson(res);
  }

  Future<Subject> update(String id, Map<String, dynamic> data) async {
    final res = await _db.from('subjects').update(data).eq('id', id).select().single();
    return Subject.fromJson(res);
  }

  Future<void> delete(String id) => _db.from('subjects').delete().eq('id', id);
}

// ─── Timetable Repository ─────────────────────────────────────────────────────

class TimetableRepository {
  Future<List<TimetableEntry>> getForClass(String classId) async {
    final data = await _db
        .from('timetable')
        .select()
        .eq('class_id', classId)
        .order('day_of_week')
        .order('period_number');
    return data.map((e) => TimetableEntry.fromJson(e)).toList();
  }

  Future<TimetableEntry> upsert(Map<String, dynamic> data) async {
    final res = await _db.from('timetable').upsert(data).select().single();
    return TimetableEntry.fromJson(res);
  }

  Future<void> delete(String id) => _db.from('timetable').delete().eq('id', id);
}

// ─── Attendance Repository ─────────────────────────────────────────────────────

class AttendanceRepository {
  Future<List<StudentAttendance>> getForClass({
    required String classId,
    required DateTime date,
    String? subjectId,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    var query = _db
        .from('student_attendance')
        .select()
        .eq('class_id', classId)
        .eq('date', dateStr);
    if (subjectId != null) query = query.eq('subject_id', subjectId);
    final data = await query;
    return data.map((e) => StudentAttendance.fromJson(e)).toList();
  }

  Future<List<StudentAttendance>> getForStudent(String studentId,
      {DateTime? from, DateTime? to}) async {
    var query = _db
        .from('student_attendance')
        .select()
        .eq('student_id', studentId);
    if (from != null) query = query.gte('date', from.toIso8601String().split('T')[0]);
    if (to != null) query = query.lte('date', to.toIso8601String().split('T')[0]);
    final data = await query.order('date', ascending: false);
    return data.map((e) => StudentAttendance.fromJson(e)).toList();
  }

  Future<void> markBulk(List<Map<String, dynamic>> records) async {
    await _db.from('student_attendance').upsert(records);
  }

  Future<Map<String, int>> getSummaryForStudent(String studentId) async {
    final records = await getForStudent(studentId);
    final present = records.where((r) => r.status == AttendanceStatus.present).length;
    final absent = records.where((r) => r.status == AttendanceStatus.absent).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    return {'total': records.length, 'present': present, 'absent': absent, 'late': late};
  }

  // Staff attendance
  Future<List<StaffAttendance>> getStaffAttendance(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final data = await _db
        .from('staff_attendance')
        .select()
        .eq('date', dateStr);
    return data.map((e) => StaffAttendance.fromJson(e)).toList();
  }

  Future<void> markStaff(Map<String, dynamic> record) async {
    await _db.from('staff_attendance').upsert(record);
  }

  // Leave requests
  Future<List<LeaveRequest>> getLeaves({String? requesterId}) async {
    var query = _db.from('leave_requests').select();
    if (requesterId != null) query = query.eq('requester_id', requesterId);
    final data = await query.order('created_at', ascending: false);
    return data.map((e) => LeaveRequest.fromJson(e)).toList();
  }

  Future<LeaveRequest> createLeave(Map<String, dynamic> data) async {
    final res = await _db.from('leave_requests').insert(data).select().single();
    return LeaveRequest.fromJson(res);
  }

  Future<LeaveRequest> updateLeaveStatus(
      String id, String status, String approvedBy) async {
    final res = await _db
        .from('leave_requests')
        .update({'status': status, 'approved_by': approvedBy})
        .eq('id', id)
        .select()
        .single();
    return LeaveRequest.fromJson(res);
  }
}

// ─── Exam Repository ──────────────────────────────────────────────────────────

class ExamRepository {
  Future<List<Exam>> getAll({String? classId, String? subjectId}) async {
    var query = _db.from('exams').select();
    if (classId != null) query = query.eq('class_id', classId);
    if (subjectId != null) query = query.eq('subject_id', subjectId);
    final data = await query.order('exam_date', ascending: false);
    return data.map((e) => Exam.fromJson(e)).toList();
  }

  Future<Exam> create(Map<String, dynamic> data) async {
    final res = await _db.from('exams').insert(data).select().single();
    return Exam.fromJson(res);
  }

  Future<Exam> update(String id, Map<String, dynamic> data) async {
    final res = await _db.from('exams').update(data).eq('id', id).select().single();
    return Exam.fromJson(res);
  }

  Future<void> delete(String id) => _db.from('exams').delete().eq('id', id);

  Future<List<ExamResult>> getResults(String examId) async {
    final data = await _db
        .from('exam_results')
        .select()
        .eq('exam_id', examId)
        .order('marks_obtained', ascending: false);
    return data.map((e) => ExamResult.fromJson(e)).toList();
  }

  Future<List<ExamResult>> getResultsForStudent(String studentId) async {
    final data = await _db
        .from('exam_results')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return data.map((e) => ExamResult.fromJson(e)).toList();
  }

  Future<void> saveResult(Map<String, dynamic> data) async {
    await _db.from('exam_results').upsert(data);
  }

  Future<void> saveBulkResults(List<Map<String, dynamic>> results) async {
    await _db.from('exam_results').upsert(results);
  }
}

// ─── Fee Repository ───────────────────────────────────────────────────────────

class FeeRepository {
  Future<List<FeeStructure>> getStructures({String? classId}) async {
    var query = _db.from('fee_structures').select();
    if (classId != null) query = query.eq('class_id', classId);
    final data = await query.order('name');
    return data.map((e) => FeeStructure.fromJson(e)).toList();
  }

  Future<FeeStructure> createStructure(Map<String, dynamic> data) async {
    final res = await _db.from('fee_structures').insert(data).select().single();
    return FeeStructure.fromJson(res);
  }

  Future<FeeStructure> updateStructure(String id, Map<String, dynamic> data) async {
    final res = await _db
        .from('fee_structures')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return FeeStructure.fromJson(res);
  }

  Future<void> deleteStructure(String id) =>
      _db.from('fee_structures').delete().eq('id', id);

  Future<List<FeePayment>> getPayments({String? studentId}) async {
    var query = _db.from('fee_payments').select();
    if (studentId != null) query = query.eq('student_id', studentId);
    final data = await query.order('payment_date', ascending: false);
    return data.map((e) => FeePayment.fromJson(e)).toList();
  }

  Future<FeePayment> collectFee(Map<String, dynamic> data) async {
    final res = await _db.from('fee_payments').insert(data).select().single();
    return FeePayment.fromJson(res);
  }

  Future<Map<String, double>> getSummary() async {
    final data = await _db.from('fee_payments').select('amount_paid, status');
    double total = 0, collected = 0;
    for (final row in data) {
      final amount = (row['amount_paid'] as num).toDouble();
      total += amount;
      if (row['status'] == 'paid') collected += amount;
    }
    return {'total': total, 'collected': collected, 'pending': total - collected};
  }
}

// ─── Announcement Repository ──────────────────────────────────────────────────

class AnnouncementRepository {
  Future<List<Announcement>> getAll({String? audience}) async {
    var query = _db.from('announcements').select();
    if (audience != null && audience != 'all') {
      query = query.or('target_audience.eq.all,target_audience.eq.$audience');
    }
    final data = await query.order('is_pinned', ascending: false).order('published_at', ascending: false);
    return data.map((e) => Announcement.fromJson(e)).toList();
  }

  Future<Announcement> create(Map<String, dynamic> data) async {
    final res = await _db.from('announcements').insert(data).select().single();
    return Announcement.fromJson(res);
  }

  Future<Announcement> update(String id, Map<String, dynamic> data) async {
    final res = await _db.from('announcements').update(data).eq('id', id).select().single();
    return Announcement.fromJson(res);
  }

  Future<void> delete(String id) => _db.from('announcements').delete().eq('id', id);
}

// ─── Library Repository ───────────────────────────────────────────────────────

class LibraryRepository {
  Future<List<Book>> getBooks({String? search, String? category}) async {
    var query = _db.from('books').select();
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }
    if (category != null) query = query.eq('category', category);
    final data = await query.order('title');
    return data.map((e) => Book.fromJson(e)).toList();
  }

  Future<Book> addBook(Map<String, dynamic> data) async {
    final res = await _db.from('books').insert(data).select().single();
    return Book.fromJson(res);
  }

  Future<Book> updateBook(String id, Map<String, dynamic> data) async {
    final res = await _db.from('books').update(data).eq('id', id).select().single();
    return Book.fromJson(res);
  }

  Future<void> deleteBook(String id) => _db.from('books').delete().eq('id', id);

  Future<List<BookIssue>> getActiveIssues() async {
    final data = await _db
        .from('book_issues')
        .select()
        .eq('status', 'issued')
        .order('due_date');
    return data.map((e) => BookIssue.fromJson(e)).toList();
  }

  Future<List<BookIssue>> getIssuesForBorrower(String borrowerId) async {
    final data = await _db
        .from('book_issues')
        .select()
        .eq('borrower_id', borrowerId)
        .order('issue_date', ascending: false);
    return data.map((e) => BookIssue.fromJson(e)).toList();
  }

  Future<BookIssue> issueBook(Map<String, dynamic> data) async {
    // Decrement available copies
    await _db.rpc('decrement_book_copies', params: {'book_id': data['book_id']});
    final res = await _db.from('book_issues').insert(data).select().single();
    return BookIssue.fromJson(res);
  }

  Future<BookIssue> returnBook(String issueId, double fine) async {
    final issue = await _db
        .from('book_issues')
        .select()
        .eq('id', issueId)
        .single();
    await _db.rpc('increment_book_copies', params: {'book_id': issue['book_id']});
    final res = await _db.from('book_issues').update({
      'return_date': DateTime.now().toIso8601String().split('T')[0],
      'fine_amount': fine,
      'status': 'returned',
    }).eq('id', issueId).select().single();
    return BookIssue.fromJson(res);
  }
}

// ─── Notification Repository ──────────────────────────────────────────────────

class NotificationRepository {
  Future<List<AppNotification>> getForUser(String userId) async {
    final data = await _db
        .from('notifications')
        .select()
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return data.map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final res = await _db
        .from('notifications')
        .select()
        .eq('recipient_id', userId)
        .eq('is_read', false)
        .count(CountOption.exact);
    return res.count;
  }

  Future<void> markRead(String id) =>
      _db.from('notifications').update({'is_read': true}).eq('id', id);

  Future<void> markAllRead(String userId) => _db
      .from('notifications')
      .update({'is_read': true})
      .eq('recipient_id', userId);

  Future<AppNotification> create(Map<String, dynamic> data) async {
    final res = await _db.from('notifications').insert(data).select().single();
    return AppNotification.fromJson(res);
  }
}

// ─── Misc Repositories ────────────────────────────────────────────────────────

class TransportRepository {
  Future<List<BusRoute>> getRoutes() async {
    final data = await _db.from('bus_routes').select().order('route_number');
    return data.map((e) => BusRoute.fromJson(e)).toList();
  }

  Future<BusRoute> create(Map<String, dynamic> data) async {
    final res = await _db.from('bus_routes').insert(data).select().single();
    return BusRoute.fromJson(res);
  }

  Future<BusRoute> update(String id, Map<String, dynamic> data) async {
    final res = await _db.from('bus_routes').update(data).eq('id', id).select().single();
    return BusRoute.fromJson(res);
  }

  Future<void> delete(String id) => _db.from('bus_routes').delete().eq('id', id);

  Future<void> assignStudent(
      String studentId, String routeId, String pickupStop, String dropStop) async {
    await _db.from('student_transport').upsert({
      'student_id': studentId,
      'route_id': routeId,
      'pickup_stop': pickupStop,
      'drop_stop': dropStop,
    });
  }
}

class HostelRepository {
  Future<List<HostelRoom>> getRooms() async {
    final data = await _db.from('hostel_rooms').select().order('room_number');
    return data.map((e) => HostelRoom.fromJson(e)).toList();
  }

  Future<HostelRoom> create(Map<String, dynamic> data) async {
    final res = await _db.from('hostel_rooms').insert(data).select().single();
    return HostelRoom.fromJson(res);
  }

  Future<HostelRoom> update(String id, Map<String, dynamic> data) async {
    final res = await _db.from('hostel_rooms').update(data).eq('id', id).select().single();
    return HostelRoom.fromJson(res);
  }

  Future<void> allocateStudent(String studentId, String roomId) async {
    await _db.from('student_hostel').upsert({
      'student_id': studentId,
      'room_id': roomId,
      'check_in_date': DateTime.now().toIso8601String().split('T')[0],
    });
    // Increment occupied count
    await _db.rpc('increment_room_occupied', params: {'room_id': roomId});
  }
}

class HomeworkRepository {
  Future<List<Homework>> getAll({String? classId, String? subjectId}) async {
    var query = _db.from('homework').select();
    if (classId != null) query = query.eq('class_id', classId);
    if (subjectId != null) query = query.eq('subject_id', subjectId);
    final data = await query.order('due_date', ascending: false);
    return data.map((e) => Homework.fromJson(e)).toList();
  }

  Future<Homework> create(Map<String, dynamic> data) async {
    final res = await _db.from('homework').insert(data).select().single();
    return Homework.fromJson(res);
  }

  Future<Homework> update(String id, Map<String, dynamic> data) async {
    final res = await _db.from('homework').update(data).eq('id', id).select().single();
    return Homework.fromJson(res);
  }

  Future<void> delete(String id) => _db.from('homework').delete().eq('id', id);
}
