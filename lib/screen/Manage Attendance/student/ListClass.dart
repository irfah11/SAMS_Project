import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AttendanceCheckIn.dart';

class StudentListClassScreen extends StatelessWidget {
  final String? subjectId;
  final String? coqId;
  final String subjectName;
  // Option B: matric student_id (e.g. "CB23028") passed from Co-QSubject
  final String? studentId;

  const StudentListClassScreen({
    super.key,
    this.subjectId,
    this.coqId,
    required this.subjectName,
    this.studentId,
  });

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
    Query query = FirebaseFirestore.instance
        .collection('AttendanceSession')
        .orderBy('start_time', descending: false);

    if (subjectId != null) {
      query = query.where('subject_id', isEqualTo: subjectId);
    } else if (coqId != null) {
      query = query.where('coq_id', isEqualTo: coqId);
    }

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
            Row(children: [
              const Icon(Icons.people_outline, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Manage Attendance',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                      Text(subjectName,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black54)),
                    ]),
              ),
            ]),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _buildEmpty();
                }
                final docs = snap.data!.docs;
                return Table(
                  border: TableBorder.all(
                      color: Colors.grey.shade400, width: 0.5),
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(2.5),
                    2: FlexColumnWidth(3),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    _buildHeader(),
                    ...docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return _buildRow(context, doc.id, d);
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeader() {
    return const TableRow(
      decoration: BoxDecoration(color: Color(0xFFE0F7FA)),
      children: [
        _HCell('Time & Date'),
        _HCell('Description'),
        _HCell('Location'),
        _HCell('Status'),
      ],
    );
  }

  TableRow _buildRow(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final status  = data['session_status'] as String? ?? 'Pending';
    final startTs = data['start_time'] as Timestamp?;
    final endTs   = data['end_time'] as Timestamp?;
    final desc    = data['session_description'] as String? ?? '-';

    String location = 'UMPSA Campus';
    final geo = data['session_location'];
    if (geo is GeoPoint) {
      location = '${geo.latitude.toStringAsFixed(4)},\n'
          '${geo.longitude.toStringAsFixed(4)}';
    }

    final timeStr = startTs != null && endTs != null
        ? '${_fmtTs(startTs)} -\n${_fmtTs(endTs)}'
        : _fmtTs(startTs);

    final canCheckIn = status == 'Active' || status == 'Pending';

    void goCheckIn() {
      if (canCheckIn) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceCheckInScreen(
              sessionId:   docId,
              sessionData: data,
              subjectName: subjectName,
              studentId:   studentId, // pass matric number down
            ),
          ),
        );
      }
    }

    return TableRow(children: [
      _DCell(timeStr, tapEnabled: canCheckIn, onTap: goCheckIn),
      _DCell(desc,    tapEnabled: canCheckIn, onTap: goCheckIn),
      _DCell(location),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
      ),
    ]);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Active': return Colors.green.shade600;
      case 'Passed': return Colors.grey.shade600;
      default:       return Colors.orange.shade600;
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
