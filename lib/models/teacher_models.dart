class Teacher {
  final String id;
  final String? profileId;
  final String employeeId;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? email;
  final String? address;
  final String? qualification;
  final String? specialization;
  final DateTime joiningDate;
  final double? salary;
  final String status;
  final String? photoUrl;
  final DateTime createdAt;

  const Teacher({
    required this.id,
    this.profileId,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.email,
    this.address,
    this.qualification,
    this.specialization,
    required this.joiningDate,
    this.salary,
    this.status = 'active',
    this.photoUrl,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  bool get isActive => status == 'active';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  factory Teacher.fromJson(Map<String, dynamic> j) => Teacher(
        id: j['id'],
        profileId: j['profile_id'],
        employeeId: j['employee_id'],
        firstName: j['first_name'],
        lastName: j['last_name'],
        dateOfBirth:
            j['date_of_birth'] != null ? DateTime.parse(j['date_of_birth']) : null,
        gender: j['gender'],
        phone: j['phone'],
        email: j['email'],
        address: j['address'],
        qualification: j['qualification'],
        specialization: j['specialization'],
        joiningDate: DateTime.parse(j['joining_date']),
        salary: j['salary'] != null ? (j['salary'] as num).toDouble() : null,
        status: j['status'] ?? 'active',
        photoUrl: j['photo_url'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'employee_id': employeeId,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
        'gender': gender,
        'phone': phone,
        'email': email,
        'address': address,
        'qualification': qualification,
        'specialization': specialization,
        'joining_date': joiningDate.toIso8601String().split('T')[0],
        'salary': salary,
        'status': status,
        'photo_url': photoUrl,
      };
}

class LeaveRequest {
  final String id;
  final String requesterId;
  final String requesterType;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String status;
  final String? approvedBy;
  final String? remarks;
  final DateTime createdAt;

  const LeaveRequest({
    required this.id,
    required this.requesterId,
    required this.requesterType,
    this.leaveType = 'personal',
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.status = 'pending',
    this.approvedBy,
    this.remarks,
    required this.createdAt,
  });

  int get days => endDate.difference(startDate).inDays + 1;

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
        id: j['id'],
        requesterId: j['requester_id'],
        requesterType: j['requester_type'],
        leaveType: j['leave_type'] ?? 'personal',
        startDate: DateTime.parse(j['start_date']),
        endDate: DateTime.parse(j['end_date']),
        reason: j['reason'],
        status: j['status'] ?? 'pending',
        approvedBy: j['approved_by'],
        remarks: j['remarks'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'requester_id': requesterId,
        'requester_type': requesterType,
        'leave_type': leaveType,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'reason': reason,
        'status': status,
      };
}
