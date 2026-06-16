import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Domain/subject.dart';

class SubjectController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CREATE
  Future<void> addContent(SubjectContent content) async {
    await _firestore
        .collection('subjects')
        .doc(content.subjectId)
        .collection('contents')
        .add(content.toMap());
  }

  // RETRIEVE NOTES
  Stream<List<SubjectContent>> getNotes(String subjectId) {
    return _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('contents')
        .where('type', isEqualTo: 'Note')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubjectContent.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // RETRIEVE ASSIGNMENTS
  Stream<List<SubjectContent>> getAssignments(String subjectId) {
    return _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('contents')
        .where('type', isEqualTo: 'Assignment')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubjectContent.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // RETRIEVE QUIZZES
  Stream<List<SubjectContent>> getQuizzes(String subjectId) {
    return _firestore
        .collection('subjects')
        .doc(subjectId)
        .collection('contents')
        .where('type', isEqualTo: 'Quiz')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SubjectContent.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
