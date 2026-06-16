import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleController {
  // =====================================================
  // FIRESTORE INSTANCE
  // Used to access Firebase Firestore database
  // =====================================================
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =====================================================
  // GET ALL MODULES / SUBJECTS
  // Returns a real-time stream from Firestore
  // Collection: subjects
  // =====================================================
  Stream<QuerySnapshot> getSubjects() {
    return _firestore.collection('subjects').snapshots();
  }

  // =====================================================
  // ADD NEW MODULE / SUBJECT
  // Stores module code, title and creation date
  // into Firestore collection: subjects
  // =====================================================
  Future<void> addSubject({required String code, required String title}) async {
    await _firestore.collection('subjects').add({
      'code': code,
      'title': title,
      'createdAt': Timestamp.now(),
    });
  }

  // =====================================================
  // DELETE MODULE / SUBJECT
  // Removes a module from Firestore using document ID
  // =====================================================
  Future<void> deleteSubject(String subjectId) async {
    await _firestore.collection('subjects').doc(subjectId).delete();
  }
}
