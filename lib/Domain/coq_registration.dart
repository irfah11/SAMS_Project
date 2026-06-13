import 'package:cloud_firestore/cloud_firestore.dart';

class CoqRegistration {
  final String registrationId;
  final String studentId;
  final String moduleDocId;
  final String coqId;
  final String activityName;
  final String lecturerName;
  final String location;
  final dynamic date;
  final dynamic time;
  final String status;
  final dynamic createdAt;

  CoqRegistration({
    required this.registrationId,
    required this.studentId,
    required this.moduleDocId,
    required this.coqId,
    required this.activityName,
    required this.lecturerName,
    required this.location,
    required this.date,
    required this.time,
    required this.status,
    this.createdAt,
  });

  factory CoqRegistration.fromFirebase(
    Map<String, dynamic> data,
    String docId,
  ) {
    return CoqRegistration(
      registrationId: data['registration_id'] ?? docId,
      studentId: data['student_id'] ?? '',
      moduleDocId: data['module_doc_id'] ?? '',
      coqId: data['coq_id'] ?? '',
      activityName: data['activity_name'] ?? '',
      lecturerName: data['lecturer_name'] ?? '',
      location: data['location'] ?? '',
      date: data['date'],
      time: data['time'],
      status: data['status'] ?? 'Registered',
      createdAt: data['created_at'],
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'registration_id': registrationId,
      'student_id': studentId,
      'module_doc_id': moduleDocId,
      'coq_id': coqId,
      'activity_name': activityName,
      'lecturer_name': lecturerName,
      'location': location,
      'date': date,
      'time': time,
      'status': status,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
