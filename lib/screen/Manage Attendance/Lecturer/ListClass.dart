import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';
import 'AddAttendance.dart';
import 'EditAttendance.dart';
import 'GenerateAttendance.dart';
import 'ViewAttendance.dart';

class LecturerListClassScreen extends StatelessWidget {
  final String? subjectId;
  final String? coqId;
  final String subjectName;
  final bool isCoQ;
  // Option B: numeric lecturer_id from the lecturer collection (e.g. 1002)
  final dynamic lecturerId;

  const LecturerListClassScreen({
    super.key,
    this.subjectId,
    this.coqId,
    required this.subjectName,
    required this.isCoQ,
    required this.lecturerId,
  });

  static const _blue = Color(0xFF4C66EE);

  String _fmtTs(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}\n'
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  // Long date header, e.g. "Thursday, 2 Apr 2026\n8AM - 10AM"
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmtHour(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    if (d.minute == 0) return '$h$ampm';
    return '$h:${d.minute.toString().padLeft(2, '0')}$ampm';
  }

  String _dateHeader(Map<String, dynamic> data) {
    final start = (data['start_time'] as Timestamp?)?.toDate();
    if (start == null) return data['session_description'] as String? ?? '-';
    final dateStr =
        '${_weekdays[start.weekday - 1]}, ${start.day} ${_months[start.month - 1]} ${start.year}';
    final end = (data['end_time'] as Timestamp?)?.toDate();
    final timeStr = end == null
        ? _fmtHour(start)
        : '${_fmtHour(start)} - ${_fmtHour(end)}';
    return '$dateStr\n$timeStr';
  }

  /// SDD fetchSessions() — live stream of this lecturer's sessions for the
  /// selected subject/Co-Q.
  Stream<QuerySnapshot> fetchSessions() =>
      AttendanceController.lecturerSessionsStream(
        lecturerId: lecturerId,
        subjectId: subjectId,
        coqId: coqId,
      );

  /// SDD displayStatus(msg) — show a status message to the lecturer.
  void displayStatus(BuildContext context, String msg, {bool success = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final stream = fetchSessions();

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
              child: Text(subjectName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            // Add Attendance button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddAttendanceScreen(
                      subjectId:   subjectId,
                      coqId:       coqId,
                      subjectName: subjectName,
                      isCoQ:       isCoQ,
                      lecturerId:  lecturerId,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Attendance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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
                    ...docs.map((doc) {
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
        decoration: BoxDecoration(color: Color(0xFFE8EAFF)),
        children: [
          _Cell('Time & Date', isHeader: true),
          _Cell('Description', isHeader: true),
          _Cell('Class Status', isHeader: true),
          _Cell('Class Location', isHeader: true),
        ],
      );

  TableRow _row(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final status  = data['session_status'] as String? ?? 'Pending';
    final startTs = data['start_time'] as Timestamp?;
    final desc    = data['session_description'] as String? ?? '-';

    final isOnline = data['is_online'] as bool? ?? false;
    String location = 'Online';
    if (!isOnline) {
      final geo = data['session_location'];
      location = geo is GeoPoint
          ? '${geo.latitude.toStringAsFixed(4)},\n'
              '${geo.longitude.toStringAsFixed(4)}'
          : '-';
    }

    void openMenu() => selectSession(context, docId, data, desc);

    return TableRow(children: [
      GestureDetector(
        onTap: openMenu,
        child: Container(
          color: const Color(0xFFF8F9FF),
          padding: const EdgeInsets.all(8),
          child: Text(_fmtTs(startTs),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11)),
        ),
      ),
      _Cell(desc, onTap: openMenu),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: GestureDetector(
            onTap: openMenu,
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
      ),
      _Cell(location, onTap: openMenu),
    ]);
  }

  // SDD selectSession(sessionID) — Figure 3.5.67 class menu shown when a row
  // is tapped.
  void selectSession(BuildContext context, String docId,
      Map<String, dynamic> data, String desc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_dateHeader(data),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.blue),
            title: const Text('Edit Attendance'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => EditAttendanceScreen(
                        sessionId: docId, sessionData: data),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Attendance'),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, docId, data);
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.green),
            title: const Text('Generate Code Attendance'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => GenerateAttendanceScreen(
                        sessionId:   docId,
                        sessionData: data,
                        subjectName: subjectName),
                  ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined, color: _blue),
            title: const Text('View Class Attendant'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => ViewAttendanceScreen(
                        sessionId:          docId,
                        sessionDescription: desc,
                        subjectName:        subjectName,
                        startTime:          data['start_time'] as Timestamp?,
                        endTime:            data['end_time'] as Timestamp?,
                        subjectId:          data['subject_id'] as String? ?? '',
                        coqId:              coqId ?? '',
                        isCoQ:              isCoQ),
                  ));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.arrow_back, color: Colors.black54),
            title: const Text('Back'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // Figure 3.5.70 — delete confirmation dialog.
  void _confirmDelete(
      BuildContext context, String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(children: const [
          Icon(Icons.cancel_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Attendance', style: TextStyle(fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Are you sure you want to Delete Attendance for',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          Text(_dateHeader(data),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _runDelete(context, docId, data);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _runDelete(
      BuildContext context, String docId, Map<String, dynamic> data) async {
    try {
      await AttendanceController.deleteSession(docId);
      if (!context.mounted) return;
      // Figure 3.5.71 — delete successful dialog.
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green.shade600),
            const SizedBox(height: 16),
            const Text('Class has been deleted successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_dateHeader(data),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black54)),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
    } on SessionPassedException {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text(
              'This session has been completed (Passed). '
              'Completed sessions cannot be deleted to preserve records.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      displayStatus(context, 'Error: $e', success: false);
    }
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
            Text('No sessions yet. Tap "Add Attendance" to create one.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final VoidCallback? onTap;
  const _Cell(this.text, {this.isHeader = false, this.onTap});
  @override
  Widget build(BuildContext context) => TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.all(8),
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isHeader ? FontWeight.w600 : FontWeight.normal)),
          ),
        ),
      );
}
