import 'package:cloud_firestore/cloud_firestore.dart';

class QuizAttempt {
  final String attemptId; // Unique ID for this specific attempt document
  final String quizId; // Links back to the quiz being taken
  final String studentId; // Links to the student who took it
  final int score; // The student's final score
  final DateTime?
  takenAt; // Optional: highly recommended for tracking *when* they took it

  QuizAttempt({
    required this.attemptId,
    required this.quizId,
    required this.studentId,
    required this.score,
    this.takenAt,
  });

  // Factory constructor to parse data coming from Firebase Firestore
  factory QuizAttempt.fromFirebase(Map<String, dynamic> json) {
    return QuizAttempt(
      attemptId: json['attempt_id'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      score: (json['score'] as num? ?? 0)
          .toInt(), // Safe casting in case Firebase returns a double
      takenAt: json['taken_at'] != null
          ? (json['taken_at'] as Timestamp).toDate()
          : null,
    );
  }

  // Method to convert the object into a Map structure to write into Firebase
  Map<String, dynamic> toFirebase() {
    return {
      'attempt_id': attemptId,
      'quiz_id': quizId,
      'student_id': studentId,
      'score': score,
      if (takenAt != null) 'taken_at': Timestamp.fromDate(takenAt!),
    };
  }
}
