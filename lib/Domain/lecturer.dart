class Lecturer {
  final int lecturerId;
  final int userId;
  final String fullName;

  Lecturer({
    required this.lecturerId,
    required this.userId,
    required this.fullName,
  });

  factory Lecturer.fromFirebase(Map<String, dynamic> json) {
    return Lecturer(
      lecturerId: json['lecturer_id'] as int,
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'lecturer_id': lecturerId,
      'user_id': userId,
      'full_name': fullName,
    };
  }
}
