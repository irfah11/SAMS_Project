import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:sams/Domain/fee.dart';
import 'package:sams/Controller/Fee/FeeController.dart';
import 'package:sams/screen/Manage_Menu/student_menu.dart';

import 'PaymentPage.dart';
import 'TransactionPage.dart';

// =============================================================
// BOUNDARY CLASS — FeePage  [SDD-REQ-301]
// Data access lives in FeeController (lib/Controller/Fee/FeeController.dart).
// =============================================================
class FeePage extends StatefulWidget {
  final String studentId;
  const FeePage({super.key, required this.studentId});

  @override
  State<FeePage> createState() => _FeePageState();
}

class _FeePageState extends State<FeePage> {
  late Future<Fee> _feeFuture;

  @override
  void initState() {
    super.initState();
    _feeFuture = FeeController.fetchCurrentFees(widget.studentId);
  }

  void navigateToPayment(Fee fee) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PaymentPage(
        studentId: widget.studentId,
        semesterId: fee.semesterId,
        totalOutstanding: fee.totalOutstanding,
        feeBreakdown: fee,
      ),
    ));
  }

  void navigateToTransactions() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TransactionPage(studentId: widget.studentId),
    ));
  }

  // Shown when a paid student taps the (disabled) Pay tuition button.
  void _showNoOutstandingDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('No outstanding amount'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
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
      drawer: StudentDrawer(studentId: widget.studentId),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SamsHeader(),
            Expanded(
              child: FutureBuilder<Fee>(
                future: _feeFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Text('Failed to load fee record.'),
                    );
                  }
                  final fee = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Fees',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            color: Colors.black,
                          ),
                        ),
                        const Divider(height: 24, thickness: 0.5),
                        _FeeHighlightCard(fee: fee),
                        const SizedBox(height: 24),
                        const SectionTitle('FEE SUMMARY'),
                        const SizedBox(height: 12),
                        LabelAmountRow(label: 'Tuition fee',      amount: fee.tuitionFee),
                        LabelAmountRow(label: 'Medical fee',      amount: fee.medicalFee),
                        LabelAmountRow(label: 'Student welfare',  amount: fee.welfareFee),
                        LabelAmountRow(label: 'Insurance',        amount: fee.insuranceFee),
                        LabelAmountRow(label: 'Student activity', amount: fee.activityFee),
                        LabelAmountRow(label: 'Hostel',  amount: fee.hostelFee),
                        LabelAmountRow(label: 'Total outstanding',amount: fee.totalOutstanding),
                        const SizedBox(height: 28),
                        if (fee.totalOutstanding > 0)
                          MoonOutlinedButton(
                            buttonSize: MoonButtonSize.lg,
                            isFullWidth: true,
                            onTap: () => navigateToPayment(fee),
                            label: const Text(
                              'Pay tuition',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          )
                        else
                          // Nothing owed — greyed out, taps just explain why.
                          InkWell(
                            onTap: _showNoOutstandingDialog,
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDEDED),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFBDBDBD)),
                              ),
                              child: const Text(
                                'Pay tuition',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        MoonOutlinedButton(
                          buttonSize: MoonButtonSize.lg,
                          isFullWidth: true,
                          onTap: navigateToTransactions,
                          label: const Text(
                            'View transactions',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// SHARED UI WIDGETS (used by FeePage + PaymentPage)
// =============================================================
class SamsHeader extends StatelessWidget {
  final Color color;
  const SamsHeader({super.key, this.color = const Color(0xFF5EE7E7)});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SAMS',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  offset: const Offset(2, 2),
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
          IconButton(
            // Opens the navigation drawer on pages that have one (e.g. FeePage).
            // Safely does nothing on pages without a drawer.
            onPressed: () {
              final scaffold = Scaffold.maybeOf(context);
              if (scaffold != null && scaffold.hasDrawer) {
                scaffold.openDrawer();
              }
            },
            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Colors.black,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _FeeHighlightCard extends StatelessWidget {
  final Fee fee;
  const _FeeHighlightCard({required this.fee});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RM ${formatMoney(fee.totalOutstanding)}',
            style: const TextStyle(
              fontSize: 32,
              color: Color(0xFFE74C4C),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fee.dueWeek.trim().isEmpty
                ? fee.semesterId
                : '${fee.semesterId} · ${fee.dueWeek}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFE74C4C),
            ),
          ),
          const SizedBox(height: 12),
          MoonTag(
            tagSize: MoonTagSize.xs,
            backgroundColor: const Color(0xFF2E7D32),
            label: Text(
              fee.accessStatus.trim().toLowerCase().startsWith('unblock')
                  ? 'ACTIVE'
                  : 'BLOCKED',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LabelAmountRow extends StatelessWidget {
  final String label;
  final double amount;
  const LabelAmountRow({super.key, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return LabelValueRow(label: label, value: 'RM ${formatMoney(amount)}');
  }
}

class LabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  const LabelValueRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(value,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}

// =============================================================
// HELPERS (shared)
// =============================================================
String formatDate(DateTime d) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}

String formatMoney(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    final idxFromRight = whole.length - i;
    buf.write(whole[i]);
    if (idxFromRight > 1 && (idxFromRight - 1) % 3 == 0) buf.write(',');
  }
  return '$buf.${parts[1]}';
}