import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectContent {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final String type; // Note, Assignment, Quiz
  final String? fileUrl;
  final String? link;
  final String? duration;
  final DateTime createdAt;

  SubjectContent({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.type,
    this.fileUrl,
    this.link,
    this.duration,
    required this.createdAt,
  });

  factory SubjectContent.fromMap(Map<String, dynamic> map, String documentId) {
    return SubjectContent(
      id: documentId,
      subjectId: map['subjectId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      fileUrl: map['fileUrl'],
      link: map['link'],
      duration: map['duration'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'type': type,
      'fileUrl': fileUrl,
      'link': link,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
