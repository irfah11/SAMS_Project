import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================
// MODEL — AttendanceSession
// Maps to the 'AttendanceSession' collection in Firestore.
// =============================================================
class AttendanceSession {
  final String sessionId; // Firestore document ID
  final String lecturerId;
  final String lecturerName;
  final String subjectId;
  final String coqId;
  final String subjectName;
  final bool isCoq;
  final DateTime startTime;
  final DateTime endTime;
  final String sessionDescription;
  final String attendanceCode;
  final GeoPoint sessionLocation;
  final int radiusMeters;
  final String sessionStatus;
  final DateTime createdAt;

  const AttendanceSession({
    required this.sessionId,
    required this.lecturerId,
    required this.lecturerName,
    required this.subjectId,
    required this.coqId,
    required this.subjectName,
    required this.isCoq,
    required this.startTime,
    required this.endTime,
    required this.sessionDescription,
    required this.attendanceCode,
    required this.sessionLocation,
    required this.radiusMeters,
    required this.sessionStatus,
    required this.createdAt,
  });

  static String _toString(dynamic value) => value?.toString() ?? '';

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Unsupported date format: $value');
  }

  static GeoPoint _toGeoPoint(dynamic value) {
    if (value is GeoPoint) return value;
    throw ArgumentError('Unsupported GeoPoint format: $value');
  }

  factory AttendanceSession.fromFirebase(Map<String, dynamic> json, {String? docId}) {
    return AttendanceSession(
      sessionId: (docId ?? json['session_id'] ?? '').toString(),
      lecturerId: _toString(json['Lecturer_id']),
      lecturerName: _toString(json['lecturer_name']),
      subjectId: _toString(json['subject_id']),
      coqId: _toString(json['coq_id']),
      subjectName: _toString(json['subject_name']),
      isCoq: _toBool(json['is_coq']),
      startTime: _toDateTime(json['start_time']),
      endTime: _toDateTime(json['end_time']),
      sessionDescription: _toString(json['session_description']),
      attendanceCode: _toString(json['attendance_code']),
      sessionLocation: _toGeoPoint(json['session_location']),
      radiusMeters: _toInt(json['radius_meters']),
      sessionStatus: _toString(json['session_status']),
      createdAt: _toDateTime(json['created_at']),
    );
  }

  factory AttendanceSession.fromFirestore(DocumentSnapshot doc) {
    return AttendanceSession.fromFirebase(
      doc.data() as Map<String, dynamic>,
      docId: doc.id,
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'Lecturer_id': lecturerId,
      'lecturer_name': lecturerName,
      'subject_id': subjectId,
      'coq_id': coqId,
      'subject_name': subjectName,
      'is_coq': isCoq,
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'session_description': sessionDescription,
      'attendance_code': attendanceCode,
      'session_location': sessionLocation,
      'radius_meters': radiusMeters,
      'session_status': sessionStatus,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
