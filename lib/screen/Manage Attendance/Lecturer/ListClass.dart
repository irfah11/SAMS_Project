import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';
import 'AddAttendance.dart';
import 'EditAttendance.dart';
import 'DeleteAttendance.dart';
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

  @override
  Widget build(BuildContext context) {
    final stream = AttendanceController.lecturerSessionsStream(
      lecturerId: lecturerId,
      subjectId: subjectId,
      coqId: coqId,
    );

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
                return Column(
                  children: snap.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _buildTile(context, doc.id, d);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
      BuildContext context, String docId, Map<String, dynamic> data) {
    final status  = data['session_status'] as String? ?? 'Pending';
    final startTs = data['start_time'] as Timestamp?;
    final endTs   = data['end_time'] as Timestamp?;
    final desc    = data['session_description'] as String? ?? '-';
    final timeStr = '${_fmtTs(startTs)} — ${_fmtTs(endTs)}';

    return GestureDetector(
      onTap: () => _showActionSheet(context, docId, data, desc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Container(
            width: 6,
            height: 48,
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          title: Text(desc,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(timeStr,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(status,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.more_vert, color: Colors.black54),
          ]),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context, String docId,
      Map<String, dynamic> data, String desc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(desc,
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
              Navigator.push(context,
                  MaterialPageRoute(
                    builder: (_) => DeleteAttendanceScreen(
                        sessionId: docId, sessionDescription: desc),
                  ));
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
                        subjectName:        subjectName),
                  ));
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
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
