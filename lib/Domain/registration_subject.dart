// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationSubject {
  final String regId; // ID dokumen unik pendaftaran
  final int studentId;
  final String fullName;
  final String programme;
  final String advisorName;
  final int semester;
  final String subjectId;
  final String subjectName;
  final String section;
  final String tutorialLab;
  final int creditHour;
  final String status; // 'Pending', 'Approved', 'Rejected'

  RegistrationSubject({
    required this.regId,
    required this.studentId,
    required this.fullName,
    required this.programme,
    required this.advisorName,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.section,
    required this.tutorialLab,
    this.creditHour = 3, // Default nilai mengikut lakaran UI
    this.status = 'Pending',
  });

  factory RegistrationSubject.fromFirebase(Map<String, dynamic> json) {
    return RegistrationSubject(
      regId: json['reg_id'] as String,
      studentId: json['student_id'] as int,
      fullName: json['full_name'] as String,
      programme: json['programme'] as String,
      advisorName: json['advisor_name'] as String,
      semester: json['semester'] as int,
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      section: json['section'] as String,
      tutorialLab: json['tutorial_lab'] as String,
      creditHour: json['credit_hour'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'reg_id': regId,
      'student_id': studentId,
      'full_name': fullName,
      'programme': programme,
      'advisor_name': advisorName,
      'semester': semester,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'section': section,
      'tutorial_lab': tutorialLab,
      'credit_hour': creditHour,
      'status': status,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
