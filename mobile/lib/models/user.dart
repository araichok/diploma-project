enum UserRole { user, admin }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String phoneNumber;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.user,
    this.phoneNumber = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory User.fromBackendJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final roleStr = json['role'] as String? ?? 'user';
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: name.isEmpty ? (json['name'] ?? '') : name,
      role: roleStr.toLowerCase() == 'admin' ? UserRole.admin : UserRole.user,
      phoneNumber: json['phone_number'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'first_name': name.split(' ').first,
        'last_name': name.contains(' ') ? name.substring(name.indexOf(' ') + 1) : '',
        'role': role.name,
        'phone_number': phoneNumber,
        'created_at': createdAt.toIso8601String(),
      };
}
