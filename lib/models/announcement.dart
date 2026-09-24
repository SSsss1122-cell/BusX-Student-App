class Announcement {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String institutionId;
  final int? createdBy;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.institutionId,
    this.createdBy,
  });

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as int,
      title: map['title'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['created_at'].toString()),
      institutionId: map['institution_id'] as String,
      createdBy: map['created_by'] as int?,
    );
  }
}