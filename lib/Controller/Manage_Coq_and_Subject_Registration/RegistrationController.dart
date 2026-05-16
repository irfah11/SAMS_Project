//Controller for faculty registrar Manage the subject(CRUD)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Domain/module_coq.dart' show ModuleCoQ;
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
}
