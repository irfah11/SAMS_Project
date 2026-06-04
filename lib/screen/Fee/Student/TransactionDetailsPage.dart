import 'package:flutter/material.dart';
import 'package:sams/Domain/transaction.dart';
import 'package:sams/Controller/Fee/FeeController.dart';

import 'FeePage.dart'; // for SamsHeader, SectionTitle, LabelAmountRow, formatDate, formatMoney

// =============================================================
// BOUNDARY CLASS — TransactionDetailsPage
// Receipt data (Student + Fee join) is built by FeeController
// (lib/Controller/Fee/FeeController.dart), returning a ReceiptData.
// =============================================================
class TransactionDetailsPage extends StatefulWidget {
  final Transaction transaction;
  const TransactionDetailsPage({super.key, required this.transaction});

  @override
  State<TransactionDetailsPage> createState() =>
      _TransactionDetailsPageState();
}

class _TransactionDetailsPageState extends State<TransactionDetailsPage> {
  late Future<ReceiptData> _future;

  @override
  void initState() {
    super.initState();
    _future = FeeController.fetchReceiptData(widget.transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SamsHeader(),
            Expanded(
              child: FutureBuilder<ReceiptData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Text('Failed to load receipt.'),
                    );
                  }
                  return _buildBody(snapshot.data!);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ReceiptData r) {
    // Display "Sem 2 2025/26" style from "Semester 2 2025/2026"
    final shortSemester = _shortSemester(r.semesterId);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                color: Colors.black,
              ),
            ),
          ),
          const Divider(height: 24, thickness: 0.5),

          const Text(
            'Payment Receipt',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            r.transactionId,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          // ---- Blue info card ----
          _InfoCard(rows: [
            _InfoRow(label: 'Name',       value: r.studentName),
            _InfoRow(label: 'Matrix',     value: r.studentId),
            _InfoRow(label: 'Receipt no.', value: r.transactionId),
            _InfoRow(label: 'Date',       value: formatDate(r.date)),
            _InfoRow(label: 'Method',     value: r.paymentMethod),
            _InfoRow(label: 'Semester',   value: shortSemester),
          ]),
          const SizedBox(height: 24),

          // ---- Fee summary ----
          const SectionTitle('FEE SUMMARY'),
          const SizedBox(height: 12),
          LabelAmountRow(label: 'Tuition fee',      amount: r.tuitionFee),
          LabelAmountRow(label: 'Medical fee',      amount: r.medicalFee),
          LabelAmountRow(label: 'Student welfare',  amount: r.welfareFee),
          LabelAmountRow(label: 'Insurance',        amount: r.insuranceFee),
          LabelAmountRow(label: 'Student activity', amount: r.activityFee),
          LabelAmountRow(label: 'Hostel activity',  amount: r.hostelFee),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total outstanding',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              Text(
                'RM ${formatMoney(r.totalPaid)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortSemester(String semesterId) {
    // "Semester 2 2025/2026" → "Sem 2 2025/26"
    final m = RegExp(r'Semester\s+(\d+)\s+(\d{4})/(\d{4})').firstMatch(semesterId);
    if (m != null) {
      final n = m.group(1);
      final y1 = m.group(2);
      final y2 = m.group(3)!.substring(2);
      return 'Sem $n $y1/$y2';
    }
    return semesterId;
  }
}

// =============================================================
// UI — Blue info card with label/value rows
// =============================================================
class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3ECF7), // soft blue
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F4E8C),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1F4E8C),
            ),
          ),
        ),
      ],
    );
  }
}