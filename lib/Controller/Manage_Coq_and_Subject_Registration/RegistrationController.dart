// import from another package
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore package
import 'package:sams/Domain/registration_subject.dart';
import '../../Domain/course_subject.dart';
import '../../Domain/lecturer.dart';
import 'package:sams/Domain/module_coq.dart';
import 'package:sams/Domain/coq_registration.dart';

class RegistrationController {
  // 1. FIREBASE DATABASE CONNECTION
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Firestore object

  // 2. CREATE COURSE SUBJECT
  Future<void> createCourse(CourseSubject subject) async {
    try {
      await _db
          .collection('course_subjects') // Access course_subjects collection
          .doc(subject.subjectId) // Use subject ID as document ID
          .set(subject.toFirebase()); //save course to firestore

      print("Course Subject ${subject.subjectName} berjaya didaftarkan!");
    } catch (e) {
      print("Ralat: $e");
      rethrow;
    }
  }

  Future<void> createLecturer(Lecturer lecturer) async {
    try {
      await _db
          .collection('lecturers') //Acess lecturers collection
          .doc(lecturer.lecturerId.toString()) // Use lecturer ID as doc ID
          .set(lecturer.toFirebase()); // save lecturer data to firestore
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Lecturer>> getLecturerStream() {
    return _db.collection('lecturers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        //loop every lecturer document
        return Lecturer.fromFirebase(doc.data()); // Convert Firestore to object
      }).toList();
    });
  }

  // ============================================================
  // 5. UPDATE COURSE SUBJECT (FACULTY REGISTRAR)
  // ============================================================

  Future<void> updateCourse(CourseSubject subject) async {
    try {
      await _db
          .collection('course_subjects') // Access course_subjects collection
          .doc(subject.subjectId) // Find document by subject ID
          .update(subject.toFirebase()); // Update document with new data

      print("Course Subject ${subject.subjectName} Successfully updated!");
    } catch (e) {
      print("error: $e");
      rethrow;
    }
  }

  // ============================================================
  // 6. DELETE COURSE SUBJECT (FACULTY REGISTRAR)
  // ============================================================

  Future<void> deleteCourse(String subjectId) async {
    try {
      await _db
          .collection('course_subjects') // Access course_subjects collection
          .doc(subjectId) // Delete document by subject ID
          .delete();

      print("Course Subject bertipe ID $subjectId successfully deleted!");
    } catch (e) {
      print("Error , failed to delete course subject: $e");
      rethrow;
    }
  }

  // ============================================================
  // 7. CREATE CO-Q ACTIVITY (PUSAT ADAB)
  // ============================================================

  Future<void> createCoQ(ModuleCoQ coq) async {
    try {
      await _db
          .collection('module_coq') // Access module_coq collection
          .doc(coq.coqId) // Use Co-Q ID as document ID
          .set(coq.toFirebase()); // Save Co-Q activity to Firestore
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // 8. UPDATE CO-Q ACTIVITY (PUSAT ADAB)
  // ============================================================

  Future<void> updateCoQ(ModuleCoQ coq) async {
    try {
      await _db
          .collection('module_coq') // Access module_coq collection
          .doc(coq.coqId) // Find Co-Q document by ID
          .update(coq.toFirebase()); // Update Co-Q activity in Firestore
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // 9. DELETE CO-Q ACTIVITY  (PUSAT ADAB)
  // ============================================================

  Future<void> deleteCoQ(String coqId) async {
    try {
      await _db
          .collection('module_coq') // Access module_coq collection
          .doc(coqId) // Find Co-Q document by ID
          .delete(); // Delete Co-Q activity from Firestore
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // 10. SUBMIT COURSE REGISTRATION (STUDENT)
  // ============================================================

  Future<void> submitCourseRegistration(RegistrationSubject reg) async {
    try {
      await _db
          .collection(
            'course_registrations',
          ) // Access course_registrations collection
          .doc(reg.regId) // Use registration ID as document ID
          .set(reg.toFirebase()); // Save course registration to Firestore
    } catch (e) {
      print("Ralat semasa submit registration: $e");
      rethrow;
    }
  }

  // ============================================================
  // 11. GET COURSE REGISTRATION BY STATUS
  // ============================================================

  Stream<List<RegistrationSubject>> getRegistrationsByStatus(
    String studentId,
    String status,
  ) {
    return _db
        .collection(
          'course_registrations',
        ) // Access course_registrations collection
        .where('student_id', isEqualTo: studentId) // Filter by student ID
        .where('status', isEqualTo: status) // Pending or Approved
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Loop every registration document
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

  // ============================================================
  // 12. GET PENDING COURSE REGISTRATION (STUDENT)
  // ============================================================

  Stream<List<RegistrationSubject>> getPendingRegistrations(String studentId) {
    return getRegistrationsByStatus(studentId, 'Pending'); // For approval page
  }

  // ============================================================
  // 13. GET APPROVED COURSE REGISTRATION (STUDENT)
  // ============================================================

  Stream<List<RegistrationSubject>> getApprovedRegistrations(String studentId) {
    return getRegistrationsByStatus(
      studentId,
      'Approved',
    ); // For registered page
  }

  // ============================================================
  // 14. DROP REGISTERED COURSE(STUDENT)
  // ============================================================

  Future<void> dropRegisteredCourse(String regId) async {
    try {
      await _db
          .collection('course_registrations')
          .doc(regId) // Delete selected registration
          .delete();

      print("Pendaftaran $regId berjaya digugurkan!");
    } catch (e) {
      print("Ralat semasa drop subjek: $e");
      rethrow;
    }
  }

  // ============================================================
  // 15. CHECK DUPLICATE SUBJECT REGISTRATION (STUDENT)
  // ============================================================

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

      for (var doc in result.docs) {
        var status = doc.data()['status'];

        if (status == 'Pending' || status == 'Approved') {
          return true; // Student already registered this subject
        }
      }

      return false;
    } catch (e) {
      print("Ralat semakan duplicate: $e");
      return false;
    }
  }

  // ============================================================
  // 16. APPROVE COURSE REGISTRATION (LECTURER)
  // ============================================================

  Future<void> approveRegistration(String regId) async {
    try {
      await _db.collection('course_registrations').doc(regId).update({
        'status': 'Approved', // Change status from Pending to Approved
      });

      print("Registration $regId approved!");
    } catch (e) {
      print("Ralat semasa approve registration: $e");
      rethrow;
    }
  }

  // ============================================================
  // 17. GET COURSE REGISTRATION (LECTURER)
  // ============================================================

  Stream<QuerySnapshot> getCourseRegistrationsForLecturer() {
    return _db
        .collection('course_registrations')
        .where('status', whereIn: ['Pending', 'Approved'])
        .snapshots();
  }

  // ============================================================
  // 18. GET CO-Q BOOKING SLOT (STUDENTS)
  // ============================================================

  Stream<QuerySnapshot> getCoQBookingSlots() {
    return _db.collection('module_coq').snapshots(); // Get all Co-Q modules
  }

  // ============================================================
  // 19. GET STUDENT CO-Q REGISTRATION (STUDENT)
  // ============================================================

  Stream<QuerySnapshot> getStudentCoQRegistrations(String studentId) {
    return _db
        .collection('coq_registrations')
        .where('student_id', isEqualTo: studentId)
        .snapshots();
  }

  // ============================================================
  // 20. BOOK CO-Q (STUDENT)
  // ============================================================

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
        .collection('coq_registrations') // Access coq_registrations collection
        .doc('${studentId}_$coqId'); // Prevent duplicate booking

    await _db.runTransaction((transaction) async {
      final moduleSnapshot = await transaction.get(
        moduleRef,
      ); // Get Co-Q module data
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

      transaction.set(regRef, registration.toFirebase()); // Save registration
      transaction.update(moduleRef, {'booked': booked + 1}); // Add booked slot
    });
  }

  // ============================================================
  // 21. DROP CO-Q (STUDENT)
  // ============================================================

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

      transaction.delete(regRef); // Delete student Co-Q registration

      if (moduleSnapshot.exists) {
        transaction.update(moduleRef, {
          'booked': booked > 0 ? booked - 1 : 0, // Avoid negative booked value
        });
      }
    });
  }
}
