// ignore: file_names
class User {
  final int userId; // Unique identifier for each user login
  final String username; // Unique login name
  final String password; // Encrypted password
  final String role; // Student, Lecturer, Registrar, or Pusat Adab

  User({
    required this.userId,
    required this.username,
    required this.password,
    required this.role,
  });

  // Fungsi untuk menukar data dari Firebase/Map ke Objek User
  factory User.fromFirebase(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      role: json['role'] as String,
    );
  }

  // Fungsi untuk menukar Objek User ke format Map untuk disimpan ke Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'user_id': userId,
      'username': username,
      'password': password,
      'role': role,
    };
  }
}
