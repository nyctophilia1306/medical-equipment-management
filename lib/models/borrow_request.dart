// BorrowRequest model
// This file defines the detailed BorrowRequest used across the app.
class BorrowRequest {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String? equipmentSerialNumber; // Serial number for QR scanning
  final String userId;
  final String userName;
  final String requestedBy; // Manager who created the request
  final String requestedByName;
  final int quantity;
  final DateTime borrowDate;
  final DateTime expectedReturnDate;
  final DateTime? actualReturnDate;
  final String
  status; // 'pending', 'approved', 'rejected', 'returned', 'overdue'
  final String purpose;
  final String? notes;
  final String? rejectionReason;
  final String? returnNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? requestSerial; // DDMMYYYY format for grouping requests
  final bool isEquipmentReturned; // Track individual equipment return status

  const BorrowRequest({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    this.equipmentSerialNumber,
    required this.userId,
    required this.userName,
    required this.requestedBy,
    required this.requestedByName,
    required this.quantity,
    required this.borrowDate,
    required this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    required this.purpose,
    this.notes,
    this.rejectionReason,
    this.returnNotes,
    required this.createdAt,
    this.updatedAt,
    this.requestSerial,
    this.isEquipmentReturned = false,
  });

  factory BorrowRequest.fromJson(Map<String, dynamic> json) {
    return BorrowRequest(
      id: json['id'] as String,
      equipmentId: json['equipment_id'] as String,
      equipmentName: json['equipment_name'] as String,
      equipmentSerialNumber: json['equipment_serial_number'] as String?,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      requestedBy: json['requested_by'] as String,
      requestedByName: json['requested_by_name'] as String,
      quantity: json['quantity'] as int,
      borrowDate: DateTime.parse(json['borrow_date'] as String),
      expectedReturnDate: DateTime.parse(
        json['expected_return_date'] as String,
      ),
      actualReturnDate: json['actual_return_date'] != null
          ? DateTime.parse(json['actual_return_date'] as String)
          : null,
      status: json['status'] as String,
      purpose: json['purpose'] as String,
      notes: json['notes'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      returnNotes: json['return_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      requestSerial: json['request_serial'] as String?,
      isEquipmentReturned: json['is_equipment_returned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'equipment_serial_number': equipmentSerialNumber,
      'user_id': userId,
      'user_name': userName,
      'requested_by': requestedBy,
      'requested_by_name': requestedByName,
      'quantity': quantity,
      'borrow_date': borrowDate.toIso8601String().split('T')[0],
      'expected_return_date': expectedReturnDate.toIso8601String().split(
        'T',
      )[0],
      'actual_return_date': actualReturnDate?.toIso8601String().split('T')[0],
      'status': status,
      'purpose': purpose,
      'notes': notes,
      'rejection_reason': rejectionReason,
      'return_notes': returnNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'request_serial': requestSerial,
      'is_equipment_returned': isEquipmentReturned,
    };
  }

  BorrowRequest copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? equipmentSerialNumber,
    String? userId,
    String? userName,
    String? requestedBy,
    String? requestedByName,
    int? quantity,
    DateTime? borrowDate,
    DateTime? expectedReturnDate,
    DateTime? actualReturnDate,
    String? status,
    String? purpose,
    String? notes,
    String? rejectionReason,
    String? returnNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? requestSerial,
    bool? isEquipmentReturned,
  }) {
    return BorrowRequest(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentSerialNumber:
          equipmentSerialNumber ?? this.equipmentSerialNumber,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      quantity: quantity ?? this.quantity,
      borrowDate: borrowDate ?? this.borrowDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      status: status ?? this.status,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      returnNotes: returnNotes ?? this.returnNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requestSerial: requestSerial ?? this.requestSerial,
      isEquipmentReturned: isEquipmentReturned ?? this.isEquipmentReturned,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isReturned => status == 'returned';
  bool get isOverdue => status == 'overdue';

  bool get isActive => isApproved && !isReturned;

  bool get isOverdueByDate {
    if (isReturned) return false;
    return DateTime.now().isAfter(expectedReturnDate);
  }

  int get daysBorrowed {
    final endDate = actualReturnDate ?? DateTime.now();
    return endDate.difference(borrowDate).inDays;
  }

  int get daysOverdue {
    if (!isOverdueByDate) return 0;
    return DateTime.now().difference(expectedReturnDate).inDays;
  }

  Duration get borrowDuration {
    return expectedReturnDate.difference(borrowDate);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BorrowRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BorrowRequest(id: $id, equipmentName: $equipmentName, userName: $userName, status: $status)';
  }
}
