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
    this.usn,
    this.branch,
    this.phone,
    this.email,
    this.role,
    required this.institutionId,
    this.currentIntervalId,
    this.routes,
    this.semester,
  });

  factory Student.fromMap(
    Map<String, dynamic> map,
  ) {
    return Student(
      id: map['id']?.toString() ?? '',
      fullName:
          map['full_name']?.toString() ?? '',
      usn: map['usn']?.toString(),
      branch: map['branch']?.toString(),
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      role: map['role']?.toString(),
      institutionId:
          map['institution_id']?.toString() ?? '',
      currentIntervalId:
          map['current_interval_id']?.toString(),
      routes: map['routes']?.toString(),
      semester:
          map['semester']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'usn': usn,
      'branch': branch,
      'phone': phone,
      'email': email,
      'role': role,
      'institution_id': institutionId,
      'current_interval_id':
          currentIntervalId,
      'routes': routes,
      'semester': semester,
    };
  }
}