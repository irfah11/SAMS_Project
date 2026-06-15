import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-tap demo dataset for the Manage Attendance module.
///
/// Creates a self-consistent set of users + course/Co-Q data + attendance
/// sessions and records so that EVERY page (all dashboards and every Manage
/// Attendance screen for student / lecturer / Pusat Adab) shows real content.
///
/// It is idempotent: every document uses a deterministic id, so running it
/// again overwrites rather than duplicating. Accounts that already exist are
/// reused (signed in to read back their uid).
///
/// All accounts share the password [password].
class SeedDemoData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String password = 'sams1234';

  // ---- People -------------------------------------------------------------

  static const List<Map<String, dynamic>> lecturers = [
    {'email': 'lecturer1@sams.com', 'name': 'Dr. Ahmad Faizal', 'lecturer_id': 2001},
    {'email': 'lecturer2@sams.com', 'name': 'Dr. Siti Aminah',  'lecturer_id': 2002},
  ];

  static const List<Map<String, dynamic>> students = [
    {'email': 'student1@sams.com', 'name': 'Amir Bin Abdullah',      'student_id': 'CB23001'},
    {'email': 'student2@sams.com', 'name': 'Nurul Huda Binti Razak', 'student_id': 'CB23002'},
    {'email': 'student3@sams.com', 'name': 'Tan Wei Ming',           'student_id': 'CB23003'},
    {'email': 'student4@sams.com', 'name': 'Siti Sarah Binti Omar',  'student_id': 'CB23004'},
    {'email': 'student5@sams.com', 'name': 'Raj Kumar A/L Suresh',   'student_id': 'CB23005'},
  ];

  static const List<Map<String, dynamic>> pusatAdab = [
    {'email': 'adab1@sams.com', 'name': 'Ustaz Hassan'},
    {'email': 'adab2@sams.com', 'name': 'Ustazah Fatimah'},
  ];

  // ---- Courses & Co-Q -----------------------------------------------------

  static const List<Map<String, dynamic>> subjects = [
    {'subject_id': 'BCS2343', 'subject_name': 'Software Engineering Practice',
     'lecturer_name': 'Dr. Ahmad Faizal', 'lecturer_id': 2001},
    {'subject_id': 'BCS2313', 'subject_name': 'Artificial Intelligence Techniques',
     'lecturer_name': 'Dr. Ahmad Faizal', 'lecturer_id': 2001},
    {'subject_id': 'BCN2243', 'subject_name': 'Computer Networks',
     'lecturer_name': 'Dr. Siti Aminah', 'lecturer_id': 2002},
  ];

  static const List<Map<String, dynamic>> coqs = [
    {'coq_id': 'HQS3022', 'activity_name': 'Kayak',
     'lecturer_name': 'Dr. Siti Aminah',  'lecturer_id': 2002,
     'booking_quota': 30, 'location': 'Tasik UMPSA'},
    {'coq_id': 'HQR3032', 'activity_name': 'Basic Fire Safety',
     'lecturer_name': 'Dr. Ahmad Faizal', 'lecturer_id': 2001,
     'booking_quota': 40, 'location': 'Dewan Astaka'},
    {'coq_id': 'HQB1013', 'activity_name': 'Archery',
     'lecturer_name': 'Dr. Siti Aminah',  'lecturer_id': 2002,
     'booking_quota': 25, 'location': 'Padang Kawad'},
  ];

  static const GeoPoint _campus = GeoPoint(3.5568, 103.4268);

  // ~250 km from the Gambang campus (Kuala Lumpur). Used for the demo session
  // that intentionally fails the check-in location check (out of range).
  static const GeoPoint _farLocation = GeoPoint(3.1390, 101.6869);

  /// Run the full seed. Returns a short human-readable summary.
  static Future<String> run() async {
    final nameById = <String, String>{}; // student_id -> full_name

    // 1) Accounts ---------------------------------------------------------
    for (final l in lecturers) {
      final uid = await _ensureAccount(l['email'] as String);
      if (uid == null) continue;
      await _db.collection('users').doc(uid).set({
        'email': l['email'],
        'name': l['name'],
        'role': 'lecturer',
        'lecturer_id': l['lecturer_id'],
      }, SetOptions(merge: true));
      await _db.collection('lecturer').doc('${l['lecturer_id']}').set({
        'lecturer_id': l['lecturer_id'],
        'user_id': l['lecturer_id'],
        'full_name': l['name'],
      });
    }

    for (final s in students) {
      final sid = s['student_id'] as String;
      nameById[sid] = s['name'] as String;
      final uid = await _ensureAccount(s['email'] as String);
      if (uid != null) {
        await _db.collection('users').doc(uid).set({
          'email': s['email'],
          'name': s['name'],
          'role': 'student',
          'student_id': sid,
        }, SetOptions(merge: true));
      }
      await _db.collection('student').doc(sid).set({
        'student_id': sid,
        'full_name': s['name'],
      });
    }

    for (final a in pusatAdab) {
      final uid = await _ensureAccount(a['email'] as String);
      if (uid == null) continue;
      await _db.collection('users').doc(uid).set({
        'email': a['email'],
        'name': a['name'],
        'role': 'adab',
      }, SetOptions(merge: true));
    }

    // 2) Subjects & Co-Q modules -----------------------------------------
    for (final sub in subjects) {
      await _db.collection('course_subjects').doc(sub['subject_id'] as String).set({
        'subject_id': sub['subject_id'],
        'subject_name': sub['subject_name'],
        'section': '01',
        'tutorial_lab': 'Lab 1',
        'capacity': 40,
        'time': DateTime(2026, 4, 2, 8, 0).toIso8601String(),
        'lecturer_name': sub['lecturer_name'],
      });
    }
    for (final c in coqs) {
      await _db.collection('module_coq').doc(c['coq_id'] as String).set({
        'coq_id': c['coq_id'],
        'activity_name': c['activity_name'],
        'booking_quota': c['booking_quota'],
        'location': c['location'],
        'lecturer_name': c['lecturer_name'],
      });
    }

    // 3) Registrations ----------------------------------------------------
    // Register ALL 5 demo students into EVERY subject and Co-Q that exists in
    // Firestore (the seeded ones above + any created manually), so every
    // subject and module has at least 3 (here: 5) registered students.
    final allStudentIds =
        students.map((s) => s['student_id'] as String).toList();

    final subjectDocs = await _db.collection('course_subjects').get();
    for (final doc in subjectDocs.docs) {
      final d = doc.data();
      final sid = (d['subject_id'] as String?)?.trim().isNotEmpty == true
          ? d['subject_id'] as String
          : doc.id;
      final sname = (d['subject_name'] as String?) ?? sid;
      for (final stu in allStudentIds) {
        await _db.collection('course_registrations').doc('${sid}_$stu').set({
          'subject_id': sid,
          'subject_name': sname,
          'student_id': stu,
          'full_name': nameById[stu] ?? stu,
          'status': 'Approved',
        });
      }
    }

    final coqDocs = await _db.collection('module_coq').get();
    for (final doc in coqDocs.docs) {
      final d = doc.data();
      final cid = (d['coq_id'] as String?)?.trim().isNotEmpty == true
          ? d['coq_id'] as String
          : doc.id;
      final cname = (d['activity_name'] as String?) ?? cid;
      for (final stu in allStudentIds) {
        await _db.collection('module_coq_registrations').doc('${cid}_$stu').set({
          'coq_id': cid,
          'activity_name': cname,
          'location': (d['location'] as String?) ?? '',
          'lecturer_name': (d['lecturer_name'] as String?) ?? '',
          'student_id': stu,
          'status': 'Active',
        });
      }
    }

    // 4) Attendance sessions + records -----------------------------------
    final now = DateTime.now();

    for (final sub in subjects) {
      final sid = sub['subject_id'] as String;
      final roster = allStudentIds;
      await _seedSessions(
        keyPrefix: 'SUB_$sid',
        lecturerId: sub['lecturer_id'],
        lecturerName: sub['lecturer_name'] as String,
        subjectId: sid,
        coqId: null,
        subjectName: '${sub['subject_id']} : ${sub['subject_name']}',
        isCoQ: false,
        roster: roster,
        nameById: nameById,
        now: now,
      );
    }

    for (final c in coqs) {
      final cid = c['coq_id'] as String;
      final roster = allStudentIds;
      await _seedSessions(
        keyPrefix: 'COQ_$cid',
        lecturerId: c['lecturer_id'],
        lecturerName: c['lecturer_name'] as String,
        subjectId: null,
        coqId: cid,
        subjectName: '${c['coq_id']} : ${c['activity_name']}',
        isCoQ: true,
        roster: roster,
        nameById: nameById,
        now: now,
      );
    }

    // Leave the user signed out so they can log in fresh.
    await _auth.signOut();

    return 'Seeded ${lecturers.length} lecturers, ${students.length} students, '
        '${pusatAdab.length} Pusat Adab, ${subjects.length} subjects and '
        '${coqs.length} Co-Q modules with sessions & records.';
  }

  // Create three sessions (Passed / Active / Pending) and attendance records
  // for the past + ongoing ones.
  static Future<void> _seedSessions({
    required String keyPrefix,
    required dynamic lecturerId,
    required String lecturerName,
    required String? subjectId,
    required String? coqId,
    required String subjectName,
    required bool isCoQ,
    required List<String> roster,
    required Map<String, String> nameById,
    required DateTime now,
  }) async {
    final plan = [
      {
        'key': 'passed',
        'date': now.subtract(const Duration(days: 7)),
        'status': 'Passed',
        'desc': 'Regular class session',
        'code': '',
        'online': false,
      },
      // Active session is ONLINE so students can check in with just the code
      // (no GPS / location check required).
      {
        'key': 'active',
        'date': now,
        'status': 'Active',
        'desc': 'Online class session',
        'code': 'ABC123',
        'online': true,
      },
      {
        'key': 'pending',
        'date': now.add(const Duration(days: 7)),
        'status': 'Pending',
        'desc': 'Regular class session',
        'code': '',
        'online': false,
      },
      // Active physical session located far from campus, so a student's GPS
      // check fails (out of range). Code: XYZ789.
      {
        'key': 'farloc',
        'date': now,
        'status': 'Active',
        'desc': 'Physical class (location check)',
        'code': 'XYZ789',
        'online': false,
        'far': true,
      },
    ];

    const statuses = ['Present', 'Absent', 'Late'];

    for (final p in plan) {
      final d = p['date'] as DateTime;
      final start = Timestamp.fromDate(DateTime(d.year, d.month, d.day, 8, 0));
      final end = Timestamp.fromDate(DateTime(d.year, d.month, d.day, 10, 0));
      final sessionId = '${keyPrefix}_${p['key']}';
      final isOnline = p['online'] as bool;
      final isFar = p['far'] == true;

      await _db.collection('AttendanceSession').doc(sessionId).set({
        'Lecturer_id': lecturerId,
        'lecturer_name': lecturerName,
        'subject_id': subjectId,
        'coq_id': coqId,
        'subject_name': subjectName,
        'is_coq': isCoQ,
        'is_online': isOnline,
        'start_time': start,
        'end_time': end,
        'session_description': p['desc'],
        'attendance_code': p['code'],
        'session_location':
            isOnline ? null : (isFar ? _farLocation : _campus),
        'radius_meters': 100,
        'session_status': p['status'],
        'created_at': Timestamp.now(),
      });

      // Records: full attendance for the past (Passed) session so View Class
      // Attendant has data. The Active session is left EMPTY on purpose so any
      // enrolled student can still check in (code: ABC123); the Pending session
      // is not open yet.
      if (p['status'] == 'Passed') {
        for (var i = 0; i < roster.length; i++) {
          final stu = roster[i];
          await _db
              .collection('AttendanceRecord')
              .doc('${sessionId}_$stu')
              .set({
            'session_id': sessionId,
            'Student_id': stu,
            'student_name': nameById[stu] ?? stu,
            'status': statuses[i % statuses.length],
            'check_in_time': start,
            'record_location': _campus,
          });
        }
      } else if (p['status'] == 'Active') {
        // Clear any leftover records so every student starts as Pending and
        // can check in (handles re-runs of an earlier seed).
        final existing = await _db
            .collection('AttendanceRecord')
            .where('session_id', isEqualTo: sessionId)
            .get();
        for (final doc in existing.docs) {
          await doc.reference.delete();
        }
      }
    }
  }

  /// Ensure an Auth account exists for [email]; returns its uid.
  static Future<String?> _ensureAccount(String email) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        try {
          final cred = await _auth.signInWithEmailAndPassword(
              email: email, password: password);
          return cred.user?.uid;
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
