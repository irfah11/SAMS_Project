import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:http/http.dart' as http;
import 'package:sams/Domain/fee.dart';
import 'package:sams/Domain/transaction.dart';
import 'package:sams/config/billplz_config.dart';
import 'package:sams/config/stripe_config.dart';

// =============================================================
// CONTROLLER — FeeController
// Single entry point for all Fee-module data access:
//   • fetching a student's current fee record       (FeePage)
//   • fetching + grouping their transactions         (TransactionPage)
//   • recording a payment                            (PaymentPage)
//   • building a receipt (Student + Fee join)        (TransactionDetailsPage)
// UI widgets stay in the screen files; only logic lives here.
// =============================================================
class FeeController {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------
  // FEE — current fee record for a student
  // ---------------------------------------------------------------
  static Future<Fee> fetchCurrentFees(String studentId) async {
    final snap = await _db
        .collection('Fee')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('No fee record found for $studentId');
    }

    return Fee.fromFirestore(snap.docs.first);
  }

  // ---------------------------------------------------------------
  // TRANSACTIONS — list + grouping
  // ---------------------------------------------------------------
  static Future<List<Transaction>> fetchTransactions(String studentId) async {
    final snapshot = await _db
        .collection('transactions')
        .where('student_id', isEqualTo: studentId)
        .where('payment_success_stat', isEqualTo: 'success')
        .orderBy('transaction_date', descending: true)
        .get();

    return snapshot.docs.map(Transaction.fromFirestore).toList();
  }

  /// Group transactions by academic year, preserving recency order.
  /// Returns a list of (year, transactions) pairs.
  static List<MapEntry<String, List<Transaction>>> groupByYear(
    List<Transaction> txs,
  ) {
    final map = <String, List<Transaction>>{};
    for (final t in txs) {
      map.putIfAbsent(t.academicYear, () => []).add(t);
    }
    return map.entries.toList();
  }

  // ---------------------------------------------------------------
  // PAYMENT — record a successful payment + mark the fee paid
  // ---------------------------------------------------------------
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

  // ---------------------------------------------------------------
  // RECEIPT — joins Transaction + Student.full_name + Fee breakdown
  // ---------------------------------------------------------------
  static Future<ReceiptData> fetchReceiptData(Transaction tx) async {
    // ---- Student (3.3.2) lookup by student_id ----
    String studentName = '-';
    try {
      final studentQuery = await _db
          .collection('student')
          .where('student_id', isEqualTo: tx.studentId)
          .limit(1)
          .get();
      if (studentQuery.docs.isNotEmpty) {
        final data = studentQuery.docs.first.data();
        studentName = (data['full_name'] ?? '-').toString();
      }
    } catch (_) {
      // ignore — fall back to "-"
    }

    // ---- Fee breakdown (3.3.7) lookup by student_id + semester_id ----
    double tuition = 0, medical = 0, welfare = 0, insurance = 0,
        activity = 0, hostel = 0;
    try {
      final feeQuery = await _db
          .collection('Fee')
          .where('student_id', isEqualTo: tx.studentId)
          .where('semester_id', isEqualTo: tx.semesterId)
          .limit(1)
          .get();
      if (feeQuery.docs.isNotEmpty) {
        final data = feeQuery.docs.first.data();
        tuition   = _asDouble(data['tuition_fee']);
        medical   = _asDouble(data['medical_fee']);
        welfare   = _asDouble(data['welfare_fee']);
        insurance = _asDouble(data['insurance_fee']);
        activity  = _asDouble(data['activity_fee']);
        hostel    = _asDouble(data['hostel_fee']);
      }
    } catch (_) {
      // ignore — leave zeros
    }

    return ReceiptData(
      studentName: studentName,
      studentId: tx.studentId,
      semesterId: tx.semesterId,
      transactionId: tx.transactionId,
      date: tx.transactionDate,
      paymentMethod: tx.paymentMethod,
      tuitionFee: tuition,
      medicalFee: medical,
      welfareFee: welfare,
      insuranceFee: insurance,
      activityFee: activity,
      hostelFee: hostel,
      totalPaid: tx.amountPaid,
    );
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

// =============================================================
// PaymentResult — outcome of a payment attempt
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
// ReceiptData — snapshot needed to render a receipt
// (joins Transaction + Student + Fee)
// =============================================================
class ReceiptData {
  final String studentName;
  final String studentId;
  final String semesterId;
  final String transactionId;
  final DateTime date;
  final String paymentMethod;

  final double tuitionFee;
  final double medicalFee;
  final double welfareFee;
  final double insuranceFee;
  final double activityFee;
  final double hostelFee;
  final double totalPaid;

  const ReceiptData({
    required this.studentName,
    required this.studentId,
    required this.semesterId,
    required this.transactionId,
    required this.date,
    required this.paymentMethod,
    required this.tuitionFee,
    required this.medicalFee,
    required this.welfareFee,
    required this.insuranceFee,
    required this.activityFee,
    required this.hostelFee,
    required this.totalPaid,
  });
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
