import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:sams/Domain/fee.dart';
import 'package:sams/Domain/transaction.dart';

// =============================================================
// CONTROLLER — FeeController  [SDD-REQ-308]
// Single control class for ALL Fee-module business logic:
//   student fees, payments, transactions, receipts, and the Treasury
//   administrative functions (dashboard stats, financial records, reports,
//   overdue management, access blocking).
// UI widgets stay in the screen files; only logic lives here.
// =============================================================
class FeeController {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------
  // getFeeRecord() — itemized fee record for a student (FeePage / PaymentPage)
  // ---------------------------------------------------------------
  static Future<Fee> getFeeRecord(String studentId) async {
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
  // processPayment() — record a payment, then mark the fee paid
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

      // 2. Update the fee record (payment_status → Paid).
      await updatePaymentStatus(studentId: studentId, semesterId: semesterId);

      return PaymentResult(
        success: true,
        message: 'Payment successful',
        transactionId: transactionId,
      );
    } catch (e) {
      return PaymentResult(success: false, message: 'Payment failed: $e');
    }
  }

  // ---------------------------------------------------------------
  // updatePaymentStatus() — mark the student's fee Paid + restore access
  // ---------------------------------------------------------------
  static Future<void> updatePaymentStatus({
    required String studentId,
    required String semesterId,
  }) async {
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
  }

  // ---------------------------------------------------------------
  // getTransactionHistory() — a student's successful transactions
  // ---------------------------------------------------------------
  static Future<List<Transaction>> getTransactionHistory(
      String studentId) async {
    // Two equality filters only — no orderBy, so Firestore serves this from its
    // automatic indexes (no composite index needed). One student's history is
    // small, so we sort by date client-side below.
    final snapshot = await _db
        .collection('transactions')
        .where('student_id', isEqualTo: studentId)
        .where('payment_success_stat', isEqualTo: 'success')
        .get();

    final txs = snapshot.docs.map(Transaction.fromFirestore).toList();
    txs.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return txs;
  }

  // ---------------------------------------------------------------
  // getTransactionDetails() — full receipt (Transaction + Student + Fee)
  // ---------------------------------------------------------------
  static Future<ReceiptData> getTransactionDetails(Transaction tx) async {
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

  // ---------------------------------------------------------------
  // getDashboardStats() — Treasury: counts + searchable student list
  // ---------------------------------------------------------------
  static Future<({DashboardStats stats, List<StudentRow> students})>
      getDashboardStats() async {
    final feeSnap = await _db.collection('Fee').get();

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
      final studentSnap = await _db.collection('student').get();
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
  // getStudentFinancialRecord() — Treasury: one student's full financials
  // ---------------------------------------------------------------
  static Future<StudentFinancialRecord> getStudentFinancialRecord(
      String studentId) async {
    // Student profile
    String fullName = '-';
    final studentSnap = await _db
        .collection('student')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (studentSnap.docs.isNotEmpty) {
      fullName = (studentSnap.docs.first.data()['full_name'] ?? '-').toString();
    }

    // Fee record
    final feeSnap = await _db
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

  // ---------------------------------------------------------------
  // generatePDFReport() — Treasury: record a fee report for a student
  // (The actual PDF export is handled later; the UI shows a confirmation.)
  // ---------------------------------------------------------------
  static Future<void> generatePDFReport(StudentFinancialRecord r) async {
    await _db.collection('fee_reports').add({
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

  // ---------------------------------------------------------------
  // getOverdueList() — Treasury: all students with an Overdue fee
  // ---------------------------------------------------------------
  static Future<List<OverdueStudent>> getOverdueList() async {
    final feeSnap = await _db
        .collection('Fee')
        .where('payment_status', isEqualTo: 'Overdue')
        .get();

    final ids = feeSnap.docs
        .map((d) => (d.data()['student_id'] ?? '').toString())
        .toList();

    // Fetch student names in one batched read.
    final nameById = <String, String>{};
    if (ids.isNotEmpty) {
      final studentSnap = await _db.collection('student').get();
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

  // ---------------------------------------------------------------
  // toggleAccessStatus() — Treasury: flip access Blocked <-> Unblocked
  // ---------------------------------------------------------------
  static Future<String> toggleAccessStatus({
    required String studentId,
    required String currentStatus,
  }) async {
    final isUnblocked =
        currentStatus.trim().toLowerCase().startsWith('unblock');
    final newStatus = isUnblocked ? 'Blocked' : 'Unblocked';

    final feeSnap = await _db
        .collection('Fee')
        .where('student_id', isEqualTo: studentId)
        .limit(1)
        .get();
    if (feeSnap.docs.isNotEmpty) {
      await feeSnap.docs.first.reference.update({'access_status': newStatus});
    }
    return newStatus;
  }

  // ---------------------------------------------------------------
  // sendOverdueNotification() — record an automated notification event
  // ---------------------------------------------------------------
  static Future<void> sendOverdueNotification({
    required String studentId,
    required String accessStatus,
    required String paymentStatus,
  }) async {
    final message = accessStatus.toLowerCase() == 'blocked'
        ? 'Your academic access has been blocked due to overdue fees.'
        : 'Your academic access has been restored.';

    await _db.collection('notifications').add({
      'student_id': studentId,
      'access_status': accessStatus,
      'payment_status': paymentStatus,
      'message': message,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------
  // enforceAccessBlock() — auto-block every student whose fee is still
  // Unpaid/Overdue (the Week-5 deadline rule). Notifies each one.
  // ---------------------------------------------------------------
  static Future<int> enforceAccessBlock() async {
    final feeSnap = await _db.collection('Fee').get();

    int blocked = 0;
    for (final doc in feeSnap.docs) {
      final data = doc.data();
      final status = (data['payment_status'] ?? '').toString().toLowerCase();
      if (status == 'unpaid' || status == 'overdue') {
        await doc.reference.update({'access_status': 'Blocked'});
        await sendOverdueNotification(
          studentId: (data['student_id'] ?? '').toString(),
          accessStatus: 'Blocked',
          paymentStatus: (data['payment_status'] ?? '').toString(),
        );
        blocked++;
      }
    }
    return blocked;
  }

  // ===============================================================
  // Helpers not in the SDD (kept at the bottom)
  // ===============================================================

  /// Group transactions by academic year, preserving recency order.
  static List<MapEntry<String, List<Transaction>>> groupByYear(
    List<Transaction> txs,
  ) {
    final map = <String, List<Transaction>>{};
    for (final t in txs) {
      map.putIfAbsent(t.academicYear, () => []).add(t);
    }
    return map.entries.toList();
  }

  // Build a human-readable receipt number, e.g. "RP2605-43187".
  static String _generateTransactionId(DateTime now) {
    final yy = (now.year % 100).toString().padLeft(2, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final seq =
        (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'RP$yy$mm-$seq';
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

// =============================================================
// MODELS / DTOs used by the Fee module
// =============================================================

// PaymentResult — outcome of a payment attempt
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

// ReceiptData — snapshot needed to render a receipt (Transaction + Student + Fee)
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

// DashboardStats — Treasury summary counts
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

// StudentRow — one row in the Treasury student list
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

// StudentFinancialRecord — Treasury view of one student's financials
class StudentFinancialRecord {
  final String studentId;
  final String fullName;
  final String semesterId;
  final double semesterFee;
  final double amountPaid;
  final double balance;
  final String paymentStatus;
  final String accessStatus;

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

// OverdueStudent — one overdue student in the Treasury list
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
