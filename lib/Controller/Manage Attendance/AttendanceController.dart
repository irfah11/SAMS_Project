import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================
// CONTROLLER — AttendanceController
// Single entry point for all Manage Attendance Firestore access:
//   LECTURER  : fetch classes, CRUD sessions, generate code, view records
//   STUDENT   : fetch subjects, list sessions, check-in
//   PUSAT ADAB: list CoQ modules, view sessions, update record status
// UI widgets stay in the screen files; only logic lives here.
// =============================================================
class AttendanceController {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _sessionsCol = 'AttendanceSession';
  static const _recordsCol  = 'AttendanceRecord';

  // ================================================================
  // SHARED
  // ================================================================

  /// Live stream of AttendanceRecord docs for a session, ordered by name.
  static Stream<QuerySnapshot> sessionRecordsStream(String sessionId) {
    return _db
        .collection(_recordsCol)
        .where('session_id', isEqualTo: sessionId)
        .orderBy('student_name')
        .snapshots();
  }

  /// Update the attendance status ('Present' | 'Absent' | 'Late') for one record.
  static Future<void> updateRecordStatus(
      String recordId, String newStatus) async {
    await _db
        .collection(_recordsCol)
        .doc(recordId)
        .update({'status': newStatus});
  }

  // ================================================================
  // LECTURER
  // ================================================================

  /// Load the subjects and CoQ modules assigned to this lecturer.
  /// Returns a list of maps with keys: id, name, isCoQ.
  static Future<List<Map<String, dynamic>>> fetchLecturerClasses(
      dynamic lecturerId) async {
    final list = <Map<String, dynamic>>[];

    final subSnap = await _db
        .collection('course_subjects')
        .where('Lecturer_id', isEqualTo: lecturerId)
        .get();
    for (final doc in subSnap.docs) {
      final d = doc.data();
      list.add({
        'id':    d['subject_id'] ?? doc.id,
        'name':  d['subject_name'] ?? 'Unknown Subject',
        'isCoQ': false,
      });
    }

    final coqSnap = await _db
        .collection('module_coq')
        .where('Lecturer_id', isEqualTo: lecturerId)
        .get();
    for (final doc in coqSnap.docs) {
      final d = doc.data();
      list.add({
        'id':    d['coq_id'] ?? doc.id,
        'name':  d['activity_name'] ?? 'Unknown Activity',
        'isCoQ': true,
      });
    }

    return list;
  }

  /// Live stream of AttendanceSessions for a lecturer, optionally filtered
  /// by subjectId or coqId, ordered by start_time ascending.
  static Stream<QuerySnapshot> lecturerSessionsStream({
    required dynamic lecturerId,
    String? subjectId,
    String? coqId,
  }) {
    Query q = _db
        .collection(_sessionsCol)
        .where('Lecturer_id', isEqualTo: lecturerId)
        .orderBy('start_time');

    if (subjectId != null) {
      q = q.where('subject_id', isEqualTo: subjectId);
    } else if (coqId != null) {
      q = q.where('coq_id', isEqualTo: coqId);
    }

    return q.snapshots();
  }

  /// Create a new AttendanceSession. Returns the new document ID.
  /// Location is simulated (UMPSA Gambang campus coordinates).
  static Future<String> createSession({
    required dynamic lecturerId,
    required String subjectName,
    String? subjectId,
    String? coqId,
    required bool isCoQ,
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required String sessionDescription,
    int radiusMeters = 100,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userDoc = await _db.collection('users').doc(uid).get();
    final lecturerName =
        userDoc.data()?['name'] as String? ?? 'Lecturer';

    final start = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, startHour, startMinute));
    final end = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, endHour, endMinute));

    final docRef = await _db.collection(_sessionsCol).add({
      'Lecturer_id':         lecturerId,
      'lecturer_name':       lecturerName,
      'subject_id':          subjectId,
      'coq_id':              coqId,
      'subject_name':        subjectName,
      'is_coq':              isCoQ,
      'start_time':          start,
      'end_time':            end,
      'session_description': sessionDescription,
      'attendance_code':     '',
      'session_location':    const GeoPoint(3.5568, 103.4268),
      'radius_meters':       radiusMeters,
      'session_status':      'Pending',
      'created_at':          Timestamp.now(),
    });

    return docRef.id;
  }

  /// Update mutable fields of an existing session.
  static Future<void> updateSession(
    String sessionId, {
    required DateTime date,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    required String sessionDescription,
    required int radiusMeters,
  }) async {
    final start = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, startHour, startMinute));
    final end = Timestamp.fromDate(
        DateTime(date.year, date.month, date.day, endHour, endMinute));

    await _db.collection(_sessionsCol).doc(sessionId).update({
      'start_time':          start,
      'end_time':            end,
      'session_description': sessionDescription,
      'radius_meters':       radiusMeters,
    });
  }

  /// Delete a session and all its AttendanceRecord children.
  /// Throws [SessionPassedException] if the session is already 'Passed'.
  static Future<void> deleteSession(String sessionId) async {
    final sessionDoc =
        await _db.collection(_sessionsCol).doc(sessionId).get();

    if (sessionDoc.exists) {
      final status =
          sessionDoc.data()?['session_status'] as String? ?? '';
      if (status == 'Passed') {
        throw const SessionPassedException();
      }
    }

    final records = await _db
        .collection(_recordsCol)
        .where('session_id', isEqualTo: sessionId)
        .get();

    final batch = _db.batch();
    for (final doc in records.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection(_sessionsCol).doc(sessionId));
    await batch.commit();
  }

  /// Generate a unique 6-character attendance code and activate the session.
  /// Returns the generated code.
  static Future<String> generateCode(String sessionId) async {
    final code = await _generateUniqueCode();
    await _db.collection(_sessionsCol).doc(sessionId).update({
      'attendance_code': code,
      'session_status':  'Active',
    });
    return code;
  }

  static String _randomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }

  static Future<String> _generateUniqueCode() async {
    String code;
    bool isUnique = false;
    do {
      code = _randomCode();
      final existing = await _db
          .collection(_sessionsCol)
          .where('attendance_code', isEqualTo: code)
          .where('session_status', isEqualTo: 'Active')
          .limit(1)
          .get();
      isUnique = existing.docs.isEmpty;
    } while (!isUnique);
    return code;
  }

  // ================================================================
  // STUDENT
  // ================================================================

  /// Load the student's enrolled subjects and active CoQ registrations.
  /// [studentId] is the matric number (e.g. "CB23028"), not the Auth UID.
  /// Returns a list of maps with keys: id, name, isCoQ.
  static Future<List<Map<String, dynamic>>> fetchStudentSubjects(
      String studentId) async {
    final list = <Map<String, dynamic>>[];

    final regSnap = await _db
        .collection('course_registration')
        .where('student_id', isEqualTo: studentId)
        .where('status', isEqualTo: 'Approved')
        .get();
    for (final doc in regSnap.docs) {
      final d = doc.data();
      list.add({
        'id':    d['subject_id'] ?? doc.id,
        'name':  d['subject_name'] ?? 'Unknown Subject',
        'isCoQ': false,
      });
    }

    final coqSnap = await _db
        .collection('coq_registration')
        .where('student_id', isEqualTo: studentId)
        .where('status', isEqualTo: 'Active')
        .get();
    for (final doc in coqSnap.docs) {
      final d = doc.data();
      list.add({
        'id':    d['coq_id'] ?? doc.id,
        'name':  d['activity_name'] ?? 'Unknown Activity',
        'isCoQ': true,
      });
    }

    return list;
  }

  /// Live stream of AttendanceSessions for a subject or CoQ, ordered by
  /// start_time. Intended for the student "List Class" screen.
  static Stream<QuerySnapshot> studentSessionsStream({
    String? subjectId,
    String? coqId,
  }) {
    Query q = _db
        .collection(_sessionsCol)
        .orderBy('start_time');

    if (subjectId != null) {
      q = q.where('subject_id', isEqualTo: subjectId);
    } else if (coqId != null) {
      q = q.where('coq_id', isEqualTo: coqId);
    }

    return q.snapshots();
  }

  /// Submit a check-in for a student.
  /// Validates that the session is Active and the entered code is correct,
  /// then upserts an AttendanceRecord (one per student per session).
  static Future<CheckInResult> checkIn({
    required String sessionId,
    required String studentId,
    required String studentName,
    required String enteredCode,
  }) async {
    final sessionDoc =
        await _db.collection(_sessionsCol).doc(sessionId).get();

    if (!sessionDoc.exists) {
      return const CheckInResult(
          success: false, message: 'Session not found.');
    }

    final data   = sessionDoc.data()!;
    final code   = (data['attendance_code'] as String? ?? '').toUpperCase();
    final status = data['session_status'] as String? ?? '';

    if (status != 'Active') {
      return const CheckInResult(
          success: false,
          message: 'This session is not currently active.');
    }

    if (enteredCode.toUpperCase() != code) {
      return const CheckInResult(
          success: false,
          message:
              'Attendance Check-In Failed.\nYou had enter the wrong code.');
    }

    const GeoPoint studentLoc = GeoPoint(3.5568, 103.4268);

    final existing = await _db
        .collection(_recordsCol)
        .where('session_id', isEqualTo: sessionId)
        .where('Student_id', isEqualTo: studentId)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await _db.collection(_recordsCol).add({
        'session_id':      sessionId,
        'Student_id':      studentId,
        'student_name':    studentName,
        'check_in_time':   Timestamp.now(),
        'status':          'Present',
        'record_location': studentLoc,
      });
    } else {
      await existing.docs.first.reference.update({
        'status':        'Present',
        'check_in_time': Timestamp.now(),
      });
    }

    return const CheckInResult(
        success: true,
        message:
            'Attendance Check-In Successful!\nYou have been marked as Present.');
  }

  // ================================================================
  // PUSAT ADAB
  // ================================================================

  /// Live stream of all Co-Q modules, ordered by activityName.
  static Stream<QuerySnapshot> coqModulesStream() {
    return _db
        .collection('moduleCoQ')
        .orderBy('activityName')
        .snapshots();
  }

  /// Live stream of AttendanceSessions for a Co-Q module, ordered by
  /// start_time ascending.
  static Stream<QuerySnapshot> sessionsByCoQStream(String coqId) {
    return _db
        .collection(_sessionsCol)
        .where('coq_id', isEqualTo: coqId)
        .orderBy('start_time')
        .snapshots();
  }
}

// ================================================================
// Result types
// ================================================================

class CheckInResult {
  final bool success;
  final String message;
  const CheckInResult({required this.success, required this.message});
}

class SessionPassedException implements Exception {
  const SessionPassedException();
  @override
  String toString() =>
      'This session has been completed (Passed) and cannot be deleted.';
}
