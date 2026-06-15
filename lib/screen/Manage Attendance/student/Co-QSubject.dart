import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';
import '../../../widgets/card_image.dart';
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

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    _studentId = userDoc.data()?['student_id'] as String?;

    if (_studentId != null) {
      final subjects =
          await AttendanceController.fetchStudentSubjects(_studentId!);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
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
                    Icon(Icons.people_outline, size: 32),
                    SizedBox(width: 10),
                    Text('Manage  Attendance',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 24),
                  if (_subjects.isEmpty)
                    _buildEmptyState()
                  else
                    ..._subjects.map(displayModule),
                ],
              ),
            ),
    );
  }

  /// SDD selectModule() — open the class list for the chosen subject/module.
  void selectModule(Map<String, dynamic> s) {
    final isCoQ = s['isCoQ'] as bool;
    final code  = (s['id'] as String?) ?? '';
    final name  = (s['name'] as String?) ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentListClassScreen(
          subjectId:   isCoQ ? null : s['id'] as String,
          coqId:       isCoQ ? s['id'] as String : null,
          subjectName: code.isEmpty ? name : '$code : $name',
          studentId:   _studentId,
        ),
      ),
    );
  }

  /// SDD displayModule() — build a tappable card for one subject/module.
  Widget displayModule(Map<String, dynamic> s) {
    final code  = (s['id'] as String?) ?? '';
    final name  = (s['name'] as String?) ?? '';
    return GestureDetector(
      onTap: () => selectModule(s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            const CardImageBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Text(code,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
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
