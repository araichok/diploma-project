enum UserRole { user, admin }

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String phone;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.user,
    this.phone = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Parses the response from POST /login and GET /profile
  factory User.fromBackendJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: '$firstName $lastName'.trim(),
      role: (json['role'] as String?) == 'admin' ? UserRole.admin : UserRole.user,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String? ?? '',
    email: json['email'] as String? ?? '',
    name: json['name'] as String? ?? '',
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.user,
    ),
    phone: json['phone'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
        : DateTime.now(),
  );
}
