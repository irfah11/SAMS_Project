import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================
// MODEL — AttendanceRecord
// Maps to the 'AttendanceRecord' collection in Firestore.
// =============================================================
class AttendanceRecord {
  final String attendanceId; // Firestore document ID
  final String sessionId;
  final String studentId;
  final String studentName;
  final DateTime? checkInTime;
  final String status;
  final GeoPoint? recordLocation;

  const AttendanceRecord({
    required this.attendanceId,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.checkInTime,
    required this.status,
    required this.recordLocation,
  });

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String _toString(dynamic value) {
    return value?.toString() ?? '';
  }

  factory AttendanceRecord.fromFirebase(Map<String, dynamic> json, {String? docId}) {
    return AttendanceRecord(
      attendanceId: (docId ?? json['attendance_id'] ?? '').toString(),
      sessionId: _toString(json['session_id']),
      studentId: _toString(json['Student_id']),
      studentName: _toString(json['student_name']),
      checkInTime: _toDateTime(json['check_in_time']),
      status: _toString(json['status']),
      recordLocation: json['record_location'] is GeoPoint
          ? json['record_location'] as GeoPoint
          : null,
    );
  }

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    return AttendanceRecord.fromFirebase(
      doc.data() as Map<String, dynamic>,
      docId: doc.id,
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'session_id': sessionId,
      'Student_id': studentId,
      'student_name': studentName,
      if (checkInTime != null) 'check_in_time': Timestamp.fromDate(checkInTime!),
      'status': status,
      if (recordLocation != null) 'record_location': recordLocation,
    };
  }
}
