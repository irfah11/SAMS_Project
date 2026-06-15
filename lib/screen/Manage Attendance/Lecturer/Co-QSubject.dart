import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../widgets/card_image.dart';
import 'ListClass.dart';

class LecturerCoQSubjectScreen extends StatefulWidget {
  const LecturerCoQSubjectScreen({super.key});

  @override
  State<LecturerCoQSubjectScreen> createState() =>
      _LecturerCoQSubjectScreenState();
}

class _LecturerCoQSubjectScreenState
    extends State<LecturerCoQSubjectScreen> {
  static const _blue = Color(0xFF4C66EE);
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isLoading = true;
  List<Map<String, dynamic>> _classes = [];
  // The numeric lecturer_id (e.g. 1002) stored in users doc
  dynamic _lecturerId;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    final userData = userDoc.data() ?? {};

    // lecturer_id is the numeric ID (e.g. 1002) used in course_subjects.Lecturer_id
    // Falls back to staff_id for accounts registered via RegisterScreen
    _lecturerId = userData['lecturer_id'] ?? userData['staff_id'];

    // lecturer_name is used in module_coq.lecturer_name (no Lecturer_id field there)
    final lecturerName = userData['name'] as String? ?? '';

    if (_lecturerId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final list = <Map<String, dynamic>>[];

    // Academic subjects from course_subjects where lecturer_name matches
    // (course_subjects has no Lecturer_id field, same as module_coq)
    if (lecturerName.isNotEmpty) {
      final subSnap = await FirebaseFirestore.instance
          .collection('course_subjects')
          .where('lecturer_name', isEqualTo: lecturerName)
          .get();

      for (final doc in subSnap.docs) {
        final d = doc.data();
        list.add({
          'id':    d['subject_id'] ?? doc.id,
          'name':  d['subject_name'] ?? 'Unknown Subject',
          'isCoQ': false,
        });
      }

      // Co-Q modules from module_coq where lecturer_name matches
      final coqSnap = await FirebaseFirestore.instance
          .collection('module_coq')
          .where('lecturer_name', isEqualTo: lecturerName)
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
        _classes = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _blue,
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
                  if (_lecturerId == null)
                    _buildNoIdState()
                  else if (_classes.isEmpty)
                    _buildEmpty()
                  else
                    ..._classes.map(displayclass),
                ],
              ),
            ),
    );
  }

  /// SDD selectclass() — open the session list for the chosen subject/module.
  void selectclass(Map<String, dynamic> cls) {
    final isCoQ = cls['isCoQ'] as bool;
    final code  = (cls['id'] as String?) ?? '';
    final name  = (cls['name'] as String?) ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerListClassScreen(
          subjectId:   isCoQ ? null : cls['id'] as String,
          coqId:       isCoQ ? cls['id'] as String : null,
          subjectName: code.isEmpty ? name : '$code : $name',
          isCoQ:       isCoQ,
          lecturerId:  _lecturerId,
        ),
      ),
    );
  }

  /// SDD displayclass() — build a tappable card for one subject/module.
  Widget displayclass(Map<String, dynamic> cls) {
    final code  = (cls['id'] as String?) ?? '';
    final name  = (cls['name'] as String?) ?? '';
    return GestureDetector(
      onTap: () => selectclass(cls),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(15),
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

  Widget _buildNoIdState() => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Column(children: [
            Icon(Icons.badge_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'Lecturer ID not set.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            SizedBox(height: 8),
            Text(
              'Please ensure your users document\nhas a "lecturer_id" field.',
              style: TextStyle(fontSize: 13, color: Colors.black38),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              'No classes assigned for Lecturer ID: $_lecturerId',
              style: const TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your lecturer_id to course_subjects or module_coq.',
              style: TextStyle(fontSize: 13, color: Colors.black38),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadClasses,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
}
