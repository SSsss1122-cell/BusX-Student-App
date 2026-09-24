class Notice {
  final String id;
  final String title;
  final String content;
  final String? category;
  final String? priority;
  final String institutionId;
  final String? studentId;        // ← ADD THIS
  final DateTime createdAt;
  final DateTime? expiryDate;
  final bool isActive;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.priority,
    required this.institutionId,
    this.studentId,               // ← ADD THIS
    required this.createdAt,
    this.expiryDate,
    required this.isActive,
  });

  factory Notice.fromMap(Map<String, dynamic> map) {
    return Notice(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String?,
      priority: map['priority'] as String?,
      institutionId: map['institution_id'] as String,
      studentId: map['student_id'] as String?,        // ← ADD THIS
      createdAt: DateTime.parse(map['created_at'].toString()),
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'].toString())
          : null,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}