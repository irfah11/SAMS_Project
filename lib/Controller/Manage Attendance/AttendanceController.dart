import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

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

  /// Live stream of AttendanceRecord docs for a session.
  /// Not ordered server-side (would require a composite index) — callers
  /// should sort by student_name client-side.
  static Stream<QuerySnapshot> sessionRecordsStream(String sessionId) {
    return _db
        .collection(_recordsCol)
        .where('session_id', isEqualTo: sessionId)
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
  // SDD class-diagram methods (thin wrappers over the logic above so the
  // implementation matches the design document method names).
  // ================================================================

  /// SDD getAttendanceList(sessionID) — all AttendanceRecords for a session.
  static Future<List<Map<String, dynamic>>> getAttendanceList(
      String sessionId) async {
    final snap = await _db
        .collection(_recordsCol)
        .where('session_id', isEqualTo: sessionId)
        .get();
    return snap.docs.map((d) {
      return {...d.data(), 'record_id': d.id};
    }).toList();
  }

  /// SDD updateAttendanceStatus(studentID, sessionID, newStatus) — set a
  /// student's status for a session, creating the record if none exists.
  static Future<void> updateAttendanceStatus(
      String studentId, String sessionId, String newStatus) async {
    final existing = await _db
        .collection(_recordsCol)
        .where('session_id', isEqualTo: sessionId)
        .where('Student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({'status': newStatus});
    } else {
      await _db.collection(_recordsCol).add({
        'session_id': sessionId,
        'Student_id': studentId,
        'status': newStatus,
        'check_in_time': null,
      });
    }
  }

  /// SDD calculateDistance(lat1, lon1, lat2, lon2) — distance in metres.
  static double calculateDistance(
          double lat1, double lon1, double lat2, double lon2) =>
      Geolocator.distanceBetween(lat1, lon1, lat2, lon2);

  /// SDD validateCheckIn(studentID, inputCode, sLat, sLong) — validates the
  /// code + location and records attendance. Delegates to [checkIn].
  static Future<CheckInResult> validateCheckIn(
    String studentId,
    String inputCode,
    double? sLat,
    double? sLong, {
    required String sessionId,
    required String studentName,
  }) {
    return checkIn(
      sessionId: sessionId,
      studentId: studentId,
      studentName: studentName,
      enteredCode: inputCode,
      studentLat: sLat,
      studentLong: sLong,
    );
  }

  /// Set the attendance status for a roster entry. If [recordId] is null
  /// (the student has no AttendanceRecord yet, i.e. they never checked in),
  /// a new record is created instead of updating an existing one.
  static Future<void> setRecordStatus({
    required String? recordId,
    required String sessionId,
    required String studentId,
    required String studentName,
    required String newStatus,
  }) async {
    if (recordId != null) {
      await updateRecordStatus(recordId, newStatus);
    } else {
      await _db.collection(_recordsCol).add({
        'session_id':    sessionId,
        'Student_id':    studentId,
        'student_name':  studentName,
        'status':        newStatus,
        'check_in_time': null,
      });
    }
  }

  /// All students registered (status 'Approved') for a subject, with their
  /// full names. Used to build the full class roster for "View Attendance".
  static Future<List<Map<String, dynamic>>> fetchSubjectRoster(
      String subjectId) async {
    final snap = await _db
        .collection('course_registrations')
        .where('subject_id', isEqualTo: subjectId)
        .where('status', isEqualTo: 'Approved')
        .get();

    return snap.docs.map((doc) {
      final d = doc.data();
      return {
        'student_id': d['student_id']?.toString() ?? '',
        'full_name':  (d['full_name'] ?? 'Unknown').toString(),
      };
    }).toList();
  }

  /// All students registered (status 'Active') for a Co-Q module, with their
  /// full names looked up from the `student` collection. Used to build the
  /// full roster for Pusat Adab's "View Attendance".
  static Future<List<Map<String, dynamic>>> fetchCoQRoster(
      String coqId) async {
    final regSnap = await _db
        .collection('module_coq_registrations')
        .where('coq_id', isEqualTo: coqId)
        .where('status', isEqualTo: 'Active')
        .get();

    final studentIds = regSnap.docs
        .map((doc) => doc.data()['student_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final names = <String, String>{};
    for (var i = 0; i < studentIds.length; i += 30) {
      final chunk = studentIds.sublist(i, min(i + 30, studentIds.length));
      final stuSnap = await _db
          .collection('student')
          .where('student_id', whereIn: chunk)
          .get();
      for (final doc in stuSnap.docs) {
        final d = doc.data();
        names[d['student_id']?.toString() ?? ''] =
            (d['full_name'] ?? 'Unknown').toString();
      }
    }

    return studentIds
        .map((id) => {'student_id': id, 'full_name': names[id] ?? id})
        .toList();
  }

  /// Merges a class/Co-Q [roster] with the live AttendanceRecord stream for
  /// [sessionId]. Roster entries with no matching record are reported as
  /// 'Absent' with a null record_id (so the UI can create a record on edit).
  static Stream<List<Map<String, dynamic>>> sessionRosterStream({
    required String sessionId,
    required List<Map<String, dynamic>> roster,
  }) {
    return sessionRecordsStream(sessionId).map((snap) {
      final records = <String, QueryDocumentSnapshot>{};
      for (final doc in snap.docs) {
        final sid =
            (doc.data() as Map<String, dynamic>)['Student_id']?.toString() ??
                '';
        records[sid] = doc;
      }

      return roster.map((entry) {
        final sid = entry['student_id'] as String;
        final record = records[sid];
        if (record != null) {
          final d = record.data() as Map<String, dynamic>;
          return {
            'student_id':      sid,
            'full_name':       entry['full_name'],
            'status':          d['status'] ?? 'Present',
            'check_in_time':   d['check_in_time'],
            'record_location': d['record_location'],
            'record_id':       record.id,
          };
        }
        return {
          'student_id':      sid,
          'full_name':       entry['full_name'],
          'status':          'Absent',
          'check_in_time':   null,
          'record_location': null,
          'record_id':       null,
        };
      }).toList();
    });
  }

  // ================================================================
  // LECTURER
  // ================================================================

  /// Load the subjects and CoQ modules assigned to this lecturer.
  /// [lecturerId] is the numeric ID (kept for API compatibility, currently unused).
  /// [lecturerName] is the display name used by both course_subjects.lecturer_name
  /// and module_coq.lecturer_name (neither collection has a Lecturer_id field).
  /// Returns a list of maps with keys: id, name, isCoQ.
  static Future<List<Map<String, dynamic>>> fetchLecturerClasses(
      dynamic lecturerId, {String lecturerName = ''}) async {
    final list = <Map<String, dynamic>>[];

    if (lecturerName.isNotEmpty) {
      final subSnap = await _db
          .collection('course_subjects')
          .where('lecturer_name', isEqualTo: lecturerName)
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
          .where('lecturer_name', isEqualTo: lecturerName)
          .get();
      for (final doc in coqSnap.docs) {
        final d = doc.data();
        list.add({
          'id':    d['coq_id'] ?? doc.id,
          'name':  d['activity_name'] ?? 'Unknown Activity',
          'isCoQ': true,
        });
      }
    }

    return list;
  }

  /// Live stream of AttendanceSessions for a lecturer, optionally filtered
  /// by subjectId or coqId. Not ordered server-side (would require a
  /// composite index) — callers should sort by start_time client-side.
  static Stream<QuerySnapshot> lecturerSessionsStream({
    required dynamic lecturerId,
    String? subjectId,
    String? coqId,
  }) {
    Query q = _db
        .collection(_sessionsCol)
        .where('Lecturer_id', isEqualTo: lecturerId);

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

    // course_registrations stores student_id as String (e.g. "CB23038")
    // No status filter — approval screen not yet wired to Firestore
    final regSnap = await _db
        .collection('course_registrations')
        .where('student_id', isEqualTo: studentId)
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
        .collection('module_coq_registrations')
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

  /// Live stream of AttendanceSessions for a subject or CoQ. Intended for
  /// the student "List Class" screen. Not ordered server-side (would
  /// require a composite index) — callers should sort by start_time
  /// client-side.
  static Stream<QuerySnapshot> studentSessionsStream({
    String? subjectId,
    String? coqId,
  }) {
    Query q = _db.collection(_sessionsCol);

    if (subjectId != null) {
      q = q.where('subject_id', isEqualTo: subjectId);
    } else if (coqId != null) {
      q = q.where('coq_id', isEqualTo: coqId);
    }

    return q.snapshots();
  }

  /// Submit a check-in for a student.
  /// Validates that the session is Active, the entered code is correct, and
  /// — unless the session is online or has no location set — that the
  /// student's detected GPS position is within [radius_meters] of the
  /// session's location, then upserts an AttendanceRecord (one per student
  /// per session).
  static Future<CheckInResult> checkIn({
    required String sessionId,
    required String studentId,
    required String studentName,
    required String enteredCode,
    double? studentLat,
    double? studentLong,
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
              'You had enter the wrong code for Check-In your attendance.');
    }

    final isOnline = data['is_online'] as bool? ?? false;
    final sessionLoc = data['session_location'] as GeoPoint?;
    final radiusMeters = (data['radius_meters'] as num?)?.toDouble() ?? 100;

    if (!isOnline &&
        sessionLoc != null &&
        studentLat != null &&
        studentLong != null) {
      final distance = calculateDistance(
        studentLat,
        studentLong,
        sessionLoc.latitude,
        sessionLoc.longitude,
      );
      if (distance > radiusMeters) {
        return const CheckInResult(
            success: false,
            message: 'Your location for Check-In is out of range.');
      }
    }

    final studentLoc = (studentLat != null && studentLong != null)
        ? GeoPoint(studentLat, studentLong)
        : null;

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
        'record_location': ?studentLoc,
      });
    } else {
      await existing.docs.first.reference.update({
        'status':        'Present',
        'check_in_time': Timestamp.now(),
        'record_location': ?studentLoc,
      });
    }

    return const CheckInResult(
        success: true,
        message:
            'You had successfully Check-In your attendance.');
  }

  // ================================================================
  // PUSAT ADAB
  // ================================================================

  /// Live stream of all Co-Q modules, ordered by activityName.
  static Stream<QuerySnapshot> coqModulesStream() {
    return _db
        .collection('module_coq')
        .orderBy('activity_name')
        .snapshots();
  }

  /// Live stream of AttendanceSessions for a Co-Q module. Not ordered
  /// server-side (would require a composite index) — callers should sort
  /// by start_time client-side.
  static Stream<QuerySnapshot> sessionsByCoQStream(String coqId) {
    return _db
        .collection(_sessionsCol)
        .where('coq_id', isEqualTo: coqId)
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
