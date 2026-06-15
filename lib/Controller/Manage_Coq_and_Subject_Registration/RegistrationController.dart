//Controller for faculty registrar Manage the subject(CRUD)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Domain/module_coq.dart' show ModuleCoQ;
import 'package:sams/Domain/registration_subject.dart';
import '../../Domain/course_subject.dart';
import '../../Domain/lecturer.dart';
import 'package:sams/Domain/module_coq.dart';

class RegistrationController {
  // Instance untuk berhubung dengan Firebase Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. FUNGSI CREATE (TAMBAH SUBJEK BARU) ---
  Future<void> createCourse(CourseSubject subject) async {
    try {
      await _db
          .collection('course_subjects') // Tukar di sini
          .doc(subject.subjectId)
          .set(subject.toFirebase());

      print("Course Subject ${subject.subjectName} berjaya didaftarkan!");
    } catch (e) {
      print("Ralat: $e");
      rethrow;
    }
  }

  // Simpan pensyarah baru
  Future<void> createLecturer(Lecturer lecturer) async {
    try {
      await _db
          .collection('lecturers')
          .doc(lecturer.lecturerId.toString())
          .set(lecturer.toFirebase());
    } catch (e) {
      rethrow;
    }
  }

  // Ambil senarai pensyarah (Untuk kegunaan Dropdown di Create Course)
  Stream<List<Lecturer>> getLecturerStream() {
    return _db.collection('lecturers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lecturer.fromFirebase(doc.data());
      }).toList();
    });
  }

  // --- 2. FUNGSI UPDATE (KEMASKINI MAKLUMAT SUBJEK) ---
  // --- FUNGSI UPDATE (EDIT SUBJEK) ---
  Future<void> updateCourse(CourseSubject subject) async {
    try {
      await _db
          .collection('course_subjects')
          .doc(subject.subjectId) // Mencari dokumen berdasarkan ID subjek
          .update(subject.toFirebase());

      print("Course Subject ${subject.subjectName} Successfully updated!");
    } catch (e) {
      print("error: $e");
      rethrow;
    }
  }

  // --- 3. FUNGSI DELETE (UNTUK CRUD) ---
  // --- FUNGSI DELETE (PADAM SUBJEK) ---
  Future<void> deleteCourse(String subjectId) async {
    try {
      await _db
          .collection('course_subjects')
          .doc(subjectId) // Mencari dokumen berdasarkan ID yang dihantar
          .delete();

      print("Course Subject bertipe ID $subjectId successfully deleted!");
    } catch (e) {
      print("Error , failed to delete course subject: $e");
      rethrow;
    }
  }

  //Pusat adab CRUD untuk pusat adab register coq

  // CREATE: Tambah aktiviti CoQ baharu
  Future<void> createCoQ(ModuleCoQ coq) async {
    try {
      await _db.collection('module_coq').doc(coq.coqId).set(coq.toFirebase());
    } catch (e) {
      rethrow;
    }
  }

  // UPDATE: Kemas kini data aktiviti CoQ sedia ada
  Future<void> updateCoQ(ModuleCoQ coq) async {
    try {
      await _db
          .collection('module_coq')
          .doc(coq.coqId)
          .update(coq.toFirebase());
    } catch (e) {
      rethrow;
    }
  }

  // DELETE: Padam aktiviti CoQ
  Future<void> deleteCoQ(String coqId) async {
    try {
      await _db.collection('module_coq').doc(coqId).delete();
    } catch (e) {
      rethrow;
    }
  }
  // ============================================
  // --- FUNGSI COURSE REGISTRATION (STUDENT) ---
  // ============================================

  // Hantar pendaftaran subjek baharu
  Future<void> submitCourseRegistration(RegistrationSubject reg) async {
    try {
      await _db
          .collection('course_registrations')
          .doc(reg.regId)
          .set(reg.toFirebase());
    } catch (e) {
      rethrow;
    }
  }

  // Ambil senarai pendaftaran secara real-time
  Stream<List<RegistrationSubject>> getPendingRegistrations(String studentId) {
    return _db
        .collection('course_registrations')
        .where('student_id', isEqualTo: studentId)
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            var data = doc.data();

            return RegistrationSubject(
              regId: doc.id,
              studentId: data['student_id'] is int
                  ? data['student_id']
                  : (int.tryParse(
                          data['student_id'].toString().replaceAll(
                            RegExp(r'[^0-9]'),
                            '',
                          ),
                        ) ??
                        0),
              fullName: data['full_name'] ?? '',
              programme: data['programme'] ?? '',
              advisorName: data['advisor_name'] ?? '',
              semester: data['semester'] is int
                  ? data['semester']
                  : (int.tryParse(data['semester'].toString()) ?? 1),
              subjectId: data['subject_id'] ?? '',
              subjectName: data['subject_name'] ?? '',
              section: data['section'] ?? '',
              tutorialLab: data['tutorial_lab'] ?? '',
              creditHour: data['credit_hour'] is int ? data['credit_hour'] : 3,
              status: data['status'] ?? 'Pending',
            );
          }).toList();
        });
  }

  // --- FUNGSI UNTUK DROP SUBJEK (STUDENT) ---
  Future<void> dropRegisteredCourse(String regId) async {
    try {
      await _db.collection('course_registrations').doc(regId).delete();

      print("Pendaftaran $regId berjaya digugurkan!");
    } catch (e) {
      print("Ralat semasa drop subjek: $e");
      rethrow;
    }

    // --- FUNGSI SEMAKAN SUBJEK duplicate ---
    Future<bool> isSubjectAlreadyRegistered(
      String studentId,
      String subjectId,
    ) async {
      try {
        // Semak jika ada rekod dengan subjectId dan studentId yang sama
        var result = await _db
            .collection('course_registrations')
            .where('student_id', isEqualTo: studentId)
            .where('subject_id', isEqualTo: subjectId)
            .where('status', isEqualTo: 'Pending')
            .get();

        return result.docs.isNotEmpty; // Pulangkan true jika sudah ada
      } catch (e) {
        print("Ralat semakan: $e");
        return false;
      }
    }
  }

  // ============================================
  // --- FUNGSI CO-Q REGISTRATION (STUDENT) ---
  // ============================================

  // Tempah/daftar aktiviti Co-Q
  Future<void> registerForCoQ(String studentId, ModuleCoQ coq) async {
    final existing = await _db
        .collection('module_coq_registrations')
        .where('student_id', isEqualTo: studentId)
        .where('coq_id', isEqualTo: coq.coqId)
        .where('status', isEqualTo: 'Active')
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('You have already booked this Co-Q activity.');
    }

    await _db.collection('module_coq_registrations').add({
      'student_id': studentId,
      'coq_id': coq.coqId,
      'activity_name': coq.activityName,
      'location': coq.location,
      'lecturer_name': coq.lecturerName,
      'status': 'Active',
    });
  }

  // Senarai pendaftaran Co-Q aktif bagi seorang pelajar (real-time)
  Stream<List<Map<String, dynamic>>> studentCoQRegistrationsStream(
    String studentId,
  ) {
    return _db
        .collection('module_coq_registrations')
        .where('student_id', isEqualTo: studentId)
        .where('status', isEqualTo: 'Active')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['reg_id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Gugurkan pendaftaran Co-Q (Drop)
  Future<void> dropCoQRegistration(String regId) async {
    await _db.collection('module_coq_registrations').doc(regId).delete();
  }
}
