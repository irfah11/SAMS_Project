import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

import 'package:sams/screen/Fee/Student/FeePage.dart' show SamsHeader;

import 'StudentRecordPage.dart';
import 'OverdueStudentPage.dart';

const Color kTreasuryGreen = Color(0xFF52DE76);

// =============================================================
// MODELS
// =============================================================
class DashboardStats {
  final int totalStudents;
  final int paidStudents;
  final int unpaidStudents;
  final int overdueStudents;

  const DashboardStats({
    required this.totalStudents,
    required this.paidStudents,
    required this.unpaidStudents,
    required this.overdueStudents,
  });
}

class StudentRow {
  final String studentId;
  final String fullName;
  final String paymentStatus;

  const StudentRow({
    required this.studentId,
    required this.fullName,
    required this.paymentStatus,
  });
}

// =============================================================
// CONTROLLER METHODS — FeeController (treasury side)
// Per SDD-REQ-308: getDashboardStats()
// =============================================================
class TreasuryController {
  /// Fetches stats + student list in one pass over the fees collection.
  /// For very large datasets (>10K students), prefer aggregation queries.
  static Future<({DashboardStats stats, List<StudentRow> students})>
      getDashboardStats() async {
    final db = FirebaseFirestore.instance;

    // Pull all fee records (each represents one student-semester).
    final feeSnap = await db.collection('Fee').get();

    int paid = 0, unpaid = 0, overdue = 0;
    final rows = <StudentRow>[];

    for (final doc in feeSnap.docs) {
      final data = doc.data();
      final status = (data['payment_status'] ?? 'Unpaid').toString();

      switch (status.toLowerCase()) {
        case 'paid':
          paid++;
          break;
        case 'overdue':
          overdue++;
          unpaid++; // overdue counts as unpaid for the summary tile
          break;
        default:
          unpaid++;
      }

      rows.add(StudentRow(
        studentId: (data['student_id'] ?? '').toString(),
        fullName: (data['student_name'] ?? '').toString(),
        paymentStatus: status,
      ));
    }

    // Backfill missing names from the students collection if needed.
    final missing = rows.where((r) => r.fullName.isEmpty).toList();
    if (missing.isNotEmpty) {
      final studentSnap = await db.collection('student').get();
      final nameById = {
        for (final d in studentSnap.docs)
          (d.data()['student_id'] ?? d.id).toString():
              (d.data()['full_name'] ?? '').toString(),
      };
      for (int i = 0; i < rows.length; i++) {
        if (rows[i].fullName.isEmpty) {
          rows[i] = StudentRow(
            studentId: rows[i].studentId,
            fullName: nameById[rows[i].studentId] ?? '-',
            paymentStatus: rows[i].paymentStatus,
          );
        }
      }
    }

    return (
      stats: DashboardStats(
        totalStudents: rows.length,
        paidStudents: paid,
        unpaidStudents: unpaid,
        overdueStudents: overdue,
      ),
      students: rows,
    );
  }
}

// =============================================================
// BOUNDARY CLASS — TreasuryDashboardPage  [SDD-REQ-305]
// =============================================================
class TreasuryDashboardPage extends StatefulWidget {
  const TreasuryDashboardPage({super.key});

  @override
  State<TreasuryDashboardPage> createState() => _TreasuryDashboardPageState();
}

class _TreasuryDashboardPageState extends State<TreasuryDashboardPage> {
  late Future<({DashboardStats stats, List<StudentRow> students})> _future;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // SDD: current academic semester (would come from a setting in production)
  static const String _currentSemester = 'Semester 2 2025/2026';

  @override
  void initState() {
    super.initState();
    loadDashboardStats();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void loadDashboardStats() {
    setState(() {
      _future = TreasuryController.getDashboardStats();
    });
  }

  // searchStudent() — filter the visible list
  List<StudentRow> searchStudent(List<StudentRow> all) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) =>
            s.studentId.toLowerCase().contains(q) ||
            s.fullName.toLowerCase().contains(q))
        .toList();
  }

  // navigateToStudentRecord() — push individual record view
  void navigateToStudentRecord(String studentId) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => StudentRecordPage(studentId: studentId),
        ))
        // refresh when coming back since block/unblock may have changed state
        .then((_) => loadDashboardStats());
  }

  void _openOverdueList() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const OverdueStudentPage(),
    ));
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
              child: FutureBuilder<
                  ({DashboardStats stats, List<StudentRow> students})>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text('Failed to load: ${snapshot.error}'),
                    );
                  }
                  final stats = snapshot.data!.stats;
                  final all = snapshot.data!.students;
                  final filtered = searchStudent(all);
                  return _buildBody(stats, filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(DashboardStats stats, List<StudentRow> students) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee management',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentSemester,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // Stats cards
          Row(
            children: [
              Expanded(child: _StatCard(value: stats.totalStudents, label: 'Total')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(value: stats.paidStudents, label: 'Paid')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(value: stats.unpaidStudents, label: 'Unpaid')),
            ],
          ),
          const SizedBox(height: 12),

          // Quick link to overdue list
          if (stats.overdueStudents > 0)
            TextButton.icon(
              onPressed: _openOverdueList,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                minimumSize: const Size(0, 32),
              ),
              icon: const Icon(Icons.warning_amber, size: 16, color: Colors.redAccent),
              label: Text(
                'View ${stats.overdueStudents} overdue students',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.redAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search ID',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'ALL STUDENTS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),

          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No matching students.')),
            )
          else
            for (final s in students)
              _StudentTile(
                row: s,
                onTap: () => navigateToStudentRecord(s.studentId),
              ),
        ],
      ),
    );
  }
}

// =============================================================
// UI WIDGETS
// =============================================================
class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7F6), // lavender
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            _formatThousands(value),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5C4A8F),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF5C4A8F)),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final StudentRow row;
  final VoidCallback onTap;
  const _StudentTile({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                    row.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.studentId,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              row.paymentStatus,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _statusColor(row.paymentStatus),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'overdue':
        return Colors.redAccent;
      default:
        return Colors.black87;
    }
  }
}

String _formatThousands(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final idxFromRight = s.length - i;
    buf.write(s[i]);
    if (idxFromRight > 1 && (idxFromRight - 1) % 3 == 0) buf.write(',');
  }
  return buf.toString();
}