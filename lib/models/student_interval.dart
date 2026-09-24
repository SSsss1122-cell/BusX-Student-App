class StudentInterval {
  final String id;
  final String studentId;
  final int intervalNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double totalFees;
  final double paidAmount;
  final double dueAmount;
  final DateTime? lastPaymentDate;
  final String? paymentMode;
  final String? utr;
  final String status;
  final String institutionId;

  StudentInterval({
    required this.id,
    required this.studentId,
    required this.intervalNumber,
    required this.startDate,
    required this.endDate,
    required this.totalFees,
    required this.paidAmount,
    required this.dueAmount,
    this.lastPaymentDate,
    this.paymentMode,
    this.utr,
    required this.status,
    required this.institutionId,
  });

  factory StudentInterval.fromMap(Map<String, dynamic> map) {
    return StudentInterval(
      id: map['id'] as String,
      studentId: map['student_id'] as String,
      intervalNumber: map['interval_number'] as int,
      startDate: DateTime.parse(map['start_date'].toString()),
      endDate: DateTime.parse(map['end_date'].toString()),
      totalFees: (map['total_fees'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      dueAmount: (map['due_amount'] as num?)?.toDouble() ?? 0.0,
      lastPaymentDate: map['last_payment_date'] != null
          ? DateTime.parse(map['last_payment_date'].toString())
          : null,
      paymentMode: map['payment_mode'] as String?,
      utr: map['utr'] as String?,
      status: map['status'] as String? ?? 'pending',
      institutionId: map['institution_id'] as String,
    );
  }

  bool get isPaid => status.toLowerCase() == 'paid' || dueAmount <= 0;
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isPartial => status.toLowerCase() == 'partial';
}