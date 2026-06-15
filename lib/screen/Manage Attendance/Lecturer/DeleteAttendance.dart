import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';

class DeleteAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String sessionDescription;

  const DeleteAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.sessionDescription,
  });

  @override
  State<DeleteAttendanceScreen> createState() =>
      _DeleteAttendanceScreenState();
}

class _DeleteAttendanceScreenState extends State<DeleteAttendanceScreen> {
  static const _blue = Color(0xFF4C66EE);
  bool _isDeleting = false;

  /// SDD verifySessionStatus() — a session can only be deleted if it has not
  /// already been completed (Passed).
  Future<bool> verifySessionStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('AttendanceSession')
        .doc(widget.sessionId)
        .get();
    if (!doc.exists) return false;
    return AttendanceController.effectiveStatus(doc.data()!) != 'Passed';
  }

  /// SDD cancelSession() — delete the session and its attendance records.
  Future<void> cancelSession() =>
      AttendanceController.deleteSession(widget.sessionId);

  /// SDD displayStatus(msg) — show a status message to the lecturer.
  void displayStatus(String msg, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  /// SDD requestDeletion() — user-confirmed deletion flow.
  Future<void> requestDeletion() async {
    setState(() => _isDeleting = true);
    try {
      if (!await verifySessionStatus()) {
        if (mounted) {
          setState(() => _isDeleting = false);
          _showCannotDelete();
        }
        return;
      }
      await cancelSession();
      if (mounted) {
        displayStatus('Class has been deleted successfully.');
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } on SessionPassedException {
      if (mounted) {
        setState(() => _isDeleting = false);
        _showCannotDelete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        displayStatus('Error: $e', success: false);
      }
    }
  }

  void _showCannotDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cannot Delete'),
        content: const Text(
            'This session has been completed (Passed). '
            'Completed sessions cannot be deleted to preserve records.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            onPressed: () => Navigator.pop(context)),
        title: const Text('SAMS',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.delete_outline, size: 36, color: Colors.red),
              SizedBox(width: 10),
              Text('Delete Attendance',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session to be deleted:',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text(widget.sessionDescription,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(children: const [
                Icon(Icons.warning_amber_outlined,
                    color: Colors.orange, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This will permanently delete the session and all student attendance records.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ]),
            ),
            const Spacer(),

            const Text(
              'Are you sure you want to delete this session?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('No, Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isDeleting ? null : requestDeletion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Yes, Delete',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
