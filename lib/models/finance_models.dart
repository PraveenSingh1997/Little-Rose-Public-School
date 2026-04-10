enum FeeType { tuition, admission, exam, library, transport, hostel, other }

extension FeeTypeExt on FeeType {
  String get value => ['tuition', 'admission', 'exam', 'library', 'transport', 'hostel', 'other'][index];
  String get label => ['Tuition', 'Admission', 'Exam', 'Library', 'Transport', 'Hostel', 'Other'][index];
  static FeeType fromString(String s) =>
      FeeType.values.firstWhere((e) => e.value == s, orElse: () => FeeType.other);
}

enum PaymentMethod { cash, card, online, bankTransfer, cheque }

extension PaymentMethodExt on PaymentMethod {
  String get value => ['cash', 'card', 'online', 'bank_transfer', 'cheque'][index];
  String get label => ['Cash', 'Card', 'Online', 'Bank Transfer', 'Cheque'][index];
  static PaymentMethod fromString(String s) =>
      PaymentMethod.values.firstWhere((e) => e.value == s, orElse: () => PaymentMethod.cash);
}

class FeeStructure {
  final String id;
  final String name;
  final String? classId;
  final double amount;
  final FeeType feeType;
  final int dueDay;
  final String academicYear;
  final String frequency;
  final double lateFinePerDay;
  final DateTime createdAt;

  const FeeStructure({
    required this.id,
    required this.name,
    this.classId,
    required this.amount,
    required this.feeType,
    this.dueDay = 10,
    required this.academicYear,
    this.frequency = 'monthly',
    this.lateFinePerDay = 0,
    required this.createdAt,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> j) => FeeStructure(
        id: j['id'],
        name: j['name'],
        classId: j['class_id'],
        amount: (j['amount'] as num).toDouble(),
        feeType: FeeTypeExt.fromString(j['fee_type']),
        dueDay: j['due_day'] ?? 10,
        academicYear: j['academic_year'] ?? '2024-25',
        frequency: j['frequency'] ?? 'monthly',
        lateFinePerDay: j['late_fine_per_day'] != null
            ? (j['late_fine_per_day'] as num).toDouble()
            : 0,
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'class_id': classId,
        'amount': amount,
        'fee_type': feeType.value,
        'due_day': dueDay,
        'academic_year': academicYear,
        'frequency': frequency,
        'late_fine_per_day': lateFinePerDay,
      };
}

class FeePayment {
  final String id;
  final String studentId;
  final String? feeStructureId;
  final double amountPaid;
  final double discount;
  final double fine;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final String? receiptNumber;
  final String? monthYear;
  final String status;
  final String? collectedBy;
  final String? notes;
  final DateTime createdAt;

  const FeePayment({
    required this.id,
    required this.studentId,
    this.feeStructureId,
    required this.amountPaid,
    this.discount = 0,
    this.fine = 0,
    required this.paymentDate,
    this.paymentMethod = PaymentMethod.cash,
    this.transactionId,
    this.receiptNumber,
    this.monthYear,
    this.status = 'paid',
    this.collectedBy,
    this.notes,
    required this.createdAt,
  });

  double get netAmount => amountPaid - discount + fine;

  factory FeePayment.fromJson(Map<String, dynamic> j) => FeePayment(
        id: j['id'],
        studentId: j['student_id'],
        feeStructureId: j['fee_structure_id'],
        amountPaid: (j['amount_paid'] as num).toDouble(),
        discount: j['discount'] != null ? (j['discount'] as num).toDouble() : 0,
        fine: j['fine'] != null ? (j['fine'] as num).toDouble() : 0,
        paymentDate: DateTime.parse(j['payment_date']),
        paymentMethod: PaymentMethodExt.fromString(j['payment_method'] ?? 'cash'),
        transactionId: j['transaction_id'],
        receiptNumber: j['receipt_number'],
        monthYear: j['month_year'],
        status: j['status'] ?? 'paid',
        collectedBy: j['collected_by'],
        notes: j['notes'],
        createdAt: DateTime.parse(j['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'fee_structure_id': feeStructureId,
        'amount_paid': amountPaid,
        'discount': discount,
        'fine': fine,
        'payment_date': paymentDate.toIso8601String().split('T')[0],
        'payment_method': paymentMethod.value,
        'transaction_id': transactionId,
        'receipt_number': receiptNumber,
        'month_year': monthYear,
        'status': status,
        'collected_by': collectedBy,
        'notes': notes,
      };
}
