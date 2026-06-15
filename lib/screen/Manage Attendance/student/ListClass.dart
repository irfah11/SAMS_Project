import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';
import 'AttendanceCheckIn.dart';

class StudentListClassScreen extends StatefulWidget {
  final String? subjectId;
  final String? coqId;
  final String subjectName;
  final String? studentId;

  const StudentListClassScreen({
    super.key,
    this.subjectId,
    this.coqId,
    required this.subjectName,
    this.studentId,
  });

  @override
  State<StudentListClassScreen> createState() => _StudentListClassScreenState();
}

class _StudentListClassScreenState extends State<StudentListClassScreen> {
  // sessionId → personal status: "Pending" | "Attend" | "Absent" | "Late"
  Map<String, String> _personalStatus = {};

  @override
  void initState() {
    super.initState();
    _loadPersonalStatus();
  }

  Future<void> _loadPersonalStatus() async {
    if (widget.studentId == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('AttendanceRecord')
        .where('Student_id', isEqualTo: widget.studentId)
        .get();

    final map = <String, String>{};
    for (final doc in snap.docs) {
      final d = doc.data();
      final sessionId = d['session_id']?.toString() ?? '';
      var status = d['status'] as String? ?? 'Absent';
      if (status == 'Present') status = 'Attend';
      if (sessionId.isNotEmpty) map[sessionId] = status;
    }
    if (mounted) setState(() => _personalStatus = map);
  }

  String _getPersonalStatus(String sessionId) =>
      _personalStatus[sessionId] ?? 'Pending';

  String _fmtTs(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}\n'
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final stream = AttendanceController.studentSessionsStream(
      subjectId: widget.subjectId,
      coqId: widget.coqId,
    );

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.people_outline, size: 32),
              SizedBox(width: 10),
              Text('Manage  Attendance',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 16),
            Center(
              child: Text(widget.subjectName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _buildEmpty();
                }
                final docs = snap.data!.docs.toList()
                  ..sort((a, b) {
                    final ta = (a.data() as Map<String, dynamic>)['start_time'] as Timestamp?;
                    final tb = (b.data() as Map<String, dynamic>)['start_time'] as Timestamp?;
                    if (ta == null || tb == null) return 0;
                    return ta.compareTo(tb);
                  });
                return displayClassList(context, docs);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// SDD displayClassList() — render the session table for this subject/module.
  Widget displayClassList(
      BuildContext context, List<QueryDocumentSnapshot> docs) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade400, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(2.5),
        1: FlexColumnWidth(3),
        2: FlexColumnWidth(2),
      },
      children: [
        _buildHeader(),
        ...docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return _buildRow(context, doc.id, d);
        }),
      ],
    );
  }

  /// SDD selectSession() — open the check-in screen for the chosen session.
  void selectSession(
      BuildContext context, String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceCheckInScreen(
          sessionId:   docId,
          sessionData: data,
          subjectName: widget.subjectName,
          studentId:   widget.studentId,
        ),
      ),
    ).then((_) => _loadPersonalStatus());
  }

  TableRow _buildHeader() {
    return const TableRow(
      decoration: BoxDecoration(color: Color(0xFFE0F7FA)),
      children: [
        _HCell('Time & Date'),
        _HCell('Description'),
        _HCell('Status'),
      ],
    );
  }

  TableRow _buildRow(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final sessionStatus = data['session_status'] as String? ?? 'Pending';
    final startTs = data['start_time'] as Timestamp?;
    final endTs   = data['end_time'] as Timestamp?;
    final desc    = data['session_description'] as String? ?? '-';
    final personal = _getPersonalStatus(docId);

    // Only allow tap-to-check-in if session is Active and student hasn't checked in yet
    final canCheckIn = sessionStatus == 'Active' && personal == 'Pending';

    final timeStr = startTs != null && endTs != null
        ? '${_fmtTs(startTs)} -\n${_fmtTs(endTs)}'
        : _fmtTs(startTs);

    void goCheckIn() {
      if (!canCheckIn) return;
      selectSession(context, docId, data);
    }

    return TableRow(children: [
      _DCell(timeStr, tapEnabled: canCheckIn, onTap: goCheckIn),
      _DCell(desc,    tapEnabled: canCheckIn, onTap: goCheckIn),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: GestureDetector(
            onTap: canCheckIn ? goCheckIn : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _personalStatusColor(personal),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                personal,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Color _personalStatusColor(String s) {
    switch (s) {
      case 'Attend': return Colors.green.shade600;
      case 'Late':   return Colors.orange.shade600;
      case 'Absent': return Colors.red.shade600;
      default:       return Colors.grey.shade500; // Pending
    }
  }

  Widget _buildEmpty() => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Column(children: [
            Icon(Icons.event_busy, size: 60, color: Colors.black26),
            SizedBox(height: 14),
            Text('No class sessions scheduled yet.',
                style: TextStyle(fontSize: 14, color: Colors.black54)),
          ]),
        ),
      );
}

class _HCell extends StatelessWidget {
  final String text;
  const _HCell(this.text);
  @override
  Widget build(BuildContext context) => TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      );
}

class _DCell extends StatelessWidget {
  final String text;
  final bool tapEnabled;
  final VoidCallback? onTap;
  const _DCell(this.text, {this.tapEnabled = false, this.onTap});
  @override
  Widget build(BuildContext context) => TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            color: tapEnabled ? const Color(0xFFF1FFFE) : null,
            padding: const EdgeInsets.all(8),
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
          ),
        ),
      );
}
