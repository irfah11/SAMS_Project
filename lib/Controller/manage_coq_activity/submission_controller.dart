import 'package:cloud_firestore/cloud_firestore.dart';

class SubmissionController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get submissions for an assignment
  Stream<QuerySnapshot> getSubmissions(String assignmentId) {
    return _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots();
  }

  // Add submission
  Future<void> addSubmission({
    required String subjectId,
    required String assignmentId,
    required String fileName,
    required String fileUrl,
  }) async {
    await _firestore.collection('submissions').add({
      'subjectId': subjectId,
      'assignmentId': assignmentId,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'submittedAt': Timestamp.now(),
    });
  }

  // Delete submission
  Future<void> deleteSubmission(String submissionId) async {
    await _firestore.collection('submissions').doc(submissionId).delete();
  }
}
