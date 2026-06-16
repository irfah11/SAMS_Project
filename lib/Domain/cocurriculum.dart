class Curriculum {
  final String? id;
  final String fileName;
  final String filePath;
  final String? fileUrl;
  final DateTime uploadedAt;

  Curriculum({
    this.id,
    required this.fileName,
    required this.filePath,
    this.fileUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory Curriculum.fromMap(Map<String, dynamic> map) {
    return Curriculum(
      id: map['id'],
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      fileUrl: map['fileUrl'],
      uploadedAt: DateTime.parse(map['uploadedAt']),
    );
  }
}
