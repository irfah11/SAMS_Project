import 'package:flutter/material.dart';
import 'package:sams/Domain/transaction.dart';
import 'package:sams/Controller/Fee/FeeController.dart';
import 'package:sams/screen/Manage_Menu/student_menu.dart';

import 'FeePage.dart'; // for SamsHeader, SectionTitle, formatDate, formatMoney
import 'TransactionDetailsPage.dart';

// =============================================================
// BOUNDARY CLASS — TransactionPage
// Data access lives in FeeController (lib/Controller/Fee/FeeController.dart).
// =============================================================
class TransactionPage extends StatefulWidget {
  final String studentId;
  const TransactionPage({super.key, required this.studentId});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  late Future<List<Transaction>> _future;

  @override
  void initState() {
    super.initState();
    _future = getHistory();
  }

  // getHistory() — SDD-REQ-303: load this student's transaction history.
  Future<List<Transaction>> getHistory() =>
      FeeController.getTransactionHistory(widget.studentId);

  void navigateToDetails(Transaction tx) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailsPage(transaction: tx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Drawer so the header's menu icon opens the student navigation here.
      drawer: StudentDrawer(studentId: widget.studentId),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SamsHeader(),
            Expanded(
              child: FutureBuilder<List<Transaction>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Failed to load: ${snapshot.error}'),
                      ),
                    );
                  }
                  final txs = snapshot.data ?? [];
                  if (txs.isEmpty) {
                    return const Center(
                      child: Text('No transactions yet.'),
                    );
                  }

                  final grouped =
                      FeeController.groupByYear(txs);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            color: Colors.black,
                          ),
                        ),
                        const Divider(height: 24, thickness: 0.5),

                        // Year groups
                        for (final group in grouped) ...[
                          Text(
                            group.key, // "2025/2026"
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final tx in group.value)
                            _TransactionTile(
                              tx: tx,
                              onTap: () => navigateToDetails(tx),
                            ),
                          const SizedBox(height: 16),
                        ],
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
// UI — Transaction list item
// =============================================================
class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  final VoidCallback onTap;

  const _TransactionTile({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.semesterId, // e.g. "Semester 2 2025/2026"
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatDate(tx.transactionDate)} · ${tx.paymentMethod} · ${tx.transactionId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'RM ${formatMoney(tx.amountPaid)}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}