import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';
import '../../../widgets/periodic_rebuild.dart';
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
  // sessionId → personal status FROM A RECORD: "Attend" | "Absent" | "Late".
  // A session with no entry here means the student has no AttendanceRecord yet.
  Map<String, String> _personalStatus = {};

  // The student's display name, used when persisting an Absent record.
  String? _studentName;

  // Sessions we've already finalised as Absent (avoids repeat writes).
  final Set<String> _absentEnsured = {};

  @override
  void initState() {
    super.initState();
    _loadStudentName();
    _loadPersonalStatus();
  }

  Future<void> _loadStudentName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    _studentName = doc.data()?['name'] as String?;
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

  /// The status to display for a session, given its (time-based) status:
  ///   • a recorded result (Attend / Late / Absent) always wins;
  ///   • otherwise a Passed class with no check-in is Absent;
  ///   • otherwise it's still Pending (upcoming or open for check-in).
  String _displayStatus(String sessionId, String sessionStatus) {
    final recorded = _personalStatus[sessionId];
    if (recorded != null) return recorded;
    if (sessionStatus == 'Passed') return 'Absent';
    return 'Pending';
  }

  /// Persist an Absent record in Firestore for any Passed session the student
  /// missed (no check-in, no lecturer override). Idempotent and lecturer-safe
  /// — see [AttendanceController.ensureAbsentRecord].
  Future<void> _finaliseAbsentees(List<QueryDocumentSnapshot> docs) async {
    if (widget.studentId == null) return;
    var wrote = false;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (AttendanceController.effectiveStatus(data) != 'Passed') continue;
      if (_personalStatus.containsKey(doc.id)) continue; // already has a record
      if (!_absentEnsured.add(doc.id)) continue;         // already handled
      await AttendanceController.ensureAbsentRecord(
        sessionId:   doc.id,
        studentId:   widget.studentId!,
        studentName: _studentName ?? widget.studentId!,
      );
      wrote = true;
    }
    if (wrote) _loadPersonalStatus();
  }

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
                // Persist Absent for any class that has already passed without
                // a check-in (after this frame, never during build).
                WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _finaliseAbsentees(docs));
                // Rebuild periodically so time-based status (and which rows
                // are tappable) stays current while the screen is open.
                return PeriodicRebuild(
                  builder: (_) => displayClassList(context, docs),
                );
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
    final sessionStatus = AttendanceController.effectiveStatus(data);
    final startTs = data['start_time'] as Timestamp?;
    final endTs   = data['end_time'] as Timestamp?;
    final desc    = data['session_description'] as String? ?? '-';
    final personal = _displayStatus(docId, sessionStatus);

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
