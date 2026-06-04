import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sams/screen/Fee/Student/FeePage.dart' show SamsHeader;

import 'StudentRecordPage.dart';
import 'TreasuryDashboardPage.dart' show kTreasuryGreen;

// =============================================================
// MODEL — OverdueStudent
// =============================================================
class OverdueStudent {
  final String studentId;
  final String fullName;
  final String accessStatus;
  final String paymentStatus;

  const OverdueStudent({
    required this.studentId,
    required this.fullName,
    required this.accessStatus,
    required this.paymentStatus,
  });
}

// =============================================================
// CONTROLLER — FeeController.getOverdueList()  [SDD-REQ-308]
// =============================================================
class OverdueController {
  static Future<List<OverdueStudent>> getOverdueList() async {
    final db = FirebaseFirestore.instance;
    final feeSnap = await db
        .collection('Fee')
        .where('payment_status', isEqualTo: 'Overdue')
        .get();

    final ids = feeSnap.docs
        .map((d) => (d.data()['student_id'] ?? '').toString())
        .toList();

    // Fetch student names in one batched read.
    final nameById = <String, String>{};
    if (ids.isNotEmpty) {
      final studentSnap = await db.collection('student').get();
      for (final d in studentSnap.docs) {
        final sid = (d.data()['student_id'] ?? d.id).toString();
        nameById[sid] = (d.data()['full_name'] ?? '-').toString();
      }
    }

    return feeSnap.docs.map((d) {
      final data = d.data();
      final sid = (data['student_id'] ?? '').toString();
      return OverdueStudent(
        studentId: sid,
        fullName: nameById[sid] ?? (data['student_name'] ?? '-').toString(),
        accessStatus: (data['access_status'] ?? 'Unblocked').toString(),
        paymentStatus: (data['payment_status'] ?? 'Overdue').toString(),
      );
    }).toList();
  }
}

// =============================================================
// BOUNDARY CLASS — OverdueStudent_Page  [SDD-REQ-307]
// =============================================================
class OverdueStudentPage extends StatefulWidget {
  const OverdueStudentPage({super.key});

  @override
  State<OverdueStudentPage> createState() => _OverdueStudentPageState();
}

class _OverdueStudentPageState extends State<OverdueStudentPage> {
  late Future<List<OverdueStudent>> _future;

  @override
  void initState() {
    super.initState();
    loadOverdueList();
  }

  void loadOverdueList() {
    setState(() {
      _future = OverdueController.getOverdueList();
    });
  }

  void _openRecord(OverdueStudent s) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => StudentRecordPage(studentId: s.studentId),
        ))
        // re-fetch on return so block/unblock changes are reflected
        .then((_) => loadOverdueList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SamsHeader(color: kTreasuryGreen),
            Expanded(
              child: FutureBuilder<List<OverdueStudent>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Failed to load: ${snapshot.error}'),
                      ),
                    );
                  }
                  final list = snapshot.data ?? [];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Fee management',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        const Text(
                          'OVERDUE STUDENTS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (list.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('No overdue students. 🎉'),
                            ),
                          )
                        else
                          for (final s in list)
                            _OverdueTile(student: s, onTap: () => _openRecord(s)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverdueTile extends StatelessWidget {
  final OverdueStudent student;
  final VoidCallback onTap;
  const _OverdueTile({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final blocked = student.accessStatus.toLowerCase() == 'blocked';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.studentId,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: blocked
                    ? const Color(0xFFFCE4E4)
                    : const Color(0xFFFFF7C2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                student.accessStatus,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: blocked ? Colors.redAccent : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}