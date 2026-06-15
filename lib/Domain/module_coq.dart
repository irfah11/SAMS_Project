import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleCoQ {
  final String coqId;
  final String activityName;
  final int bookingQuota;
  final String location;
  final String lecturerName;

  final Timestamp? date;
  final Timestamp? time;
  final String day;

  final int booked;
  final String status;

  ModuleCoQ({
    required this.coqId,
    required this.activityName,
    required this.bookingQuota,
    required this.location,
    required this.lecturerName,
    this.date,
    this.time,
    this.day = '',
    this.booked = 0,
    this.status = 'Available',
  });

  factory ModuleCoQ.fromFirebase(Map<String, dynamic> json) {
    return ModuleCoQ(
      coqId: json['coq_id'] ?? '',
      activityName: json['activity_name'] ?? '',
      bookingQuota: json['booking_quota'] is int
          ? json['booking_quota']
          : int.tryParse((json['booking_quota'] ?? '0').toString()) ?? 0,
      location: json['location'] ?? '',
      lecturerName: json['lecturer_name'] ?? '',
      date: json['date'] is Timestamp ? json['date'] : null,
      time: json['time'] is Timestamp ? json['time'] : null,
      day: json['day'] ?? '',
      booked: json['booked'] is int
          ? json['booked']
          : int.tryParse((json['booked'] ?? '0').toString()) ?? 0,
      status: json['status'] ?? 'Available',
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'coq_id': coqId,
      'activity_name': activityName,
      'booking_quota': bookingQuota,
      'location': location,
      'lecturer_name': lecturerName,
      'date': date,
      'time': time,
      'day': day,
      'booked': booked,
      'status': status,
    };
  }
}
