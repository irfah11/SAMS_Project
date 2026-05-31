import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================
// MODEL — Transaction (Data Dictionary 3.3.8)
// Maps to the 'transactions' collection in Firestore.
// =============================================================
class Transaction {
  final String transactionId;
  final String studentId;
  final String semesterId;
  final double amountPaid;
  final String paymentMethod;
  final DateTime transactionDate;
  final String paymentSuccessStat;

  const Transaction({
    required this.transactionId,
    required this.studentId,
    required this.semesterId,
    required this.amountPaid,
    required this.paymentMethod,
    required this.transactionDate,
    required this.paymentSuccessStat,
  });

  // Tolerant numeric parse — Firestore may store numbers as int, double or String.
  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime _toDate(dynamic raw) {
    // Date may be stored as a Firestore Timestamp or an ISO string.
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  factory Transaction.fromFirebase(Map<String, dynamic> json, {String? docId}) {
    return Transaction(
      transactionId: (json['transaction_id'] ?? docId ?? '').toString(),
      studentId: (json['student_id'] ?? '').toString(),
      semesterId: (json['semester_id'] ?? '').toString(),
      amountPaid: _toDouble(json['amount_paid']),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      transactionDate: _toDate(json['transaction_date']),
      paymentSuccessStat: (json['payment_success_stat'] ?? '').toString(),
    );
  }

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    return Transaction.fromFirebase(
      doc.data() as Map<String, dynamic>,
      docId: doc.id,
    );
  }

  // Convert to the Firestore JSON format. transaction_date is written as a
  // Timestamp so it sorts/queries correctly server-side.
  Map<String, dynamic> toFirebase() {
    return {
      'transaction_id': transactionId,
      'student_id': studentId,
      'semester_id': semesterId,
      'amount_paid': amountPaid,
      'payment_method': paymentMethod,
      'transaction_date': Timestamp.fromDate(transactionDate),
      'payment_success_stat': paymentSuccessStat,
    };
  }

  /// Extract the academic year part from semester_id.
  /// "Semester 2 2025/2026" → "2025/2026"
  String get academicYear {
    final match = RegExp(r'(\d{4}/\d{4})').firstMatch(semesterId);
    return match?.group(1) ?? semesterId;
  }
}
