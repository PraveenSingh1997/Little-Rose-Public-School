class AppConstants {
  AppConstants._();

  static const String appName = 'Little Rose Public School';
  static const String currentAcademicYear = '2024-25';

  // Breakpoints
  static const double wideLayoutBreakpoint = 720.0;

  // Search debounce
  static const Duration searchDebounce = Duration(milliseconds: 300);

  // Attendance statuses
  static const String statusPresent = 'present';
  static const String statusAbsent = 'absent';
  static const String statusLate = 'late';
  static const String statusExcused = 'excused';

  // Payment methods
  static const String paymentCash = 'cash';
  static const String paymentOnline = 'online';
  static const String paymentCheque = 'cheque';
  static const String paymentCard = 'card';

  // Borrower types
  static const String borrowerStudent = 'student';
  static const String borrowerTeacher = 'teacher';
  static const String borrowerStaff = 'staff';

  // Announcement audiences
  static const String audienceAll = 'all';
  static const String audienceStudents = 'students';
  static const String audienceTeachers = 'teachers';
  static const String audienceParents = 'parents';
  static const String audienceStaff = 'staff';

  static const List<String> announcementAudiences = [
    audienceAll,
    audienceStudents,
    audienceTeachers,
    audienceParents,
    audienceStaff,
  ];
}
