import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ListAttendance.dart';

class PusatAdabClassCoQScreen extends StatelessWidget {
  final String coqId;
  final String activityName;

  const PusatAdabClassCoQScreen({
    super.key,
    required this.coqId,
    required this.activityName,
  });

  static const _maroon = Color(0xFF965E5E);

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
    final query = FirebaseFirestore.instance
        .collection('AttendanceSession')
        .where('coq_id', isEqualTo: coqId)
        .orderBy('start_time', descending: false);

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
                    Text(activityName,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmpty();
                }
                return Table(
                  border: TableBorder.all(
                      color: Colors.grey.shade400, width: 0.5),
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    _hdr(),
                    ...snapshot.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return _row(context, doc.id, d);
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

  TableRow _hdr() => const TableRow(
        decoration: BoxDecoration(color: Color(0xFFF5E6E6)),
        children: [
          _Cell('Time & Date', isHeader: true),
          _Cell('Description', isHeader: true),
          _Cell('Status', isHeader: true),
          _Cell('Location', isHeader: true),
        ],
      );

  TableRow _row(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final status = data['session_status'] as String? ?? 'Pending';
    final startTs = data['start_time'] as Timestamp?;
    final desc    = data['session_description'] as String? ?? '-';

    String location = 'UMPSA Campus';
    final geo = data['session_location'];
    if (geo is GeoPoint) {
      location = '${geo.latitude.toStringAsFixed(4)},\n'
          '${geo.longitude.toStringAsFixed(4)}';
    }

    return TableRow(children: [
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PusatAdabListAttendanceScreen(
              sessionId: docId,
              sessionDescription: desc,
              activityName: activityName,
            ),
          ),
        ),
        child: Container(
          color: const Color(0xFFFFF8F8),
          padding: const EdgeInsets.all(8),
          child: Text(_fmtTs(startTs),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11)),
        ),
      ),
      _Cell(desc),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
      _Cell(location),
    ]);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Active':  return Colors.green.shade600;
      case 'Passed':  return Colors.grey.shade600;
      default:        return Colors.orange.shade600;
    }
  }

  Widget _buildEmpty() => const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
          child: Column(children: [
            Icon(Icons.event_busy, size: 60, color: Colors.black26),
            SizedBox(height: 14),
            Text('No sessions scheduled for this module.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _Cell(this.text, {this.isHeader = false});
  @override
  Widget build(BuildContext context) => TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isHeader ? FontWeight.w600 : FontWeight.normal)),
        ),
      );
}
