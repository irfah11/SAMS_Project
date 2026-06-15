import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ViewAttendance.dart';

class GenerateAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;
  final String subjectName;

  const GenerateAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.sessionData,
    required this.subjectName,
  });

  @override
  State<GenerateAttendanceScreen> createState() =>
      _GenerateAttendanceScreenState();
}

class _GenerateAttendanceScreenState
    extends State<GenerateAttendanceScreen> {
  static const _blue = Color(0xFF4C66EE);

  bool _confirmed = false;
  bool _isGenerating = false;
  String? _generatedCode;

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

  String generateAlphanumeric() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }

  // Ensure code uniqueness among Active sessions
  Future<String> _generateUniqueCode() async {
    String code;
    bool isUnique = false;
    do {
      code = generateAlphanumeric();
      final existing = await FirebaseFirestore.instance
          .collection('AttendanceSession')
          .where('attendance_code', isEqualTo: code)
          .where('session_status', isEqualTo: 'Active')
          .limit(1)
          .get();
      isUnique = existing.docs.isEmpty;
    } while (!isUnique);
    return code;
  }

  /// SDD saveCodeToDatabase() — store the code and activate the session.
  Future<void> saveCodeToDatabase(String code) async {
    await FirebaseFirestore.instance
        .collection('AttendanceSession')
        .doc(widget.sessionId)
        .update({
      'attendance_code': code,
      'session_status':  'Active',
    });
  }

  /// SDD requestGenerateCode() — generate a unique code, save it, show it.
  Future<void> requestGenerateCode() async {
    setState(() => _isGenerating = true);
    try {
      final code = await _generateUniqueCode();
      await saveCodeToDatabase(code);

      if (mounted) {
        setState(() {
          _generatedCode  = code;
          _isGenerating   = false;
          _confirmed      = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error generating code: $e')));
      }
    }
  }

  void _copyCode() {
    if (_generatedCode == null) return;
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Code copied to clipboard!'),
        duration: Duration(seconds: 2)));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _confirmed ? displayCode() : _confirmation(),
      ),
    );
  }

  Widget _confirmation() {
    final startTs = widget.sessionData['start_time'];
    final endTs   = widget.sessionData['end_time'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: const [
          Icon(Icons.qr_code, size: 36, color: _blue),
          SizedBox(width: 10),
          Text('Generate Code Attendance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 28),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _blue.withAlpha(80)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.subjectName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(_desc,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('${_fmtTs(startTs)} — ${_fmtTs(endTs)}',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Generate code for this session now? This will open the attendance window for students to check in.',
          style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 32),

        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('No'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isGenerating ? null : requestGenerateCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Yes, Generate',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget displayCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        const Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
        const SizedBox(height: 16),
        const Text('Attendance Code Generated!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(_desc,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
            textAlign: TextAlign.center),
        const SizedBox(height: 36),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _blue.withAlpha(120), width: 2),
          ),
          child: Column(children: [
            const Text('Your Attendance Class Code is',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 12),
            Text(_generatedCode ?? '',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: _blue)),
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Code')),
          ]),
        ),
        const SizedBox(height: 20),
        const Text(
            'Show this code to your students so they can check in.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
            textAlign: TextAlign.center),
        const SizedBox(height: 36),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ViewAttendanceScreen(
                  sessionId:          widget.sessionId,
                  sessionDescription: _desc,
                  subjectName:        widget.subjectName,
                  subjectId:
                      widget.sessionData['subject_id'] as String? ?? '',
                  coqId:
                      widget.sessionData['coq_id'] as String? ?? '',
                  isCoQ:
                      widget.sessionData['is_coq'] as bool? ?? false,
                ),
              ),
            ),
            icon: const Icon(Icons.group_outlined),
            label: const Text('View Class Attendant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Back to Class List'),
          ),
        ),
      ],
    );
  }
}
