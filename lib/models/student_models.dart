class Student {
  final String id;
  final String? profileId;
  final String rollNumber;
  final String? admissionNumber;
  final String? formNumber;
  final String? scholarNumber;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? city;
  final String? state;
  // Parent / family
  final String? parentId;
  final String? parentName;
  final String? fatherName;
  final String? motherName;
  final String? guardianName;
  final String? parentPhone;
  final String? officePhone;
  final String? parentEmail;
  final String? fatherOccupation;
  final String? fatherQualification;
  final String? motherQualification;
  // Identity
  final String? udiseNumber;
  final String? aadharNumber;
  // Bank
  final String? bankAccountNumber;
  final String? ifscCode;
  // Previous education
  final String? lastPassedClass;
  final String? lastPassedYear;
  final String? lastPassedPercentage;
  final String? lastPassedTotal;
  // Category
  final String? category; // general | obc | sc | st
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
    this.formNumber,
    this.scholarNumber,
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
    this.fatherName,
    this.motherName,
    this.guardianName,
    this.parentPhone,
    this.officePhone,
    this.parentEmail,
    this.fatherOccupation,
    this.fatherQualification,
    this.motherQualification,
    this.udiseNumber,
    this.aadharNumber,
    this.bankAccountNumber,
    this.ifscCode,
    this.lastPassedClass,
    this.lastPassedYear,
    this.lastPassedPercentage,
    this.lastPassedTotal,
    this.category,
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
        formNumber: j['form_number'],
        scholarNumber: j['scholar_number'],
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
        fatherName: j['father_name'],
        motherName: j['mother_name'],
        guardianName: j['guardian_name'],
        parentPhone: j['parent_phone'],
        officePhone: j['office_phone'],
        parentEmail: j['parent_email'],
        fatherOccupation: j['father_occupation'],
        fatherQualification: j['father_qualification'],
        motherQualification: j['mother_qualification'],
        udiseNumber: j['udise_number'],
        aadharNumber: j['aadhar_number'],
        bankAccountNumber: j['bank_account_number'],
        ifscCode: j['ifsc_code'],
        lastPassedClass: j['last_passed_class'],
        lastPassedYear: j['last_passed_year'],
        lastPassedPercentage: j['last_passed_percentage'],
        lastPassedTotal: j['last_passed_total'],
        category: j['category'],
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
        'form_number': formNumber,
        'scholar_number': scholarNumber,
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
        'father_name': fatherName,
        'mother_name': motherName,
        'guardian_name': guardianName,
        'parent_phone': parentPhone,
        'office_phone': officePhone,
        'parent_email': parentEmail,
        'father_occupation': fatherOccupation,
        'father_qualification': fatherQualification,
        'mother_qualification': motherQualification,
        'udise_number': udiseNumber,
        'aadhar_number': aadharNumber,
        'bank_account_number': bankAccountNumber,
        'ifsc_code': ifscCode,
        'last_passed_class': lastPassedClass,
        'last_passed_year': lastPassedYear,
        'last_passed_percentage': lastPassedPercentage,
        'last_passed_total': lastPassedTotal,
        'category': category,
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
