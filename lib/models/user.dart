class User {
  final String id;
  final String username;
  final String password;
  final String email;
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
