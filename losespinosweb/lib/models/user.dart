enum UserRole { admin, client }

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isClient => role == UserRole.client;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'role': role.toString(),
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
        role: json['role'] == 'UserRole.admin' 
            ? UserRole.admin 
            : UserRole.client,
      );
}