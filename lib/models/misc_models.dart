// ─── Announcement ─────────────────────────────────────────────────────────────

enum AnnouncementType { general, exam, holiday, event, urgent, fee }

extension AnnouncementTypeExt on AnnouncementType {
  String get value => ['general', 'exam', 'holiday', 'event', 'urgent', 'fee'][index];
  String get label => ['General', 'Exam', 'Holiday', 'Event', 'Urgent', 'Fee'][index];
  String get icon => ['📢', '📝', '🏖️', '🎉', '🚨', '💰'][index];
  int get colorValue =>
      [0xFF607D8B, 0xFF9C27B0, 0xFF4CAF50, 0xFF2196F3, 0xFFF44336, 0xFFFF9800][index];

  static AnnouncementType fromString(String s) =>
      AnnouncementType.values.firstWhere((e) => e.value == s,
          orElse: () => AnnouncementType.general);
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String? authorId;
  final AnnouncementType type;
  final String targetAudience;
  final bool isPinned;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.authorId,
    this.type = AnnouncementType.general,
    this.targetAudience = 'all',
    this.isPinned = false,
    required this.publishedAt,
    this.expiresAt,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
        id: j['id'],
        title: j['title'],
        content: j['content'],
        authorId: j['author_id'],
        type: AnnouncementTypeExt.fromString(j['type'] ?? 'general'),
        targetAudience: j['target_audience'] ?? 'all',
        isPinned: j['is_pinned'] ?? false,
        publishedAt: DateTime.parse(j['published_at']),
        expiresAt: j['expires_at'] != null ? DateTime.parse(j['expires_at']) : null,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'author_id': authorId,
        'type': type.value,
        'target_audience': targetAudience,
        'is_pinned': isPinned,
        'published_at': publishedAt.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
      };
}

// ─── Library ──────────────────────────────────────────────────────────────────

class Book {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? category;
  final String? publisher;
  final int? publicationYear;
  final int totalCopies;
  final int availableCopies;
  final String? shelfLocation;
  final String? coverUrl;
  final DateTime createdAt;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.category,
    this.publisher,
    this.publicationYear,
    this.totalCopies = 1,
    this.availableCopies = 1,
    this.shelfLocation,
    this.coverUrl,
    required this.createdAt,
  });

  bool get isAvailable => availableCopies > 0;

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        id: j['id'],
        title: j['title'],
        author: j['author'],
        isbn: j['isbn'],
        category: j['category'],
        publisher: j['publisher'],
        publicationYear: j['publication_year'],
        totalCopies: j['total_copies'] ?? 1,
        availableCopies: j['available_copies'] ?? 1,
        shelfLocation: j['shelf_location'],
        coverUrl: j['cover_url'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'isbn': isbn,
        'category': category,
        'publisher': publisher,
        'publication_year': publicationYear,
        'total_copies': totalCopies,
        'available_copies': availableCopies,
        'shelf_location': shelfLocation,
        'cover_url': coverUrl,
      };
}

class BookIssue {
  final String id;
  final String bookId;
  final String? borrowerId;
  final String? borrowerName;
  final String borrowerType;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final double finePerDay;
  final double fineAmount;
  final bool finePaid;
  final String status;
  final String? issuedBy;
  final DateTime createdAt;

  const BookIssue({
    required this.id,
    required this.bookId,
    this.borrowerId,
    this.borrowerName,
    this.borrowerType = 'student',
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    this.finePerDay = 1,
    this.fineAmount = 0,
    this.finePaid = false,
    this.status = 'issued',
    this.issuedBy,
    required this.createdAt,
  });

  bool get isOverdue =>
      returnDate == null && DateTime.now().isAfter(dueDate) && status == 'issued';

  double get calculatedFine {
    if (!isOverdue) return fineAmount;
    final days = DateTime.now().difference(dueDate).inDays;
    return days * finePerDay;
  }

  factory BookIssue.fromJson(Map<String, dynamic> j) => BookIssue(
        id: j['id'],
        bookId: j['book_id'],
        borrowerId: j['borrower_id'],
        borrowerName: j['borrower_name'],
        borrowerType: j['borrower_type'] ?? 'student',
        issueDate: DateTime.parse(j['issue_date']),
        dueDate: DateTime.parse(j['due_date']),
        returnDate: j['return_date'] != null ? DateTime.parse(j['return_date']) : null,
        finePerDay: j['fine_per_day'] != null ? (j['fine_per_day'] as num).toDouble() : 1,
        fineAmount: j['fine_amount'] != null ? (j['fine_amount'] as num).toDouble() : 0,
        finePaid: j['fine_paid'] ?? false,
        status: j['status'] ?? 'issued',
        issuedBy: j['issued_by'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'book_id': bookId,
        'borrower_id': borrowerId,
        'borrower_name': borrowerName,
        'borrower_type': borrowerType,
        'issue_date': issueDate.toIso8601String().split('T')[0],
        'due_date': dueDate.toIso8601String().split('T')[0],
        'return_date': returnDate?.toIso8601String().split('T')[0],
        'fine_amount': fineAmount,
        'fine_paid': finePaid,
        'status': status,
        'issued_by': issuedBy,
      };
}

// ─── Transport ────────────────────────────────────────────────────────────────

class BusRoute {
  final String id;
  final String routeName;
  final String routeNumber;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final int capacity;
  final double monthlyFee;
  final List<String> stops;
  final DateTime createdAt;

  const BusRoute({
    required this.id,
    required this.routeName,
    required this.routeNumber,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    this.capacity = 40,
    this.monthlyFee = 0,
    this.stops = const [],
    required this.createdAt,
  });

  factory BusRoute.fromJson(Map<String, dynamic> j) => BusRoute(
        id: j['id'],
        routeName: j['route_name'],
        routeNumber: j['route_number'],
        driverName: j['driver_name'],
        driverPhone: j['driver_phone'],
        vehicleNumber: j['vehicle_number'],
        capacity: j['capacity'] ?? 40,
        monthlyFee: j['monthly_fee'] != null ? (j['monthly_fee'] as num).toDouble() : 0,
        stops: j['stops'] != null
            ? List<String>.from(j['stops'] as List)
            : [],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'route_name': routeName,
        'route_number': routeNumber,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'vehicle_number': vehicleNumber,
        'capacity': capacity,
        'monthly_fee': monthlyFee,
        'stops': stops,
      };
}

// ─── Hostel ───────────────────────────────────────────────────────────────────

class HostelRoom {
  final String id;
  final String roomNumber;
  final int floor;
  final int capacity;
  final int occupied;
  final String roomType;
  final double monthlyFee;
  final List<String> amenities;
  final DateTime createdAt;

  const HostelRoom({
    required this.id,
    required this.roomNumber,
    this.floor = 1,
    this.capacity = 2,
    this.occupied = 0,
    this.roomType = 'shared',
    this.monthlyFee = 0,
    this.amenities = const [],
    required this.createdAt,
  });

  int get available => capacity - occupied;
  bool get isFull => occupied >= capacity;

  factory HostelRoom.fromJson(Map<String, dynamic> j) => HostelRoom(
        id: j['id'],
        roomNumber: j['room_number'],
        floor: j['floor'] ?? 1,
        capacity: j['capacity'] ?? 2,
        occupied: j['occupied'] ?? 0,
        roomType: j['room_type'] ?? 'shared',
        monthlyFee:
            j['monthly_fee'] != null ? (j['monthly_fee'] as num).toDouble() : 0,
        amenities: j['amenities'] != null
            ? List<String>.from(j['amenities'] as List)
            : [],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'room_number': roomNumber,
        'floor': floor,
        'capacity': capacity,
        'occupied': occupied,
        'room_type': roomType,
        'monthly_fee': monthlyFee,
        'amenities': amenities,
      };
}

// ─── Skills ───────────────────────────────────────────────────────────────────

enum SkillCategory { sports, arts, academics, technology, other }

extension SkillCategoryExt on SkillCategory {
  String get value => ['sports', 'arts', 'academics', 'technology', 'other'][index];
  String get label => ['Sports', 'Arts', 'Academics', 'Technology', 'Other'][index];
  String get icon => ['⚽', '🎨', '📚', '💻', '🌟'][index];
  int get colorValue =>
      [0xFF4CAF50, 0xFFE91E63, 0xFF2196F3, 0xFF9C27B0, 0xFF607D8B][index];

  static SkillCategory fromString(String s) =>
      SkillCategory.values.firstWhere((e) => e.value == s,
          orElse: () => SkillCategory.other);
}

enum SkillProficiency { beginner, intermediate, advanced, expert }

extension SkillProficiencyExt on SkillProficiency {
  String get value => ['beginner', 'intermediate', 'advanced', 'expert'][index];
  String get label => ['Beginner', 'Intermediate', 'Advanced', 'Expert'][index];
  int get colorValue =>
      [0xFF9E9E9E, 0xFF2196F3, 0xFF4CAF50, 0xFFFF9800][index];

  static SkillProficiency fromString(String s) =>
      SkillProficiency.values.firstWhere((e) => e.value == s,
          orElse: () => SkillProficiency.beginner);
}

class StudentSkill {
  final String id;
  final String studentId;
  final String skillName;
  final SkillCategory category;
  final SkillProficiency proficiency;
  final String? description;
  final String? awardedBy;
  final DateTime createdAt;

  const StudentSkill({
    required this.id,
    required this.studentId,
    required this.skillName,
    this.category = SkillCategory.other,
    this.proficiency = SkillProficiency.beginner,
    this.description,
    this.awardedBy,
    required this.createdAt,
  });

  factory StudentSkill.fromJson(Map<String, dynamic> j) => StudentSkill(
        id: j['id'],
        studentId: j['student_id'],
        skillName: j['skill_name'],
        category: SkillCategoryExt.fromString(j['category'] ?? 'other'),
        proficiency: SkillProficiencyExt.fromString(j['proficiency'] ?? 'beginner'),
        description: j['description'],
        awardedBy: j['awarded_by'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'skill_name': skillName,
        'category': category.value,
        'proficiency': proficiency.value,
        'description': description,
        'awarded_by': awardedBy,
      };
}

// ─── Notification ─────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    this.type = 'info',
    this.isRead = false,
    required this.createdAt,
  });

  int get colorValue {
    switch (type) {
      case 'warning': return 0xFFFF9800;
      case 'success': return 0xFF4CAF50;
      case 'attendance': return 0xFF2196F3;
      case 'fee': return 0xFF9C27B0;
      case 'exam': return 0xFFF44336;
      case 'announcement': return 0xFF607D8B;
      default: return 0xFF2196F3;
    }
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        recipientId: recipientId,
        title: title,
        message: message,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        recipientId: j['recipient_id'],
        title: j['title'],
        message: j['message'],
        type: j['type'] ?? 'info',
        isRead: j['is_read'] ?? false,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'recipient_id': recipientId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': isRead,
      };
}
