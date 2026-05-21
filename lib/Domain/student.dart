class Student {
  final int studentId; // Primary Key (PK) - Integer
  final int userId; // Foreign Key (FK) - Integer
  final String fullName; // Not Null - String
  final String programme; // Not Null - String
  final int semester; // Not Null - Integer
  final String advisorName; // Foreign Key (FK) - String

  Student({
    required this.studentId,
    required this.userId,
    required this.fullName,
    required this.programme,
    required this.semester,
    required this.advisorName,
  });

  // Fungsi untuk menukar data JSON dari Firebase kepada Objek Student Flutter
  factory Student.fromFirebase(Map<String, dynamic> json) {
    return Student(
      studentId: json['student_id'] as int,
      userId: json['user_id'] as int,
      fullName: json['full_name'] as String,
      programme: json['programme'] as String,
      semester: json['semester'] as int,
      advisorName: json['advisor_name'] as String,
    );
  }

  // Fungsi untuk menukar Objek Student Flutter kepada format JSON Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'student_id': studentId,
      'user_id': userId,
      'full_name': fullName,
      'programme': programme,
      'semester': semester,
      'advisor_name': advisorName,
    };
  }
}
