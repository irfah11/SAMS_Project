class CourseSubject {
  final String subjectId;
  final String subjectName;
  final String section;
  final String tutorialLab;
  final int capacity;
  final DateTime time;
  final String lecturerName; // Tukar dari int ke String

  CourseSubject({
    required this.subjectId,
    required this.subjectName,
    required this.section,
    required this.tutorialLab,
    required this.capacity,
    required this.time,
    required this.lecturerName,
  });

  factory CourseSubject.fromFirebase(Map<String, dynamic> json) {
    return CourseSubject(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      section: json['section'] as String,
      tutorialLab: json['tutorial_lab'] as String,
      capacity: json['capacity'] as int,
      time: DateTime.parse(json['time'] as String),
      lecturerName: json['lecturer_name'] as String, // Pastikan nama key sama
    );
  }

  Map<String, dynamic> toFirebase() {
    return {
      'subject_id': subjectId,
      'subject_name': subjectName,
      'section': section,
      'tutorial_lab': tutorialLab,
      'capacity': capacity,
      'time': time.toIso8601String(),
      'lecturer_name': lecturerName, // Simpan sebagai String
    };
  }
}
