import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

import 'package:sams/Controller/Fee/FeeController.dart';
import 'package:sams/screen/Fee/Student/FeePage.dart'
    show SamsHeader, formatMoney;
import 'package:sams/screen/Manage_Menu/treasury_menu.dart';

import 'TreasuryDashboardPage.dart' show kTreasuryGreen;

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
      // Drawer so the header's menu icon reaches the treasury navigation here.
      drawer: const TreasuryMenu(),
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