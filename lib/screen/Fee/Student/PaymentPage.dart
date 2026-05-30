import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'package:moon_design/moon_design.dart';
import 'package:sams/Domain/fee.dart';
import 'package:sams/Domain/transaction.dart';
import 'package:sams/config/billplz_config.dart';
import 'package:sams/config/stripe_config.dart';
import 'package:url_launcher/url_launcher.dart';

import 'FeePage.dart';
import 'TransactionPage.dart';

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
}

// =============================================================
// CONTROLLER — Payment side (writes to Firestore)
// =============================================================
class PaymentController {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<PaymentResult> processPayment({
    required String studentId,
    required String semesterId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? methodDetails,
  }) async {
    try {
      final now = DateTime.now();
      final transactionId = _generateTransactionId(now);

      final txn = Transaction(
        transactionId: transactionId,
        studentId: studentId,
        semesterId: semesterId,
        amountPaid: amount,
        paymentMethod: paymentMethod,
        transactionDate: now,
        paymentSuccessStat: 'success',
      );

      // 1. Record the payment in the 'transactions' collection.
      await _db.collection('transactions').add(txn.toFirebase());

      // 2. Mark this student's fee for the semester as fully paid and
      //    restore access. Done as a query+update so it targets the
      //    correct Fee document regardless of its doc id.
      final feeQuery = await _db
          .collection('Fee')
          .where('student_id', isEqualTo: studentId)
          .where('semester_id', isEqualTo: semesterId)
          .limit(1)
          .get();

      if (feeQuery.docs.isNotEmpty) {
        await feeQuery.docs.first.reference.update({
          'payment_status': 'Paid',
          'access_status': 'Unblocked',
          'total_outstanding': 0,
        });
      }

      return PaymentResult(
        success: true,
        message: 'Payment successful',
        transactionId: transactionId,
      );
    } catch (e) {
      return PaymentResult(success: false, message: 'Payment failed: $e');
    }
  }

  // Build a human-readable receipt number, e.g. "RP2605-43187".
  static String _generateTransactionId(DateTime now) {
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final seq =
        (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'RP$yy$mm-$seq';
  }
}

// =============================================================
// STRIPE BACKEND HOOK
// -------------------------------------------------------------
// Stripe requires a PaymentIntent to be created with your SECRET key, which
// must stay on a server (e.g. a Firebase Cloud Function). The app only ever
// sees the resulting `client_secret`.
//
// TODO(backend): deploy an endpoint that does, in Node:
//   const pi = await stripe.paymentIntents.create({
//     amount, currency, metadata: { student_id, semester_id },
//   });
//   return { client_secret: pi.client_secret };
// then set StripeConfig.createPaymentIntentUrl to its URL.
// =============================================================
class StripeBackend {
  /// Returns the PaymentIntent `client_secret` for [amount] (major units, e.g.
  /// RM 15.10). Throws a clear error until the backend URL is configured.
  static Future<String> createPaymentIntent({
    required double amount,
    required String studentId,
    required String semesterId,
  }) async {
    if (StripeConfig.createPaymentIntentUrl.isEmpty) {
      throw Exception(
        'Card payments are not live yet: no payment backend configured. '
        'Deploy a Cloud Function that creates a Stripe PaymentIntent with your '
        'secret key and set StripeConfig.createPaymentIntentUrl.',
      );
    }

    final response = await http.post(
      Uri.parse(StripeConfig.createPaymentIntentUrl),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        // Stripe expects the amount in the smallest currency unit (sen).
        'amount': (amount * 100).round(),
        'currency': StripeConfig.currency,
        'student_id': studentId,
        'semester_id': semesterId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Backend error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secret = data['client_secret'] ?? data['clientSecret'];
    if (secret == null) {
      throw Exception('Backend did not return a client_secret.');
    }
    return secret.toString();
  }
}

// =============================================================
// BILLPLZ BACKEND HOOK (FPX online banking)
// -------------------------------------------------------------
// Asks our backend (the `createBill` Cloud Function) to create a Billplz bill
// with the secret key and return the hosted payment URL. The app opens that URL;
// Billplz then notifies the backend webhook, which marks the fee paid.
// =============================================================
class BillplzBackend {
  /// Returns the hosted Billplz bill URL for this student's outstanding fee.
  /// The amount is computed server-side from the Fee document.
  static Future<String> createBill({
    required String studentId,
    required String semesterId,
  }) async {
    if (BillplzConfig.createBillUrl.isEmpty) {
      throw Exception(
        'FPX is not live yet: no payment backend configured. Deploy the '
        'createBill Cloud Function and set BillplzConfig.createBillUrl.',
      );
    }

    final response = await http.post(
      Uri.parse(BillplzConfig.createBillUrl),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'student_id': studentId, 'semester_id': semesterId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Backend error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['url'];
    if (url == null) {
      throw Exception('Backend did not return a bill url.');
    }
    return url.toString();
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

  // Whether Stripe's CardField currently holds a complete, valid card.
  bool _cardComplete = false;

  bool _submitting = false;

  void selectPaymentMethod(PaymentMethod method) {
    setState(() => _selectedPaymentMethod = method);
  }

  bool get _canSubmit {
    if (_submitting) return false;
    if (widget.totalOutstanding <= 0) return false;
    if (_selectedPaymentMethod == null) return false;
    // FPX → bank is chosen later on the Billplz page, so selecting it is enough.
    if (_selectedPaymentMethod == PaymentMethod.fpx) return true;
    return _cardComplete;
  }

  Future<void> processPayment() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);

    try {
      // ---- FPX → hand off to Billplz hosted page ----
      // The Billplz webhook records the payment server-side, so we DON'T record
      // here; we navigate to a screen that watches Firestore for the update.
      if (_selectedPaymentMethod == PaymentMethod.fpx) {
        await _payWithFpx();
        return;
      }

      // ---- Card → charge through Stripe, then record in Firestore ----
      await _chargeCardWithStripe();

      final result = await PaymentController.processPayment(
        studentId: widget.studentId,
        semesterId: widget.semesterId,
        amount: widget.totalOutstanding,
        paymentMethod: 'Credit Card',
      );

      if (!mounted) return;
      setState(() => _submitting = false);
      displayPaymentResult(result);
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      displayPaymentResult(PaymentResult(
        success: false,
        message: e.error.localizedMessage ?? 'Card payment was declined.',
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      displayPaymentResult(PaymentResult(success: false, message: '$e'));
    }
  }

  /// Creates a PaymentIntent on the backend, then confirms it with the card
  /// entered in the Stripe CardField. Throws on failure (caught by caller).
  Future<void> _chargeCardWithStripe() async {
    final clientSecret = await StripeBackend.createPaymentIntent(
      amount: widget.totalOutstanding,
      studentId: widget.studentId,
      semesterId: widget.semesterId,
    );

    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: const PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(),
      ),
    );
  }

  /// Creates a Billplz bill, opens its hosted FPX page in the browser, then
  /// hands off to a screen that waits for the webhook to mark the fee paid.
  Future<void> _payWithFpx() async {
    final billUrl = await BillplzBackend.createBill(
      studentId: widget.studentId,
      semesterId: widget.semesterId,
    );

    final opened = await launchUrl(
      Uri.parse(billUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw Exception('Could not open the FPX payment page.');
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => FpxPendingPage(
        studentId: widget.studentId,
        semesterId: widget.semesterId,
        totalOutstanding: widget.totalOutstanding,
      ),
    ));
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
          const Padding(
            padding: EdgeInsets.fromLTRB(40, 0, 0, 8),
            child: Text(
              "You'll choose your bank on the secure Billplz page after you "
              'tap Confirm payment.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
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
                // Stripe's secure card input — raw PAN/CVC never touch our app.
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CardField(
                    onCardChanged: (card) {
                      setState(() => _cardComplete = card?.complete ?? false);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Test card: 4242 4242 4242 4242 · any future expiry · any CVC',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// =============================================================
// FpxPendingPage — waits (in realtime) for the Billplz webhook to mark the
// Fee paid, then shows success. No polling: it listens to the Fee document.
// =============================================================
class FpxPendingPage extends StatelessWidget {
  final String studentId;
  final String semesterId;
  final double totalOutstanding;

  const FpxPendingPage({
    super.key,
    required this.studentId,
    required this.semesterId,
    required this.totalOutstanding,
  });

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('Fee')
        .where('student_id', isEqualTo: studentId)
        .where('semester_id', isEqualTo: semesterId)
        .limit(1)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SamsHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snap) {
                  final paid = snap.hasData &&
                      snap.data!.docs.isNotEmpty &&
                      (snap.data!.docs.first.data()['payment_status'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          'paid';
                  return paid ? _paidView(context) : _waitingView(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waitingView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Waiting for your FPX payment…',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete the payment in the page that opened. This screen updates '
            'automatically once Billplz confirms it.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 28),
          MoonOutlinedButton(
            buttonSize: MoonButtonSize.lg,
            isFullWidth: true,
            onTap: () => Navigator.of(context).pop(),
            label: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _paidView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF5EA),
            ),
            child: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Payment Successful',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Your FPX payment for $semesterId has been received.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 28),
          MoonOutlinedButton(
            buttonSize: MoonButtonSize.lg,
            isFullWidth: true,
            onTap: () => Navigator.of(context)
                .pushReplacement(MaterialPageRoute(
              builder: (_) => TransactionPage(studentId: studentId),
            )),
            label: const Text('View transactions',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          MoonOutlinedButton(
            buttonSize: MoonButtonSize.lg,
            isFullWidth: true,
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            label: const Text('Done',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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