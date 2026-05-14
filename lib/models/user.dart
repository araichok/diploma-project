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
    required this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    name: json['name'],
    role: UserRole.values.firstWhere((e) => e.name == json['role']),
    phone: json['phone'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}