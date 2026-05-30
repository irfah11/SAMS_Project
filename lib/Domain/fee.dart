import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================
// MODEL — Fee (Data Dictionary 3.3.7)
// Maps to the 'Fee' collection in Firestore.
// =============================================================
class Fee {
  final String studentId;
  final String semesterId;
  final double tuitionFee;
  final double hostelFee;
  final double medicalFee;
  final double welfareFee;
  final double insuranceFee;
  final double activityFee;
  final double totalOutstanding;
  final String paymentStatus;
  final String accessStatus;
  final String dueWeek;

  const Fee({
    required this.studentId,
    required this.semesterId,
    required this.tuitionFee,
    required this.hostelFee,
    required this.medicalFee,
    required this.welfareFee,
    required this.insuranceFee,
    required this.activityFee,
    required this.totalOutstanding,
    required this.paymentStatus,
    required this.accessStatus,
    required this.dueWeek,
  });

  // Tolerant numeric parse — Firestore may store numbers as int, double or String.
  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  // Convert a Firestore JSON map into a Fee object.
  factory Fee.fromFirebase(Map<String, dynamic> json) {
    return Fee(
      studentId: (json['student_id'] ?? '').toString(),
      semesterId: (json['semester_id'] ?? '').toString(),
      tuitionFee: _toDouble(json['tuition_fee']),
      hostelFee: _toDouble(json['hostel_fee']),
      medicalFee: _toDouble(json['medical_fee']),
      welfareFee: _toDouble(json['welfare_fee']),
      insuranceFee: _toDouble(json['insurance_fee']),
      activityFee: _toDouble(json['activity_fee']),
      totalOutstanding: _toDouble(json['total_outstanding']),
      paymentStatus: (json['payment_status'] ?? 'Unpaid').toString(),
      accessStatus: (json['access_status'] ?? 'Unblock').toString(),
      dueWeek: (json['due_week'] ?? '').toString(),
    );
  }

  // Convenience: build straight from a Firestore document snapshot.
  factory Fee.fromFirestore(DocumentSnapshot doc) {
    return Fee.fromFirebase(doc.data() as Map<String, dynamic>);
  }

  // Convert a Fee object back to the Firestore JSON format.
  Map<String, dynamic> toFirebase() {
    return {
      'student_id': studentId,
      'semester_id': semesterId,
      'tuition_fee': tuitionFee,
      'hostel_fee': hostelFee,
      'medical_fee': medicalFee,
      'welfare_fee': welfareFee,
      'insurance_fee': insuranceFee,
      'activity_fee': activityFee,
      'total_outstanding': totalOutstanding,
      'payment_status': paymentStatus,
      'access_status': accessStatus,
      'due_week': dueWeek,
    };
  }
}
