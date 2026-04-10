enum UserRole { admin, teacher, student, parent }

extension UserRoleExt on UserRole {
  String get name => ['admin', 'teacher', 'student', 'parent'][index];
  String get label => ['Administrator', 'Teacher', 'Student', 'Parent'][index];
  static UserRole fromString(String s) =>
      UserRole.values.firstWhere((r) => r.name == s, orElse: () => UserRole.student);
}

class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'],
        email: j['email'],
        fullName: j['full_name'],
        role: UserRoleExt.fromString(j['role'] ?? 'student'),
        phone: j['phone'],
        avatarUrl: j['avatar_url'],
        isActive: j['is_active'] ?? true,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'full_name': fullName,
        'role': role.name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'is_active': isActive,
      };

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}
