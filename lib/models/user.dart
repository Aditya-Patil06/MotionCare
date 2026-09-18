// lib/models/user.dart
// Specification v7 Section 8.2 & 27: User Model with Role Authentication

enum UserRole { doctor, patient }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  bool get isDoctor => role == UserRole.doctor;
  bool get isPatient => role == UserRole.patient;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.patient,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
