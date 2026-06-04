import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PusatAdabListAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String sessionDescription;
  final String activityName;

  const PusatAdabListAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.sessionDescription,
    required this.activityName,
  });

  @override
  State<PusatAdabListAttendanceScreen> createState() =>
      _PusatAdabListAttendanceScreenState();
}

class _PusatAdabListAttendanceScreenState
    extends State<PusatAdabListAttendanceScreen> {
  static const _maroon = Color(0xFF965E5E);

  String _fmtTs(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}\n'
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  // onStatusUpdate — Pusat Adab can edit student attendance status
  void _onStatusUpdate(String recordId, String current, String name) {
    String selected = current;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Update Status — $name',
              style: const TextStyle(fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Present', 'Absent', 'Late'].map((s) {
              return RadioListTile<String>(
                title: Text(s),
                value: s,
                groupValue: selected,
                activeColor: _maroon,
                onChanged: (v) {
                  if (v != null) setDlg(() => selected = v);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _updateRecord(recordId, selected, name);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _maroon,
                  foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRecord(
      String recordId, String newStatus, String name) async {
    try {
      await FirebaseFirestore.instance
          .collection('AttendanceRecord')
          .doc(recordId)
          .update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to "$newStatus" for $name'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('AttendanceRecord')
        .where('session_id', isEqualTo: widget.sessionId)
        .orderBy('student_name')
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _maroon,
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
                    const Text('View Attendance',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
                    Text(
                        '${widget.activityName} — ${widget.sessionDescription}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 8),
            const Text('Tap a status badge to update it.',
                style: TextStyle(fontSize: 12, color: Colors.black38)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return _buildEmpty();
                }
                final docs = snap.data!.docs;
                return Column(children: [
                  _buildStats(docs),
                  const SizedBox(height: 16),
                  Table(
                    border: TableBorder.all(
                        color: Colors.grey.shade400, width: 0.5),
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(2.5),
                    },
                    children: [
                      _hdr(),
                      ...docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return _row(doc.id, d);
                      }),
                    ],
                  ),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(List<QueryDocumentSnapshot> docs) {
    int p = 0, a = 0, l = 0;
    for (final d in docs) {
      final s =
          (d.data() as Map<String, dynamic>)['status'] as String? ?? '';
      if (s == 'Present') { p++; }
      else if (s == 'Late') { l++; }
      else { a++; }
    }
    return Row(children: [
      _Chip('Present', p, Colors.green.shade600),
      const SizedBox(width: 8),
      _Chip('Late', l, Colors.orange.shade600),
      const SizedBox(width: 8),
      _Chip('Absent', a, Colors.red.shade600),
    ]);
  }

  TableRow _hdr() => const TableRow(
        decoration: BoxDecoration(color: Color(0xFFF5E6E6)),
        children: [
          _HCell('Check-in Time'),
          _HCell('Full Name'),
          _HCell('Status'),
          _HCell('Location'),
        ],
      );

  TableRow _row(String recordId, Map<String, dynamic> data) {
    final status  = data['status'] as String? ?? 'Absent';
    final name    = data['student_name'] as String? ??
                    data['Student_id'] as String? ?? '-';
    final ts      = data['check_in_time'] as Timestamp?;
    final geo     = data['record_location'];
    String loc    = '-';
    if (geo is GeoPoint) {
      loc = '${geo.latitude.toStringAsFixed(4)},\n'
            '${geo.longitude.toStringAsFixed(4)}';
    }

    return TableRow(children: [
      _DCell(_fmtTs(ts)),
      _DCell(name),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: GestureDetector(
            onTap: () => _onStatusUpdate(recordId, status, name),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(status,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                    const SizedBox(width: 3),
                    const Icon(Icons.edit,
                        size: 9, color: Colors.white70),
                  ]),
            ),
          ),
        ),
      ),
      _DCell(loc),
    ]);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Present': return Colors.green.shade600;
      case 'Late':    return Colors.orange.shade600;
      default:        return Colors.red.shade600;
    }
  }

  Widget _buildEmpty() => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Column(children: [
            Icon(Icons.people_outline, size: 60, color: Colors.black26),
            SizedBox(height: 14),
            Text('No attendance records yet.',
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            SizedBox(height: 6),
            Text('Records appear once students check in.',
                style: TextStyle(fontSize: 12, color: Colors.black38)),
          ]),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label; final int count; final Color color;
  const _Chip(this.label, this.count, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Text('$label: $count',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

class _HCell extends StatelessWidget {
  final String text; const _HCell(this.text);
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
  final String text; const _DCell(this.text);
  @override
  Widget build(BuildContext context) => TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11)),
        ),
      );
}
