//Controller for faculty registrar Manage the subject(CRUD)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Domain/module_coq.dart' show ModuleCoQ;
import 'package:sams/Domain/registration_subject.dart';
import '../../Domain/course_subject.dart';
import '../../Domain/lecturer.dart';
import 'package:sams/Domain/module_coq.dart';
import 'package:sams/Domain/coq_registration.dart';

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
      print("Ralat semasa submit registration: $e");
      rethrow;
    }
  }

  // Function umum: ambil subject ikut status
  Stream<List<RegistrationSubject>> getRegistrationsByStatus(
    String studentId,
    String status,
  ) {
    return _db
        .collection('course_registrations')
        .where('student_id', isEqualTo: studentId)
        .where('status', isEqualTo: status)
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
              creditHour: data['credit_hour'] is int
                  ? data['credit_hour']
                  : (int.tryParse(data['credit_hour'].toString()) ?? 3),
              status: data['status'] ?? status,
            );
          }).toList();
        });
  }

  // Untuk page Course Registration for approval
  Stream<List<RegistrationSubject>> getPendingRegistrations(String studentId) {
    return getRegistrationsByStatus(studentId, 'Pending');
  }

  // Untuk page Course Registration
  Stream<List<RegistrationSubject>> getApprovedRegistrations(String studentId) {
    return getRegistrationsByStatus(studentId, 'Approved');
  }

  // Drop subject yang masih Pending
  Future<void> dropRegisteredCourse(String regId) async {
    try {
      await _db.collection('course_registrations').doc(regId).delete();

      print("Pendaftaran $regId berjaya digugurkan!");
    } catch (e) {
      print("Ralat semasa drop subjek: $e");
      rethrow;
    }
  }

  // Semak duplicate subject
  Future<bool> isSubjectAlreadyRegistered(
    String studentId,
    String subjectId,
  ) async {
    try {
      var result = await _db
          .collection('course_registrations')
          .where('student_id', isEqualTo: studentId)
          .where('subject_id', isEqualTo: subjectId)
          .get();

      // Kira duplicate kalau subject masih Pending atau sudah Approved
      for (var doc in result.docs) {
        var status = doc.data()['status'];

        if (status == 'Pending' || status == 'Approved') {
          return true;
        }
      }

      return false;
    } catch (e) {
      print("Ralat semakan duplicate: $e");
      return false;
    }
  }

  // Lecturer approve subject
  Future<void> approveRegistration(String regId) async {
    try {
      await _db.collection('course_registrations').doc(regId).update({
        'status': 'Approved',
      });

      print("Registration $regId approved!");
    } catch (e) {
      print("Ralat semasa approve registration: $e");
      rethrow;
    }
  }
  // ============================================
  // --- FUNGSI LECTURER APPROVAL COURSE REG ---
  // ============================================

  // Lecturer view all pending/approved course registrations
  Stream<QuerySnapshot> getCourseRegistrationsForLecturer() {
    return _db
        .collection('course_registrations')
        .where('status', whereIn: ['Pending', 'Approved'])
        .snapshots();
  }

  // ============================================
  // --- FUNGSI CO-Q REGISTRATION (STUDENT) ---
  // ============================================

  int _coqToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  // Get all Co-Q modules created by Pusat Adab
  Stream<QuerySnapshot> getCoQBookingSlots() {
    return _db.collection('module_coq').snapshots();
  }

  // Get Co-Q registrations for one student
  Stream<QuerySnapshot> getStudentCoQRegistrations(String studentId) {
    return _db
        .collection('coq_registrations')
        .where('student_id', isEqualTo: studentId)
        .snapshots();
  }

  // Student book/register Co-Q
  Future<void> bookCoQ({
    required String studentId,
    required String moduleDocId,
    required Map<String, dynamic> moduleData,
  }) async {
    final String coqId = moduleData['coq_id'] == null
        ? moduleDocId
        : moduleData['coq_id'].toString();

    final moduleRef = _db.collection('module_coq').doc(moduleDocId);

    final regRef = _db
        .collection('coq_registrations')
        .doc('${studentId}_$coqId');

    await _db.runTransaction((transaction) async {
      final moduleSnapshot = await transaction.get(moduleRef);
      final regSnapshot = await transaction.get(regRef);

      if (!moduleSnapshot.exists) {
        throw Exception("This Co-Q module does not exist.");
      }

      if (regSnapshot.exists) {
        throw Exception("You already registered this Co-Q.");
      }

      final data = moduleSnapshot.data() as Map<String, dynamic>;

      final int booked = data['booked'] is int
          ? data['booked']
          : int.tryParse((data['booked'] ?? '0').toString()) ?? 0;

      final int quota = data['booking_quota'] is int
          ? data['booking_quota']
          : int.tryParse((data['booking_quota'] ?? '50').toString()) ?? 50;

      if (booked >= quota) {
        throw Exception("This Co-Q slot is already full.");
      }

      final registration = CoqRegistration(
        registrationId: '${studentId}_$coqId',
        studentId: studentId,
        moduleDocId: moduleDocId,
        coqId: coqId,
        activityName: data['activity_name'] ?? '',
        lecturerName: data['lecturer_name'] ?? '',
        location: data['location'] ?? '',
        date: data['date'],
        time: data['time'],
        status: 'Registered',
      );

      transaction.set(regRef, registration.toFirebase());

      transaction.update(moduleRef, {'booked': booked + 1});
    });
  }

  // Student drop Co-Q registration
  Future<void> dropCoQ({
    required String registrationDocId,
    required String moduleDocId,
  }) async {
    final regRef = _db.collection('coq_registrations').doc(registrationDocId);
    final moduleRef = _db.collection('module_coq').doc(moduleDocId);

    await _db.runTransaction((transaction) async {
      final moduleSnapshot = await transaction.get(moduleRef);

      int booked = 0;

      if (moduleSnapshot.exists) {
        final data = moduleSnapshot.data() as Map<String, dynamic>;

        booked = data['booked'] is int
            ? data['booked']
            : int.tryParse((data['booked'] ?? '0').toString()) ?? 0;
      }

      transaction.delete(regRef);

      if (moduleSnapshot.exists) {
        transaction.update(moduleRef, {'booked': booked > 0 ? booked - 1 : 0});
      }
    });
  }
}
