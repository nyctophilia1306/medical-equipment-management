class InventoryLog {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String
  action; // 'added', 'removed', 'adjusted', 'maintenance', 'returned'
  final int quantityChange;
  final int quantityBefore;
  final int quantityAfter;
  final String reason;
  final String? notes;
  final String performedBy;
  final String performedByName;
  final DateTime createdAt;

  const InventoryLog({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.action,
    required this.quantityChange,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.reason,
    this.notes,
    required this.performedBy,
    required this.performedByName,
    required this.createdAt,
  });

  factory InventoryLog.fromJson(Map<String, dynamic> json) {
    return InventoryLog(
      id: json['id'] as String,
      equipmentId: json['equipment_id'] as String,
      equipmentName: json['equipment_name'] as String,
      action: json['action'] as String,
      quantityChange: json['quantity_change'] as int,
      quantityBefore: json['quantity_before'] as int,
      quantityAfter: json['quantity_after'] as int,
      reason: json['reason'] as String,
      notes: json['notes'] as String?,
      performedBy: json['performed_by'] as String,
      performedByName: json['performed_by_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipment_id': equipmentId,
      'equipment_name': equipmentName,
      'action': action,
      'quantity_change': quantityChange,
      'quantity_before': quantityBefore,
      'quantity_after': quantityAfter,
      'reason': reason,
      'notes': notes,
      'performed_by': performedBy,
      'performed_by_name': performedByName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isIncrease => quantityChange > 0;
  bool get isDecrease => quantityChange < 0;
  bool get isNoChange => quantityChange == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InventoryLog(id: $id, equipmentName: $equipmentName, action: $action, quantityChange: $quantityChange)';
  }
}

class DashboardStats {
  final int totalEquipment;
  final int availableEquipment;
  final int borrowedEquipment;
  final int maintenanceEquipment;
  final int totalUsers;
  final int activeBorrowRequests;
  final int overdueRequests;
  final int pendingRequests;
  final int lowStockItems;
  final int outOfStockItems;

  const DashboardStats({
    required this.totalEquipment,
    required this.availableEquipment,
    required this.borrowedEquipment,
    required this.maintenanceEquipment,
    required this.totalUsers,
    required this.activeBorrowRequests,
    required this.overdueRequests,
    required this.pendingRequests,
    required this.lowStockItems,
    required this.outOfStockItems,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalEquipment: json['total_equipment'] as int,
      availableEquipment: json['available_equipment'] as int,
      borrowedEquipment: json['borrowed_equipment'] as int,
      maintenanceEquipment: json['maintenance_equipment'] as int,
      totalUsers: json['total_users'] as int,
      activeBorrowRequests: json['active_borrow_requests'] as int,
      overdueRequests: json['overdue_requests'] as int,
      pendingRequests: json['pending_requests'] as int,
      lowStockItems: json['low_stock_items'] as int,
      outOfStockItems: json['out_of_stock_items'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_equipment': totalEquipment,
      'available_equipment': availableEquipment,
      'borrowed_equipment': borrowedEquipment,
      'maintenance_equipment': maintenanceEquipment,
      'total_users': totalUsers,
      'active_borrow_requests': activeBorrowRequests,
      'overdue_requests': overdueRequests,
      'pending_requests': pendingRequests,
      'low_stock_items': lowStockItems,
      'out_of_stock_items': outOfStockItems,
    };
  }

  double get equipmentUtilizationRate {
    if (totalEquipment == 0) return 0.0;
    return borrowedEquipment / totalEquipment;
  }

  double get maintenanceRate {
    if (totalEquipment == 0) return 0.0;
    return maintenanceEquipment / totalEquipment;
  }

  double get overdueRate {
    if (activeBorrowRequests == 0) return 0.0;
    return overdueRequests / activeBorrowRequests;
  }
}
