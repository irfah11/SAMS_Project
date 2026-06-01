import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================
// MODEL — Student (Data Dictionary 3.3.2)
// Maps to the 'student' collection in Firestore.
// Document ID = student_id (e.g. "CB23076").
// =============================================================
class Student {
  final String studentId;   // PK — also the document ID
  final String userId;      // FK → users/{uid}
  final String fullName;
  final String programme;
  final int semester;       // current semester (single source of truth)
  final String advisorName; // FK → a lecturers document

  const Student({
    required this.studentId,
    required this.userId,
    required this.fullName,
    required this.programme,
    required this.semester,
    required this.advisorName,
  });

  // Tolerant int parse — Firestore may store the value as int, double or String.
  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  // Convert a Firestore JSON map into a Student object.
  // [docId] lets us fall back to the document ID when student_id is absent.
  factory Student.fromFirebase(Map<String, dynamic> json, {String? docId}) {
    return Student(
      studentId: (json['student_id'] ?? docId ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      programme: (json['programme'] ?? '').toString(),
      semester: _toInt(json['semester']),
      advisorName: (json['advisor_name'] ?? '').toString(),
    );
  }

  // Convenience: build straight from a Firestore document snapshot.
  factory Student.fromFirestore(DocumentSnapshot doc) {
    return Student.fromFirebase(
      doc.data() as Map<String, dynamic>,
      docId: doc.id,
    );
  }

  // Convert a Student object back to the Firestore JSON format.
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
