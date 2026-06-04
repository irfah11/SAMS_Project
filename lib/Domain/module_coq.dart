class ModuleCoQ {
  final String coqId; // Kita guna String untuk ID dokumen unik
  final String activityName;
  final int bookingQuota;
  final String location;
  final String lecturerName; // Cara A: Simpan terus nama pensyarah penasihat

  ModuleCoQ({
    required this.coqId,
    required this.activityName,
    required this.bookingQuota,
    required this.location,
    required this.lecturerName,
  });

  factory ModuleCoQ.fromFirebase(Map<String, dynamic> json) {
    return ModuleCoQ(
      coqId: json['coq_id'] as String,
      activityName: json['activity_name'] as String,
      bookingQuota: json['booking_quota'] as int,
      location: json['location'] as String,
      lecturerName: json['lecturer_name'] as String,
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'coq_id': coqId,
      'activity_name': activityName,
      'booking_quota': bookingQuota,
      'location': location,
      'lecturer_name': lecturerName,
    };
  }
}
