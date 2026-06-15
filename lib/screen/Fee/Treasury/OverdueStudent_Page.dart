import 'package:flutter/material.dart';

import 'package:sams/Controller/Fee/FeeController.dart';
import 'package:sams/screen/Fee/Student/FeePage.dart' show SamsHeader;

import 'StudentRecordPage.dart';
import 'TreasuryDashboardPage.dart' show kTreasuryGreen;

// =============================================================
// BOUNDARY CLASS — OverdueStudent_Page  [SDD-REQ-307]
// Methods: loadOverdueList(), toggleAcademicAccess(), sendOverdueNotification()
// =============================================================
class OverdueStudentPage extends StatefulWidget {
  const OverdueStudentPage({super.key});

  @override
  State<OverdueStudentPage> createState() => _OverdueStudentPageState();
}

class _OverdueStudentPageState extends State<OverdueStudentPage> {
  late Future<List<OverdueStudent>> _future;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    loadOverdueList();
  }

  // loadOverdueList() — SDD-REQ-307: all students with an Overdue fee.
  void loadOverdueList() {
    setState(() {
      _future = FeeController.getOverdueList();
    });
  }

  // toggleAcademicAccess() — SDD-REQ-307: block/unblock then notify.
  Future<void> toggleAcademicAccess(OverdueStudent s) async {
    if (_working) return;
    setState(() => _working = true);

    final newStatus = await FeeController.toggleAccessStatus(
      studentId: s.studentId,
      currentStatus: s.accessStatus,
    );
    await sendOverdueNotification(
      studentId: s.studentId,
      accessStatus: newStatus,
      paymentStatus: s.paymentStatus,
    );

    if (!mounted) return;
    setState(() => _working = false);
    loadOverdueList(); // refresh badges
  }

  // sendOverdueNotification() — SDD-REQ-307: notify the student.
  Future<void> sendOverdueNotification({
    required String studentId,
    required String accessStatus,
    required String paymentStatus,
  }) {
    return FeeController.sendOverdueNotification(
      studentId: studentId,
      accessStatus: accessStatus,
      paymentStatus: paymentStatus,
    );
  }

  void _openRecord(OverdueStudent s) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => StudentRecordPage(studentId: s.studentId),
        ))
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
                              child: Text('No overdue students.'),
                            ),
                          )
                        else
                          for (final s in list)
                            _OverdueTile(
                              student: s,
                              working: _working,
                              onOpen: () => _openRecord(s),
                              onToggle: () => toggleAcademicAccess(s),
                            ),
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
  final bool working;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  const _OverdueTile({
    required this.student,
    required this.working,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final blocked = student.accessStatus.toLowerCase() == 'blocked';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpen,
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
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
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
          const SizedBox(width: 8),
          TextButton(
            onPressed: working ? null : onToggle,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              blocked ? 'Unblock' : 'Block',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
