import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:moon_design/moon_design.dart';

import 'FeePage.dart';

// =============================================================
// PAYMENT RESULT
// =============================================================
class PaymentResult {
  final bool success;
  final String message;
  final String? transactionId;

  const PaymentResult({
    required this.success,
    required this.message,
    this.transactionId,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['payment_success_stat'] == 'success' ||
          json['success'] == true,
      message: (json['message'] ?? '').toString(),
      transactionId: json['transaction_id']?.toString(),
    );
  }
}

// =============================================================
// CONTROLLER — Payment side
// =============================================================
class PaymentController {
  static const String _baseUrl = 'https://api.example.com';

  static Future<PaymentResult> processPayment({
    required String studentId,
    required String semesterId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? methodDetails,
  }) async {
    final uri = Uri.parse('$_baseUrl/payments');
    final body = jsonEncode({
      'student_id': studentId,
      'semester_id': semesterId,
      'amount_paid': amount,
      'payment_method': paymentMethod,
      'method_details': methodDetails ?? {},
    });

    try {
      final response = await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PaymentResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return PaymentResult(
        success: false,
        message: 'Server error (${response.statusCode}). Please try again.',
      );
    } catch (e) {
      return PaymentResult(success: false, message: 'Network error: $e');
    }
  }
}

// =============================================================
// BOUNDARY CLASS — PaymentPage  [SDD-REQ-302]
// =============================================================
enum PaymentMethod { fpx, card }

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
  String _paymentStatus = 'Pending';

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  bool _submitting = false;

  static const List<String> _banks = [
    'Maybank2U',
    'CIMB Clicks',
    'Public Bank',
    'RHB Bank',
  ];

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void selectPaymentMethod(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;
      if (method == PaymentMethod.card) _selectedBank = null;
    });
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (widget.totalOutstanding <= 0) return false;
    if (_selectedPaymentMethod == null) return false;
    if (_selectedPaymentMethod == PaymentMethod.fpx) {
      return _selectedBank != null;
    }
    return _cardNumberCtrl.text.trim().isNotEmpty &&
        _expiryCtrl.text.trim().isNotEmpty &&
        _cvvCtrl.text.trim().isNotEmpty;
  }

  Future<void> processPayment() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    final method = _selectedPaymentMethod == PaymentMethod.fpx
        ? 'FPX'
        : 'Credit Card';

    final details = _selectedPaymentMethod == PaymentMethod.fpx
        ? {'bank': _selectedBank}
        : {
            'card_number': _cardNumberCtrl.text.trim(),
            'expiry': _expiryCtrl.text.trim(),
            'cvv': _cvvCtrl.text.trim(),
          };

    final result = await PaymentController.processPayment(
      studentId: widget.studentId,
      semesterId: widget.semesterId,
      amount: widget.totalOutstanding,
      paymentMethod: method,
      methodDetails: details,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    displayPaymentResult(result);
  }

  void displayPaymentResult(PaymentResult result) {
    if (result.success) {
      setState(() => _paymentStatus = 'Paid');
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

                    // displayFeeSummary()
                    const SectionTitle('FEE SUMMARY'),
                    const SizedBox(height: 12),
                    LabelAmountRow(label: 'Tuition fee',      amount: f.tuitionFee),
                    LabelAmountRow(label: 'Medical fee',      amount: f.medicalFee),
                    LabelAmountRow(label: 'Student welfare',  amount: f.welfareFee),
                    LabelAmountRow(label: 'Insurance',        amount: f.insuranceFee),
                    LabelAmountRow(label: 'Student activity', amount: f.activityFee),
                    LabelAmountRow(label: 'Hostel activity',  amount: f.hostelFee),
                    LabelAmountRow(label: 'Total outstanding',amount: widget.totalOutstanding),
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
              value: _selectedBank,
              hint: const Text('-Select Bank-'),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                isDense: true,
              ),
              items: _banks
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
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
                  decoration: _fieldDecoration('Card Number'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _expiryCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: _fieldDecoration('Expiry date'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cvvCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        onChanged: (_) => setState(() {}),
                        decoration: _fieldDecoration('CVV'),
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

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}

// =============================================================
// PaymentSuccessPage
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