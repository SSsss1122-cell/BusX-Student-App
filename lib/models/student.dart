class Student {
  final String id;
  final String fullName;
  final String? usn;
  final String? branch;
  final String? phone;
  final String? email;
  final String? role;
  final String institutionId;
  final String? currentIntervalId;
  final String? routes;
  final String? semester;

  Student({
    required this.id,
    required this.fullName,
    required this.institutionId,
    this.usn,
    this.branch,
    this.phone,
    this.email,
    this.role,
    this.currentIntervalId,
    this.routes,
    this.semester,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      institutionId: map['institution_id'] as String,
      usn: map['usn'] as String?,
      branch: map['branch'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      role: map['role'] as String?,
      currentIntervalId: map['current_interval_id'] as String?,
      routes: map['routes'] as String?,
      semester: map['semester'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'institution_id': institutionId,
      'usn': usn,
      'branch': branch,
      'phone': phone,
      'email': email,
      'role': role,
      'current_interval_id': currentIntervalId,
      'routes': routes,
      'semester': semester,
    };
  }
}