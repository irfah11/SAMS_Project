
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
    // Two equality filters only — no orderBy, so Firestore serves this from its
    // automatic indexes (no composite index needed). A single student's history
    // is small, so we sort by date client-side below; this stays fast at any
    // system scale because the result set is bounded to one student.
    final snapshot = await _db
        .collection('transactions')
        .where('student_id', isEqualTo: studentId)
        .where('payment_success_stat', isEqualTo: 'success')
        .get();

    final txs = snapshot.docs.map(Transaction.fromFirestore).toList();
    txs.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return txs;
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

// =============================================================
// TREASURY — dashboard models + controller
// Moved here from screen/Fee/Treasury/TreasuryDashboardPage.dart so all
// Fee-module data access lives in this file.
// =============================================================
class DashboardStats {
  final int totalStudents;
  final int paidStudents;
  final int unpaidStudents;
  final int overdueStudents;

  const DashboardStats({
    required this.totalStudents,
    required this.paidStudents,
    required this.unpaidStudents,
    required this.overdueStudents,
  });
}

class StudentRow {
  final String studentId;
  final String fullName;
  final String paymentStatus;

  const StudentRow({
    required this.studentId,
    required this.fullName,
    required this.paymentStatus,
  });
}

// Per SDD-REQ-308: getDashboardStats()
class TreasuryController {
  /// Fetches stats + student list in one pass over the fees collection.
  /// For very large datasets (>10K students), prefer aggregation queries.
  static Future<({DashboardStats stats, List<StudentRow> students})>
      getDashboardStats() async {
    final db = FirebaseFirestore.instance;

    // Pull all fee records (each represents one student-semester).
    final feeSnap = await db.collection('Fee').get();

    int paid = 0, unpaid = 0, overdue = 0;
    final rows = <StudentRow>[];

    for (final doc in feeSnap.docs) {
      final data = doc.data();
      final status = (data['payment_status'] ?? 'Unpaid').toString();

      switch (status.toLowerCase()) {
        case 'paid':
          paid++;
          break;
        case 'overdue':
          overdue++;
          unpaid++; // overdue counts as unpaid for the summary tile
          break;
        default:
          unpaid++;
      }

      rows.add(StudentRow(
        studentId: (data['student_id'] ?? '').toString(),
        fullName: (data['student_name'] ?? '').toString(),
        paymentStatus: status,
      ));
    }

    // Backfill missing names from the students collection if needed.
    final missing = rows.where((r) => r.fullName.isEmpty).toList();
    if (missing.isNotEmpty) {
      final studentSnap = await db.collection('student').get();
      final nameById = {
        for (final d in studentSnap.docs)
          (d.data()['student_id'] ?? d.id).toString():
              (d.data()['full_name'] ?? '').toString(),
      };
      for (int i = 0; i < rows.length; i++) {
        if (rows[i].fullName.isEmpty) {
          rows[i] = StudentRow(
            studentId: rows[i].studentId,
            fullName: nameById[rows[i].studentId] ?? '-',
            paymentStatus: rows[i].paymentStatus,
          );
        }
      }
    }

    return (
      stats: DashboardStats(
        totalStudents: rows.length,
        paidStudents: paid,
        unpaidStudents: unpaid,
        overdueStudents: overdue,
      ),
      students: rows,
    );
  }

  // ---------------------------------------------------------------
  // DEV SEEDER — create a Fee doc for every student that lacks one.
  // Copies the standard fee template (same values as CB23076). Safe to
  // run repeatedly: students that already have a Fee are skipped.
  // Returns the number of Fee docs created.
  // TODO(dev): remove this and its dashboard button once fees are seeded.
  // ---------------------------------------------------------------
  static const String _seedSemesterId = 'SEMESTER 2 2025/2026';
  static final DateTime _seedDueDate = DateTime(2026, 5, 9); // Week 5 due date

  static Fee _feeTemplateFor(String studentId) => Fee(
        studentId: studentId,
        semesterId: _seedSemesterId,
        tuitionFee: 660,
        hostelFee: 650,
        medicalFee: 50,
        welfareFee: 30,
        insuranceFee: 20,
        activityFee: 100,
        totalOutstanding: 1510,
        paymentStatus: 'Unpaid',
        accessStatus: 'Unblocked',
        dueWeek: '5',
        dueDate: _seedDueDate,
      );

  static Future<int> seedMissingFees() async {
    final db = FirebaseFirestore.instance;

    // student_ids that already have a Fee doc
    final feeSnap = await db.collection('Fee').get();
    final haveFee = feeSnap.docs
        .map((d) => (d.data()['student_id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet();

    // Backfill: give existing Fee docs a due_date if they don't have one.
    for (final doc in feeSnap.docs) {
      if (doc.data()['due_date'] == null) {
        await doc.reference
            .update({'due_date': Timestamp.fromDate(_seedDueDate)});
      }
    }

    final studentSnap = await db.collection('student').get();

    int created = 0;
    for (final doc in studentSnap.docs) {
      final data = doc.data();
      final studentId = (data['student_id'] ?? doc.id).toString();
      if (studentId.isEmpty || haveFee.contains(studentId)) continue;

      // Deterministic doc id; '/' isn't allowed in a Firestore id so the
      // semester is sanitised. Queries use the student_id field, not this id.
      final docId = '${studentId}_SEM2_2025_2026';
      await db
          .collection('Fee')
          .doc(docId)
          .set(_feeTemplateFor(studentId).toFirebase());
      created++;
    }
    return created;
  }
}

// =============================================================
// TREASURY — student financial record model + controller
// Moved here from screen/Fee/Treasury/StudentRecordPage.dart.
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

// Per SDD-REQ-308: getStudentFinancialRecord(), toggleAccessStatus(),
//   sendOverdueNotification(), generateReport()
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
// TREASURY — overdue students model + controller
// Moved here from screen/Fee/Treasury/OverdueStudent_Page.dart.
// =============================================================
class OverdueStudent {
  final String studentId;
  final String fullName;
  final String accessStatus;
  final String paymentStatus;

  const OverdueStudent({
    required this.studentId,
    required this.fullName,
    required this.accessStatus,
    required this.paymentStatus,
  });
}

// Per SDD-REQ-308: getOverdueList()
class OverdueController {
  static Future<List<OverdueStudent>> getOverdueList() async {
    final db = FirebaseFirestore.instance;
    final feeSnap = await db
        .collection('Fee')
        .where('payment_status', isEqualTo: 'Overdue')
        .get();

    final ids = feeSnap.docs
        .map((d) => (d.data()['student_id'] ?? '').toString())
        .toList();

    // Fetch student names in one batched read.
    final nameById = <String, String>{};
    if (ids.isNotEmpty) {
      final studentSnap = await db.collection('student').get();
      for (final d in studentSnap.docs) {
        final sid = (d.data()['student_id'] ?? d.id).toString();
        nameById[sid] = (d.data()['full_name'] ?? '-').toString();
      }
    }

    return feeSnap.docs.map((d) {
      final data = d.data();
      final sid = (data['student_id'] ?? '').toString();
      return OverdueStudent(
        studentId: sid,
        fullName: nameById[sid] ?? (data['student_name'] ?? '-').toString(),
        accessStatus: (data['access_status'] ?? 'Unblocked').toString(),
        paymentStatus: (data['payment_status'] ?? 'Overdue').toString(),
      );
    }).toList();
  }
}
