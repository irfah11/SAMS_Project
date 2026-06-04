import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';

class AttendanceCheckInScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;
  final String subjectName;
  // Option B: matric student_id (e.g. "CB23028") — NOT Firebase Auth UID
  final String? studentId;

  const AttendanceCheckInScreen({
    super.key,
    required this.sessionId,
    required this.sessionData,
    required this.subjectName,
    required this.studentId,
  });

  @override
  State<AttendanceCheckInScreen> createState() =>
      _AttendanceCheckInScreenState();
}

class _AttendanceCheckInScreenState
    extends State<AttendanceCheckInScreen> {
  final _codeController = TextEditingController();
  bool _gpsEnabled = false;
  bool _isLoading = false;

  String get _desc =>
      widget.sessionData['session_description'] as String? ?? '-';

  String _fmtTs(dynamic ts) {
    if (ts == null) return '-';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckIn() async {
    final entered = _codeController.text.trim().toUpperCase();

    if (!_gpsEnabled) {
      _showResult(
          success: false,
          message: 'You are not within the class location. Attendance not recorded.',
          icon: Icons.gps_off);
      return;
    }
    if (entered.isEmpty) {
      _showResult(
          success: false,
          message: 'Please enter the class code.',
          icon: Icons.warning_amber);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final studentIdToWrite = widget.studentId ?? uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final studentName =
          userDoc.data()?['name'] as String? ?? studentIdToWrite;

      final result = await AttendanceController.checkIn(
        sessionId:   widget.sessionId,
        studentId:   studentIdToWrite,
        studentName: studentName,
        enteredCode: entered,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showResult(
          success: result.success,
          message: result.message,
          icon: result.success
              ? Icons.check_circle_outline
              : Icons.cancel_outlined,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showResult(
            success: false,
            message: 'An error occurred: $e',
            icon: Icons.error_outline);
      }
    }
  }

  void _showResult(
      {required bool success,
      required String message,
      required IconData icon}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 64,
              color: success
                  ? Colors.green.shade600
                  : Colors.red.shade600),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startTs = widget.sessionData['start_time'];
    final endTs   = widget.sessionData['end_time'];
    final timeStr = '${_fmtTs(startTs)} — ${_fmtTs(endTs)}';

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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.people_outline, size: 40),
              SizedBox(width: 10),
              Text('Manage Attendance',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 6),
            Text(widget.subjectName,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black54)),
            if (widget.studentId != null) ...[
              const SizedBox(height: 2),
              Text('Student ID: ${widget.studentId}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black38)),
            ],
            const SizedBox(height: 24),

            // Session info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5CE1E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_desc,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(timeStr,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // GPS toggle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _gpsEnabled
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _gpsEnabled
                        ? Colors.green.shade300
                        : Colors.orange.shade300),
              ),
              child: Row(children: [
                Icon(
                    _gpsEnabled ? Icons.gps_fixed : Icons.gps_off,
                    color: _gpsEnabled
                        ? Colors.green.shade700
                        : Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _gpsEnabled
                        ? 'GPS Enabled — Location verified'
                        : 'GPS Required — Enable to check in',
                    style: TextStyle(
                        fontSize: 13,
                        color: _gpsEnabled
                            ? Colors.green.shade800
                            : Colors.orange.shade800),
                  ),
                ),
                Switch(
                  value: _gpsEnabled,
                  onChanged: (v) => setState(() => _gpsEnabled = v),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // Class code field
            const Text('Class Code',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter 6-character code (e.g. QWE123)',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Colors.black38),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color(0xFF5CE1E6), width: 2),
                ),
                prefixIcon:
                    const Icon(Icons.keyboard, color: Colors.black54),
              ),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CE1E6),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enter',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
