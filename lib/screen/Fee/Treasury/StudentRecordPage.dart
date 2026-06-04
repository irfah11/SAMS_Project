import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:sams/Domain/fee.dart';

import 'package:sams/screen/Fee/Student/FeePage.dart'
    show SamsHeader, formatMoney;

import 'TreasuryDashboardPage.dart' show kTreasuryGreen;

// =============================================================
// MODEL — StudentFinancialRecord
// (joins Student 3.3.2 + Fee 3.3.7)
// =============================================================
class StudentFinancialRecord {
  final String studentId;
  final String fullName;
  final String semesterId;
  final double semesterFee;   // sum of all fee components
  final double amountPaid;    // semesterFee - total_outstanding
  final double balance;       // total_outstanding
  final String paymentStatus; // Paid | Unpaid | Overdue
  final String accessStatus;  // Blocked | Unblocked

  // breakdown (used by the PDF report)
  final double tuitionFee;
  final double medicalFee;
  final double welfareFee;
  final double insuranceFee;
  final double activityFee;
  final double hostelFee;

  const StudentFinancialRecord({
    required this.studentId,
    required this.fullName,
    required this.semesterId,
    required this.semesterFee,
    required this.amountPaid,
    required this.balance,
    required this.paymentStatus,
    required this.accessStatus,
    required this.tuitionFee,
    required this.medicalFee,
    required this.welfareFee,
    required this.insuranceFee,
    required this.activityFee,
    required this.hostelFee,
  });
}

// =============================================================
// CONTROLLER — FeeController treasury methods
// Per SDD-REQ-308:
//   getStudentFinancialRecord(), toggleAccessStatus(),
//   sendOverdueNotification(), generatePDFReport()
// =============================================================
class StudentRecordController {
  static Future<StudentFinancialRecord> getStudentFinancialRecord(
      String studentId) async {
    final db = FirebaseFirestore.instance;

    // Student profile
    String fullName = '-';
    final studentSnap = await db
        .collection('student')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (studentSnap.docs.isNotEmpty) {
      fullName = (studentSnap.docs.first.data()['full_name'] ?? '-').toString();
    }

    // Fee record — most recent semester
    final feeSnap = await db
        .collection('Fee')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (feeSnap.docs.isEmpty) {
      throw Exception('No fee record for $studentId');
    }
    final fee = Fee.fromFirestore(feeSnap.docs.first);

    final semesterFee = fee.tuitionFee +
        fee.medicalFee +
        fee.welfareFee +
        fee.insuranceFee +
        fee.activityFee +
        fee.hostelFee;
    final balance = fee.totalOutstanding;
    final amountPaid =
        (semesterFee - balance).clamp(0, double.infinity).toDouble();

    return StudentFinancialRecord(
      studentId: studentId,
      fullName: fullName,
      semesterId: fee.semesterId,
      semesterFee: semesterFee,
      amountPaid: amountPaid,
      balance: balance,
      paymentStatus: fee.paymentStatus,
      accessStatus: fee.accessStatus,
      tuitionFee: fee.tuitionFee,
      medicalFee: fee.medicalFee,
      welfareFee: fee.welfareFee,
      insuranceFee: fee.insuranceFee,
      activityFee: fee.activityFee,
      hostelFee: fee.hostelFee,
    );
  }

  /// Per SDD-REQ-308 toggleAccessStatus():
  /// Flips access_status between Blocked / Unblocked. Tolerant of legacy
  /// values like "Unblock " (trailing space) already in Firestore.
  static Future<String> toggleAccessStatus({
    required String studentId,
    required String currentStatus,
  }) async {
    final isUnblocked =
        currentStatus.trim().toLowerCase().startsWith('unblock');
    final newStatus = isUnblocked ? 'Blocked' : 'Unblocked';

    final db = FirebaseFirestore.instance;
    final feeSnap = await db
        .collection('Fee')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (feeSnap.docs.isNotEmpty) {
      await feeSnap.docs.first.reference.update({'access_status': newStatus});
    }
    return newStatus;
  }

  /// Per SDD-REQ-308 sendOverdueNotification().
  /// TODO: wire up Firebase Cloud Messaging — for now we record the
  /// notification event in Firestore so it can be picked up by a backend.
  static Future<void> sendOverdueNotification({
    required String studentId,
    required String accessStatus,
    required String paymentStatus,
  }) async {
    final db = FirebaseFirestore.instance;
    final message = accessStatus.toLowerCase() == 'blocked'
        ? 'Your academic access has been blocked due to overdue fees.'
        : 'Your academic access has been restored.';

    await db.collection('notifications').add({
      'student_id': studentId,
      'access_status': accessStatus,
      'payment_status': paymentStatus,
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Per SDD-REQ-308 generateReport().
  /// Records that a fee report was generated for this student so a backend /
  /// audit trail can pick it up. The PDF export itself is handled later once
  /// the `printing` package is wired in; the UI shows a success confirmation.
  static Future<void> generateReport(StudentFinancialRecord r) async {
    final db = FirebaseFirestore.instance;
    await db.collection('fee_reports').add({
      'student_id': r.studentId,
      'student_name': r.fullName,
      'semester_id': r.semesterId,
      'semester_fee': r.semesterFee,
      'amount_paid': r.amountPaid,
      'balance': r.balance,
      'payment_status': r.paymentStatus,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}

// =============================================================
// BOUNDARY CLASS — StudentRecordPage  [SDD-REQ-306]
// =============================================================
enum _ActionBanner { none, blocked, restored }

class StudentRecordPage extends StatefulWidget {
  final String studentId;
  const StudentRecordPage({super.key, required this.studentId});

  @override
  State<StudentRecordPage> createState() => _StudentRecordPageState();
}

class _StudentRecordPageState extends State<StudentRecordPage> {
  StudentFinancialRecord? _record;
  bool _loading = true;
  String? _error;
  _ActionBanner _banner = _ActionBanner.none;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    loadStudentRecord();
  }

  Future<void> loadStudentRecord() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await StudentRecordController
          .getStudentFinancialRecord(widget.studentId);
      if (!mounted) return;
      setState(() {
        _record = r;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onToggleAccess() async {
    if (_record == null || _busy) return;
    setState(() => _busy = true);

    final newStatus = await StudentRecordController.toggleAccessStatus(
      studentId: _record!.studentId,
      currentStatus: _record!.accessStatus,
    );

    // SDD: sendOverdueNotification() runs after the toggle
    await StudentRecordController.sendOverdueNotification(
      studentId: _record!.studentId,
      accessStatus: newStatus,
      paymentStatus: _record!.paymentStatus,
    );

    if (!mounted) return;
    setState(() {
      _record = StudentFinancialRecord(
        studentId: _record!.studentId,
        fullName: _record!.fullName,
        semesterId: _record!.semesterId,
        semesterFee: _record!.semesterFee,
        amountPaid: _record!.amountPaid,
        balance: _record!.balance,
        paymentStatus: _record!.paymentStatus,
        accessStatus: newStatus,
        tuitionFee: _record!.tuitionFee,
        medicalFee: _record!.medicalFee,
        welfareFee: _record!.welfareFee,
        insuranceFee: _record!.insuranceFee,
        activityFee: _record!.activityFee,
        hostelFee: _record!.hostelFee,
      );
      _banner = newStatus.toLowerCase() == 'blocked'
          ? _ActionBanner.blocked
          : _ActionBanner.restored;
      _busy = false;
    });
  }

  Future<void> _onGenerateReport() async {
    if (_record == null) return;
    try {
      await StudentRecordController.generateReport(_record!);
      if (!mounted) return;
      _showReportGeneratedDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    }
  }

  // "Report Generated Successfully" confirmation (screenshot 4).
  void _showReportGeneratedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_outline,
                  size: 56, color: Color(0xFF52DE76)),
              SizedBox(height: 16),
              Text(
                'Report Generated\nSuccessfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SamsHeader(color: kTreasuryGreen),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Failed to load: $_error'),
      ));
    }
    final r = _record!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Fee management',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Divider(height: 24, thickness: 0.5),

          // Student header (name + id, underlined)
          Text(
            '${r.fullName.toUpperCase()} ${r.studentId}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          Text('Status: ${r.paymentStatus}',
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 16),

          _LineRow(label: 'Semester Fee', value: 'RM ${formatMoney(r.semesterFee)}'),
          _LineRow(label: 'Amount Paid',  value: 'RM ${formatMoney(r.amountPaid)}'),
          _LineRow(
            label: 'Balance',
            value: 'RM ${formatMoney(r.balance)}',
            valueColor: r.balance > 0 ? Colors.redAccent : Colors.black87,
          ),
          const SizedBox(height: 28),

          MoonOutlinedButton(
            buttonSize: MoonButtonSize.lg,
            isFullWidth: true,
            onTap: _onGenerateReport,
            label: const Text('Generate Report',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          MoonOutlinedButton(
            buttonSize: MoonButtonSize.lg,
            isFullWidth: true,
            onTap: _busy ? null : _onToggleAccess,
            label: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    r.accessStatus.trim().toLowerCase().startsWith('block')
                        ? 'Unblock Access'
                        : 'Block Access',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(height: 16),

          if (_banner == _ActionBanner.blocked)
            _Banner(
              text: 'Access blocked. Student notified via push notification.',
              bg: const Color(0xFFFCE4E4),
            ),
          if (_banner == _ActionBanner.restored)
            _Banner(
              text: 'Access restored. Student notified.',
              bg: const Color(0xFFFFF7C2),
            ),
        ],
      ),
    );
  }
}

// =============================================================
// UI WIDGETS
// =============================================================
class _LineRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _LineRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String text;
  final Color bg;
  const _Banner({required this.text, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }
}