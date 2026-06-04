import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ListClass.dart';

class StudentCoQSubjectScreen extends StatefulWidget {
  const StudentCoQSubjectScreen({super.key});

  @override
  State<StudentCoQSubjectScreen> createState() =>
      _StudentCoQSubjectScreenState();
}

class _StudentCoQSubjectScreenState extends State<StudentCoQSubjectScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _subjects = [];
  // Option B: matric student_id (e.g. "CB23028") from users doc
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);

    // Read student_id (matric number) from users collection
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    _studentId = userDoc.data()?['student_id'] as String?;

    final list = <Map<String, dynamic>>[];

    if (_studentId != null) {
      // Academic subjects: course_registration where student_id == matric
      final regSnap = await FirebaseFirestore.instance
          .collection('course_registration')
          .where('student_id', isEqualTo: _studentId)
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

      // Co-Q activities: coq_registration where student_id == matric
      final coqSnap = await FirebaseFirestore.instance
          .collection('coq_registration')
          .where('student_id', isEqualTo: _studentId)
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
    }

    if (mounted) {
      setState(() {
        _subjects = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5CE1E6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('SAMS',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.people_outline, size: 48),
                    SizedBox(width: 12),
                    Text('Manage Attendance',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    _studentId != null
                        ? 'Student ID: $_studentId'
                        : 'No student ID found in your profile',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  if (_subjects.isEmpty)
                    _buildEmptyState()
                  else
                    ..._subjects.map(_buildCard),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> s) {
    final isCoQ = s['isCoQ'] as bool;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentListClassScreen(
            subjectId:   isCoQ ? null : s['id'] as String,
            coqId:       isCoQ ? s['id'] as String : null,
            subjectName: s['name'] as String,
            studentId:   _studentId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCoQ
              ? const Color(0xFFB2EBF2)
              : const Color(0xFF5CE1E6),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Icon(
              isCoQ ? Icons.military_tech_outlined : Icons.book_outlined,
              size: 36,
              color: Colors.black87),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'] as String,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(
                    isCoQ
                        ? 'Co-Curriculum Activity'
                        : 'Academic Subject',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(children: [
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
          const SizedBox(height: 16),
          const Text('No registered subjects found.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            _studentId == null
                ? 'Your profile is missing a "student_id" field.'
                : 'No approved registrations for student ID: $_studentId',
            style: const TextStyle(fontSize: 13, color: Colors.black38),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadSubjects,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5CE1E6),
                foregroundColor: Colors.black),
          ),
        ]),
      ),
    );
  }
}
