class Complaint {
  final String id;
  final String studentId;
  final String title;
  final String? description;
  final String status;
  final String? photoUrl;
  final String? videoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String institutionId;

  Complaint({
    required this.id,
    required this.studentId,
    required this.title,
    this.description,
    required this.status,
    this.photoUrl,
    this.videoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.institutionId,
  });

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      status: map['status'] as String? ?? 'pending',
      photoUrl: map['photo_url'] as String?,
      videoUrl: map['video_url'] as String?,
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: DateTime.parse(map['updated_at'].toString()),
      institutionId: map['institution_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'title': title,
      'description': description,
      'status': status,
      'photo_url': photoUrl,
      'video_url': videoUrl,
      'institution_id': institutionId,
    };
  }
}