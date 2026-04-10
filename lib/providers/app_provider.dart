import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_models.dart';
import '../models/academic_models.dart';
import '../models/student_models.dart';
import '../models/teacher_models.dart';
import '../models/attendance_models.dart';
import '../models/exam_models.dart';
import '../models/finance_models.dart';
import '../models/misc_models.dart';
import '../repositories/repositories.dart';

// ─── Auth Provider ────────────────────────────────────────────────────────────

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  UserProfile? _profile;
  bool _loading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _profile != null;
  UserRole get role => _profile?.role ?? UserRole.student;

  Future<void> init() async {
    final user = _repo.currentUser;
    if (user != null) {
      _profile = await _repo.getProfile(user.id);
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repo.signIn(email, password);
      _loading = false;
      notifyListeners();
      return _profile != null;
    } on AuthException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _repo.signUp(
          email: email, password: password, fullName: fullName, role: role);
      _loading = false;
      notifyListeners();
      return _profile != null;
    } on AuthException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _profile = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_profile == null) return;
    _profile = await _repo.updateProfile(_profile!.id, updates);
    notifyListeners();
  }

  Future<void> resetPassword(String email) => _repo.resetPassword(email);

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ─── Student Provider ─────────────────────────────────────────────────────────

class StudentProvider extends ChangeNotifier {
  final _repo = StudentRepository();
  List<Student> _students = [];
  Student? _selectedStudent;
  bool _loading = false;

  List<Student> get students => _students;
  Student? get selectedStudent => _selectedStudent;
  bool get loading => _loading;

  Future<void> loadAll({String? classId}) async {
    _loading = true;
    notifyListeners();
    _students = await _repo.getAll(classId: classId, status: 'active');
    _loading = false;
    notifyListeners();
  }

  Future<void> loadByProfile(String profileId) async {
    _selectedStudent = await _repo.getByProfileId(profileId);
    notifyListeners();
  }

  Future<void> loadByParent(String parentId) async {
    _loading = true;
    notifyListeners();
    _students = await _repo.getByParent(parentId);
    _loading = false;
    notifyListeners();
  }

  Future<Student> create(Map<String, dynamic> data) async {
    final s = await _repo.create(data);
    _students.insert(0, s);
    notifyListeners();
    return s;
  }

  Future<Student> update(String id, Map<String, dynamic> data) async {
    final s = await _repo.update(id, data);
    final idx = _students.indexWhere((x) => x.id == id);
    if (idx != -1) _students[idx] = s;
    if (_selectedStudent?.id == id) _selectedStudent = s;
    notifyListeners();
    return s;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  void select(Student s) {
    _selectedStudent = s;
    notifyListeners();
  }

  List<Student> search(String query, {String? classId}) {
    return _students.where((s) {
      final matchName = s.fullName.toLowerCase().contains(query.toLowerCase());
      final matchRoll = s.rollNumber.toLowerCase().contains(query.toLowerCase());
      final matchClass = classId == null || s.classId == classId;
      return (matchName || matchRoll) && matchClass;
    }).toList();
  }
}

// ─── Teacher Provider ─────────────────────────────────────────────────────────

class TeacherProvider extends ChangeNotifier {
  final _repo = TeacherRepository();
  List<Teacher> _teachers = [];
  bool _loading = false;

  List<Teacher> get teachers => _teachers;
  bool get loading => _loading;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _teachers = await _repo.getAll(status: 'active');
    _loading = false;
    notifyListeners();
  }

  Future<Teacher> create(Map<String, dynamic> data) async {
    final t = await _repo.create(data);
    _teachers.insert(0, t);
    notifyListeners();
    return t;
  }

  Future<Teacher> update(String id, Map<String, dynamic> data) async {
    final t = await _repo.update(id, data);
    final idx = _teachers.indexWhere((x) => x.id == id);
    if (idx != -1) _teachers[idx] = t;
    notifyListeners();
    return t;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _teachers.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}

// ─── Class Provider ───────────────────────────────────────────────────────────

class ClassProvider extends ChangeNotifier {
  final _classRepo = ClassRepository();
  final _subjectRepo = SubjectRepository();
  List<SchoolClass> _classes = [];
  List<Subject> _subjects = [];
  bool _loading = false;

  List<SchoolClass> get classes => _classes;
  List<Subject> get subjects => _subjects;
  bool get loading => _loading;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    final results = await Future.wait([
      _classRepo.getAll(),
      _subjectRepo.getAll(),
    ]);
    _classes = results[0] as List<SchoolClass>;
    _subjects = results[1] as List<Subject>;
    _loading = false;
    notifyListeners();
  }

  Future<SchoolClass> createClass(Map<String, dynamic> data) async {
    final c = await _classRepo.create(data);
    _classes.add(c);
    _classes.sort((a, b) => a.gradeLevel.compareTo(b.gradeLevel));
    notifyListeners();
    return c;
  }

  Future<SchoolClass> updateClass(String id, Map<String, dynamic> data) async {
    final c = await _classRepo.update(id, data);
    final idx = _classes.indexWhere((x) => x.id == id);
    if (idx != -1) _classes[idx] = c;
    notifyListeners();
    return c;
  }

  Future<void> deleteClass(String id) async {
    await _classRepo.delete(id);
    _classes.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<Subject> createSubject(Map<String, dynamic> data) async {
    final s = await _subjectRepo.create(data);
    _subjects.add(s);
    _subjects.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return s;
  }

  Future<Subject> updateSubject(String id, Map<String, dynamic> data) async {
    final s = await _subjectRepo.update(id, data);
    final idx = _subjects.indexWhere((x) => x.id == id);
    if (idx != -1) _subjects[idx] = s;
    notifyListeners();
    return s;
  }

  Future<void> deleteSubject(String id) async {
    await _subjectRepo.delete(id);
    _subjects.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  SchoolClass? getClassById(String id) =>
      _classes.where((c) => c.id == id).firstOrNull;

  Subject? getSubjectById(String id) =>
      _subjects.where((s) => s.id == id).firstOrNull;
}

// ─── Attendance Provider ──────────────────────────────────────────────────────

class AttendanceProvider extends ChangeNotifier {
  final _repo = AttendanceRepository();
  List<StudentAttendance> _records = [];
  final List<StaffAttendance> _staffRecords = [];
  List<LeaveRequest> _leaves = [];
  bool _loading = false;

  List<StudentAttendance> get records => _records;
  List<StaffAttendance> get staffRecords => _staffRecords;
  List<LeaveRequest> get leaves => _leaves;
  bool get loading => _loading;

  Future<void> loadForClass(String classId, DateTime date, {String? subjectId}) async {
    _loading = true;
    notifyListeners();
    _records = await _repo.getForClass(
        classId: classId, date: date, subjectId: subjectId);
    _loading = false;
    notifyListeners();
  }

  Future<List<StudentAttendance>> loadForStudent(String studentId) async {
    return _repo.getForStudent(studentId);
  }

  Future<void> markBulk(List<Map<String, dynamic>> records) async {
    await _repo.markBulk(records);
    notifyListeners();
  }

  Future<void> loadLeaves({String? requesterId}) async {
    _leaves = await _repo.getLeaves(requesterId: requesterId);
    notifyListeners();
  }

  Future<void> applyLeave(Map<String, dynamic> data) async {
    final leave = await _repo.createLeave(data);
    _leaves.insert(0, leave);
    notifyListeners();
  }

  Future<void> updateLeaveStatus(String id, String status, String approvedBy) async {
    final updated = await _repo.updateLeaveStatus(id, status, approvedBy);
    final idx = _leaves.indexWhere((l) => l.id == id);
    if (idx != -1) _leaves[idx] = updated;
    notifyListeners();
  }

  Future<Map<String, int>> getStudentSummary(String studentId) =>
      _repo.getSummaryForStudent(studentId);
}

// ─── Exam Provider ────────────────────────────────────────────────────────────

class ExamProvider extends ChangeNotifier {
  final _repo = ExamRepository();
  List<Exam> _exams = [];
  List<ExamResult> _results = [];
  bool _loading = false;

  List<Exam> get exams => _exams;
  List<ExamResult> get results => _results;
  bool get loading => _loading;

  Future<void> loadExams({String? classId}) async {
    _loading = true;
    notifyListeners();
    _exams = await _repo.getAll(classId: classId);
    _loading = false;
    notifyListeners();
  }

  Future<Exam> createExam(Map<String, dynamic> data) async {
    final e = await _repo.create(data);
    _exams.insert(0, e);
    notifyListeners();
    return e;
  }

  Future<Exam> updateExam(String id, Map<String, dynamic> data) async {
    final e = await _repo.update(id, data);
    final idx = _exams.indexWhere((x) => x.id == id);
    if (idx != -1) _exams[idx] = e;
    notifyListeners();
    return e;
  }

  Future<void> deleteExam(String id) async {
    await _repo.delete(id);
    _exams.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> loadResults(String examId) async {
    _results = await _repo.getResults(examId);
    notifyListeners();
  }

  Future<List<ExamResult>> loadStudentResults(String studentId) =>
      _repo.getResultsForStudent(studentId);

  Future<void> saveBulkResults(List<Map<String, dynamic>> results) async {
    await _repo.saveBulkResults(results);
    notifyListeners();
  }
}

// ─── Fee Provider ─────────────────────────────────────────────────────────────

class FeeProvider extends ChangeNotifier {
  final _repo = FeeRepository();
  List<FeeStructure> _structures = [];
  List<FeePayment> _payments = [];
  Map<String, double> _summary = {};
  bool _loading = false;

  List<FeeStructure> get structures => _structures;
  List<FeePayment> get payments => _payments;
  Map<String, double> get summary => _summary;
  bool get loading => _loading;

  Future<void> loadStructures() async {
    _loading = true;
    notifyListeners();
    _structures = await _repo.getStructures();
    _loading = false;
    notifyListeners();
  }

  Future<FeeStructure> createStructure(Map<String, dynamic> data) async {
    final s = await _repo.createStructure(data);
    _structures.add(s);
    notifyListeners();
    return s;
  }

  Future<void> deleteStructure(String id) async {
    await _repo.deleteStructure(id);
    _structures.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> loadPayments({String? studentId}) async {
    _loading = true;
    notifyListeners();
    _payments = await _repo.getPayments(studentId: studentId);
    _loading = false;
    notifyListeners();
  }

  Future<FeePayment> collectFee(Map<String, dynamic> data) async {
    final p = await _repo.collectFee(data);
    _payments.insert(0, p);
    notifyListeners();
    return p;
  }

  Future<void> loadSummary() async {
    _summary = await _repo.getSummary();
    notifyListeners();
  }
}

// ─── Announcement Provider ────────────────────────────────────────────────────

class AnnouncementProvider extends ChangeNotifier {
  final _repo = AnnouncementRepository();
  List<Announcement> _announcements = [];
  bool _loading = false;

  List<Announcement> get announcements => _announcements;
  bool get loading => _loading;

  Future<void> load({String? audience}) async {
    _loading = true;
    notifyListeners();
    _announcements = await _repo.getAll(audience: audience);
    _loading = false;
    notifyListeners();
  }

  Future<Announcement> create(Map<String, dynamic> data) async {
    final a = await _repo.create(data);
    _announcements.insert(0, a);
    notifyListeners();
    return a;
  }

  Future<Announcement> update(String id, Map<String, dynamic> data) async {
    final a = await _repo.update(id, data);
    final idx = _announcements.indexWhere((x) => x.id == id);
    if (idx != -1) _announcements[idx] = a;
    notifyListeners();
    return a;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _announcements.removeWhere((a) => a.id == id);
    notifyListeners();
  }
}

// ─── Library Provider ────────────────────────────────────────────────────────

class LibraryProvider extends ChangeNotifier {
  final _repo = LibraryRepository();
  List<Book> _books = [];
  List<BookIssue> _activeIssues = [];
  bool _loading = false;

  List<Book> get books => _books;
  List<BookIssue> get activeIssues => _activeIssues;
  bool get loading => _loading;

  Future<void> loadBooks({String? search}) async {
    _loading = true;
    notifyListeners();
    _books = await _repo.getBooks(search: search);
    _loading = false;
    notifyListeners();
  }

  Future<Book> addBook(Map<String, dynamic> data) async {
    final b = await _repo.addBook(data);
    _books.add(b);
    notifyListeners();
    return b;
  }

  Future<Book> updateBook(String id, Map<String, dynamic> data) async {
    final b = await _repo.updateBook(id, data);
    final idx = _books.indexWhere((x) => x.id == id);
    if (idx != -1) _books[idx] = b;
    notifyListeners();
    return b;
  }

  Future<void> deleteBook(String id) async {
    await _repo.deleteBook(id);
    _books.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<void> loadActiveIssues() async {
    _activeIssues = await _repo.getActiveIssues();
    notifyListeners();
  }

  Future<BookIssue> issueBook(Map<String, dynamic> data) async {
    final issue = await _repo.issueBook(data);
    _activeIssues.add(issue);
    await loadBooks();
    notifyListeners();
    return issue;
  }

  Future<BookIssue> returnBook(String issueId, double fine) async {
    final issue = await _repo.returnBook(issueId, fine);
    _activeIssues.removeWhere((i) => i.id == issueId);
    await loadBooks();
    notifyListeners();
    return issue;
  }
}

// ─── Notification Provider ────────────────────────────────────────────────────

class NotificationProvider extends ChangeNotifier {
  final _repo = NotificationRepository();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> load(String userId) async {
    _notifications = await _repo.getForUser(userId);
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = AppNotification(
        id: _notifications[idx].id,
        recipientId: _notifications[idx].recipientId,
        title: _notifications[idx].title,
        message: _notifications[idx].message,
        type: _notifications[idx].type,
        isRead: true,
        createdAt: _notifications[idx].createdAt,
      );
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  Future<void> markAllRead(String userId) async {
    await _repo.markAllRead(userId);
    _notifications = _notifications
        .map((n) => AppNotification(
              id: n.id,
              recipientId: n.recipientId,
              title: n.title,
              message: n.message,
              type: n.type,
              isRead: true,
              createdAt: n.createdAt,
            ))
        .toList();
    _unreadCount = 0;
    notifyListeners();
  }
}

// ─── Misc Providers ───────────────────────────────────────────────────────────

class TransportProvider extends ChangeNotifier {
  final _repo = TransportRepository();
  List<BusRoute> _routes = [];
  bool _loading = false;

  List<BusRoute> get routes => _routes;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _routes = await _repo.getRoutes();
    _loading = false;
    notifyListeners();
  }

  Future<BusRoute> create(Map<String, dynamic> data) async {
    final r = await _repo.create(data);
    _routes.add(r);
    notifyListeners();
    return r;
  }

  Future<BusRoute> update(String id, Map<String, dynamic> data) async {
    final r = await _repo.update(id, data);
    final idx = _routes.indexWhere((x) => x.id == id);
    if (idx != -1) _routes[idx] = r;
    notifyListeners();
    return r;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _routes.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}

class HostelProvider extends ChangeNotifier {
  final _repo = HostelRepository();
  List<HostelRoom> _rooms = [];
  bool _loading = false;

  List<HostelRoom> get rooms => _rooms;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _rooms = await _repo.getRooms();
    _loading = false;
    notifyListeners();
  }

  Future<HostelRoom> create(Map<String, dynamic> data) async {
    final r = await _repo.create(data);
    _rooms.add(r);
    notifyListeners();
    return r;
  }

  Future<HostelRoom> update(String id, Map<String, dynamic> data) async {
    final r = await _repo.update(id, data);
    final idx = _rooms.indexWhere((x) => x.id == id);
    if (idx != -1) _rooms[idx] = r;
    notifyListeners();
    return r;
  }
}

class HomeworkProvider extends ChangeNotifier {
  final _repo = HomeworkRepository();
  List<Homework> _homework = [];
  bool _loading = false;

  List<Homework> get homework => _homework;
  bool get loading => _loading;

  Future<void> load({String? classId}) async {
    _loading = true;
    notifyListeners();
    _homework = await _repo.getAll(classId: classId);
    _loading = false;
    notifyListeners();
  }

  Future<Homework> create(Map<String, dynamic> data) async {
    final h = await _repo.create(data);
    _homework.insert(0, h);
    notifyListeners();
    return h;
  }

  Future<Homework> update(String id, Map<String, dynamic> data) async {
    final h = await _repo.update(id, data);
    final idx = _homework.indexWhere((x) => x.id == id);
    if (idx != -1) _homework[idx] = h;
    notifyListeners();
    return h;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _homework.removeWhere((h) => h.id == id);
    notifyListeners();
  }
}
