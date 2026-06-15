import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';

class ViewAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String sessionDescription;
  final String subjectName;
  final String subjectId;
  final String coqId;
  final bool isCoQ;
  final Timestamp? startTime;
  final Timestamp? endTime;

  const ViewAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.sessionDescription,
    required this.subjectName,
    required this.subjectId,
    this.coqId = '',
    this.isCoQ = false,
    this.startTime,
    this.endTime,
  });

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  static const _blue = Color(0xFF4C66EE);

  String _search = '';

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

  String _dateHeader() {
    final start = widget.startTime?.toDate();
    if (start == null) return widget.sessionDescription;
    final dateStr =
        '${_weekdays[start.weekday - 1]}, ${start.day} ${_months[start.month - 1]} ${start.year}';
    final end = widget.endTime?.toDate();
    final timeStr = end == null
        ? _fmtHour(start)
        : '${_fmtHour(start)} - ${_fmtHour(end)}';
    return '$dateStr\n$timeStr';
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
              Icon(Icons.group_outlined, size: 32, color: _blue),
              SizedBox(width: 10),
              Text('View Class Attendant',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 16),
            Center(
              child: Text(_dateHeader(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              onChanged: (v) => setState(() => _search = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search Bar',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text('Tap a row or status badge to update it.',
                style: TextStyle(fontSize: 12, color: Colors.black38)),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchStudentAttendance(),
              builder: (context, rosterSnap) {
                if (rosterSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final roster = rosterSnap.data ?? [];
                if (roster.isEmpty) {
                  return _buildEmpty();
                }
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: AttendanceController.sessionRosterStream(
                      sessionId: widget.sessionId, roster: roster),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final all = (snap.data ?? List.from(roster))
                      ..sort((a, b) => (a['full_name'] as String)
                          .compareTo(b['full_name'] as String));
                    final q = _search.toLowerCase();
                    final entries = q.isEmpty
                        ? all
                        : all.where((e) {
                            final name =
                                (e['full_name'] as String? ?? '').toLowerCase();
                            final id =
                                (e['student_id'] as String? ?? '').toLowerCase();
                            return name.contains(q) || id.contains(q);
                          }).toList();
                    return Column(children: [
                      _buildStats(all),
                      const SizedBox(height: 16),
                      Table(
                        border: TableBorder.all(
                            color: Colors.grey.shade400, width: 0.5),
                        columnWidths: const {
                          0: FlexColumnWidth(2.2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2.8),
                          3: FlexColumnWidth(1.8),
                          4: FlexColumnWidth(2),
                        },
                        children: [
                          _hdr(),
                          ...entries.map((e) => _row(context, e)),
                        ],
                      ),
                    ]);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(List<Map<String, dynamic>> entries) {
    int p = 0, a = 0, l = 0;
    for (final e in entries) {
      final s = e['status'] as String? ?? 'Absent';
      if (s == 'Present') {
        p++;
      } else if (s == 'Late') {
        l++;
      } else {
        a++;
      }
    }
    return Row(children: [
      _Chip('Present', p, Colors.green.shade600),
      const SizedBox(width: 8),
      _Chip('Late', l, Colors.orange.shade600),
      const SizedBox(width: 8),
      _Chip('Absent', a, Colors.red.shade600),
      const Spacer(),
      Text('Total: ${entries.length}',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54)),
    ]);
  }

  TableRow _hdr() => const TableRow(
        decoration: BoxDecoration(color: Color(0xFFE8EAFF)),
        children: [
          _HCell('Time & Date'),
          _HCell('Matric ID'),
          _HCell('Full Name'),
          _HCell('Status'),
          _HCell('Location'),
        ],
      );

  TableRow _row(BuildContext context, Map<String, dynamic> entry) {
    final status   = entry['status'] as String? ?? 'Absent';
    final name     = entry['full_name'] as String? ?? '-';
    final matricId = entry['student_id'] as String? ?? '-';
    final ts       = entry['check_in_time'] as Timestamp?;
    final recordId = entry['record_id'] as String?;

    String location = '-';
    final geo = entry['record_location'];
    if (geo is GeoPoint) {
      location = '${geo.latitude.toStringAsFixed(3)},\n'
                 '${geo.longitude.toStringAsFixed(3)}';
    }

    return TableRow(children: [
      _DCell(_fmtTs(ts)),
      _DCell(matricId),
      GestureDetector(
        onTap: () =>
            editStudentStatus(context, recordId, matricId, status, name),
        child: Container(
          color: const Color(0xFFF8F9FF),
          padding: const EdgeInsets.all(8),
          child: Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11)),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: GestureDetector(
            onTap: () =>
                editStudentStatus(context, recordId, matricId, status, name),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 4),
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
      _DCell(location),
    ]);
  }

  /// SDD fetchStudentAttendance() — roster of students for this subject or
  /// Co-Q module (Co-Q sessions have no subject_id).
  Future<List<Map<String, dynamic>>> fetchStudentAttendance() =>
      widget.isCoQ
          ? AttendanceController.fetchCoQRoster(widget.coqId)
          : AttendanceController.fetchSubjectRoster(widget.subjectId);

  /// SDD updateAttendanceRecord() — persist a student's new status.
  Future<void> updateAttendanceRecord(String? recordId, String studentId,
      String studentName, String newStatus) {
    return AttendanceController.setRecordStatus(
      recordId:    recordId,
      sessionId:   widget.sessionId,
      studentId:   studentId,
      studentName: studentName,
      newStatus:   newStatus,
    );
  }

  /// SDD refreshList() — rebuild the attendant table.
  void refreshList() {
    if (mounted) setState(() {});
  }

  // SDD editStudentStatus(studentID) — opens dialog for lecturer to override
  // attendance status. recordId is null when the student has no
  // AttendanceRecord yet (never checked in); saving creates a new record.
  void editStudentStatus(BuildContext context, String? recordId,
      String studentId, String currentStatus, String studentName) {
    String selected = currentStatus;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Edit Status — $studentName',
              style: const TextStyle(fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Present', 'Absent', 'Late'].map((s) {
              return RadioListTile<String>(
                title: Text(s),
                value: s,
                groupValue: selected,
                activeColor: _blue,
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
                await updateAttendanceRecord(
                    recordId, studentId, studentName, selected);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
                    content: Text(
                        'Status updated to "$selected" for $studentName'),
                    backgroundColor: Colors.green,
                  ));
                  refreshList();
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: _blue, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
            Text('No students registered for this subject yet.',
                style: TextStyle(fontSize: 14, color: Colors.black54)),
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
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
