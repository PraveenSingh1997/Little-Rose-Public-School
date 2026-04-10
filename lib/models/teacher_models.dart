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
