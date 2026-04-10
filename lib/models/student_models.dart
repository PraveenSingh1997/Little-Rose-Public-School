class Student {
  final String id;
  final String? profileId;
  final String rollNumber;
  final String? admissionNumber;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? city;
  final String? state;
  final String? parentId;
  final String? parentName;
  final String? parentPhone;
  final String? parentEmail;
  final String? classId;
  final DateTime admissionDate;
  final String status;
  final String? photoUrl;
  final DateTime createdAt;

  const Student({
    required this.id,
    this.profileId,
    required this.rollNumber,
    this.admissionNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.city,
    this.state,
    this.parentId,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.classId,
    required this.admissionDate,
    this.status = 'active',
    this.photoUrl,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';
  bool get isActive => status == 'active';

  int get age {
    final now = DateTime.now();
    int a = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      a--;
    }
    return a;
  }

  factory Student.fromJson(Map<String, dynamic> j) => Student(
        id: j['id'],
        profileId: j['profile_id'],
        rollNumber: j['roll_number'],
        admissionNumber: j['admission_number'],
        firstName: j['first_name'],
        lastName: j['last_name'],
        dateOfBirth: j['date_of_birth'] != null
            ? DateTime.tryParse(j['date_of_birth']) ?? DateTime(2010)
            : DateTime(2010),
        gender: j['gender'],
        bloodGroup: j['blood_group'],
        address: j['address'],
        city: j['city'],
        state: j['state'],
        parentId: j['parent_id'],
        parentName: j['parent_name'],
        parentPhone: j['parent_phone'],
        parentEmail: j['parent_email'],
        classId: j['class_id'],
        admissionDate: DateTime.parse(j['admission_date']),
        status: j['status'] ?? 'active',
        photoUrl: j['photo_url'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'profile_id': profileId,
        'roll_number': rollNumber,
        'admission_number': admissionNumber,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        'gender': gender,
        'blood_group': bloodGroup,
        'address': address,
        'city': city,
        'state': state,
        'parent_id': parentId,
        'parent_name': parentName,
        'parent_phone': parentPhone,
        'parent_email': parentEmail,
        'class_id': classId,
        'admission_date': admissionDate.toIso8601String().split('T')[0],
        'status': status,
        'photo_url': photoUrl,
      };

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}
