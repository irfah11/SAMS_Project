import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';
import 'package:sams/Domain/fee.dart';
import 'package:sams/Controller/Fee/FeeController.dart';

import 'FeePage.dart';

// =============================================================
// BOUNDARY CLASS — PaymentPage  [SDD-REQ-302]
// Payment logic lives in FeeController (processPayment()).
// This is a simulated gateway: choosing any bank / entering any card and
// tapping "Confirm payment" records the payment in Firestore and succeeds.
// =============================================================
enum PaymentMethod { fpx, card }

// FPX banks shown in the dropdown (cosmetic — any choice succeeds).
const List<String> kFpxBanks = [
  'Maybank2u',
  'CIMB Clicks',
  'Public Bank',
  'RHB Bank',
  'MyBSN',
  'Affin Bank',
  'Bank Islam',
];

class PaymentPage extends StatefulWidget {
  final String studentId;
  final String semesterId;
  final double totalOutstanding;
  final Fee feeBreakdown;

  const PaymentPage({
    super.key,
    required this.studentId,
    required this.semesterId,
    required this.totalOutstanding,
    required this.feeBreakdown,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod? _selectedPaymentMethod;
  String? _selectedBank;

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void selectPaymentMethod(PaymentMethod method) {
    setState(() => _selectedPaymentMethod = method);
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (widget.totalOutstanding <= 0) return false;
    if (_selectedPaymentMethod == null) return false;
    if (_selectedPaymentMethod == PaymentMethod.fpx) return _selectedBank != null;
    // Card → just need a card number typed (any value works).
    return _cardNumberCtrl.text.trim().isNotEmpty;
  }

  // processPayment() — records the payment in Firestore (FeeController), which
  // marks the Fee as Paid and stores a transaction, then shows the receipt.
  Future<void> processPayment() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    final method = _selectedPaymentMethod == PaymentMethod.fpx
        ? 'FPX${_selectedBank != null ? ' - $_selectedBank' : ''}'
        : 'Credit / Debit Card';

    final result = await FeeController.processPayment(
      studentId: widget.studentId,
      semesterId: widget.semesterId,
      amount: widget.totalOutstanding,
      paymentMethod: method,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    displayPaymentResult(result);
  }

  void displayPaymentResult(PaymentResult result) {
    if (result.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            studentId: widget.studentId,
            semesterId: widget.semesterId,
            transactionId: result.transactionId ?? '-',
            paymentDate: DateTime.now(),
            totalPaid: widget.totalOutstanding,
          ),
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Payment Failed'),
          content: Text(
            result.message.isEmpty ? 'Please try again.' : result.message,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feeBreakdown;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SamsHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pay Tuition',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                      ),
                    ),
                    const Divider(height: 24, thickness: 0.5),

                    displayFeeSummary(f),
                    const SizedBox(height: 20),

                    const SectionTitle('PAYMENT METHOD'),
                    const SizedBox(height: 8),
                    _buildFpxOption(),
                    _buildCardOption(),
                    const SizedBox(height: 20),

                    MoonOutlinedButton(
                      buttonSize: MoonButtonSize.lg,
                      isFullWidth: true,
                      onTap: _canSubmit ? processPayment : null,
                      label: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Confirm payment',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                    const SizedBox(height: 12),
                    MoonOutlinedButton(
                      buttonSize: MoonButtonSize.lg,
                      isFullWidth: true,
                      onTap: () => Navigator.of(context).pop(),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // displayFeeSummary() — SDD-REQ-302: itemized fee breakdown + total.
  Widget displayFeeSummary(Fee f) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('FEE SUMMARY'),
        const SizedBox(height: 12),
        LabelAmountRow(label: 'Tuition fee',      amount: f.tuitionFee),
        LabelAmountRow(label: 'Medical fee',      amount: f.medicalFee),
        LabelAmountRow(label: 'Student welfare',  amount: f.welfareFee),
        LabelAmountRow(label: 'Insurance',        amount: f.insuranceFee),
        LabelAmountRow(label: 'Student activity', amount: f.activityFee),
        LabelAmountRow(label: 'Hostel activity',  amount: f.hostelFee),
        LabelAmountRow(
            label: 'Total outstanding', amount: widget.totalOutstanding),
      ],
    );
  }

  Widget _buildFpxOption() {
    final selected = _selectedPaymentMethod == PaymentMethod.fpx;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => selectPaymentMethod(PaymentMethod.fpx),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Radio<PaymentMethod>(
                  value: PaymentMethod.fpx,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (v) => selectPaymentMethod(v!),
                ),
                const Text(
                  'FPX - Online banking',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        if (selected)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 0, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedBank,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
              hint: const Text('-Select Bank-',
                  style: TextStyle(fontSize: 13)),
              items: [
                for (final bank in kFpxBanks)
                  DropdownMenuItem(value: bank, child: Text(bank)),
              ],
              onChanged: (v) => setState(() => _selectedBank = v),
            ),
          ),
      ],
    );
  }

  Widget _buildCardOption() {
    final selected = _selectedPaymentMethod == PaymentMethod.card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => selectPaymentMethod(PaymentMethod.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Radio<PaymentMethod>(
                  value: PaymentMethod.card,
                  groupValue: _selectedPaymentMethod,
                  onChanged: (v) => selectPaymentMethod(v!),
                ),
                const Text(
                  'Credit / debit card',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        if (selected)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CARD DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: _cardInput('Card Number'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryCtrl,
                        decoration: _cardInput('Expiry date'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cvvCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: _cardInput('CVV'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _cardInput(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
    );
  }
}

// =============================================================
// PaymentSuccessPage  [SDD-REQ-303: receipt summary]
// =============================================================
class PaymentSuccessPage extends StatelessWidget {
  final String studentId;
  final String semesterId;
  final String transactionId;
  final DateTime paymentDate;
  final double totalPaid;

  const PaymentSuccessPage({
    super.key,
    required this.studentId,
    required this.semesterId,
    required this.transactionId,
    required this.paymentDate,
    required this.totalPaid,
  });

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SuccessCard(
                      studentId: studentId,
                      semesterId: semesterId,
                    ),
                    const SizedBox(height: 24),
                    const SectionTitle('RECEIPT SUMMARY'),
                    const SizedBox(height: 12),
                    LabelValueRow(
                      label: 'Receipt no.',
                      value: transactionId,
                    ),
                    LabelValueRow(
                      label: 'Date',
                      value: formatDate(paymentDate),
                    ),
                    LabelValueRow(
                      label: 'Total Paid',
                      value: 'RM ${formatMoney(totalPaid)}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  final String studentId;
  final String semesterId;
  const _SuccessCard({required this.studentId, required this.semesterId});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5C8C8), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF5EA),
            ),
            child: const Icon(Icons.check,
                color: Color(0xFF2E7D32), size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You successfully made the payment for Student Fee - $studentId $semesterId',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
