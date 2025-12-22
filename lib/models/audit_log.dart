class AuditLog {
  final String id;
  final String userId;
  final String actionType;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic>? details;
  final String? ipAddress;
  final DateTime timestamp;

  // Action type constants
  static const String actionLogin = 'login';
  static const String actionLogout = 'logout';
  static const String actionEquipmentCreate = 'equipment_create';
  static const String actionEquipmentUpdate = 'equipment_update';
  static const String actionEquipmentDelete = 'equipment_delete';
  static const String actionEquipmentStatusChange = 'equipment_status_change';
  static const String actionBorrowCreate = 'borrow_create';
  static const String actionBorrowUpdate = 'borrow_update';
  static const String actionBorrowReturn = 'borrow_return';
  static const String actionCategoryCreate = 'category_create';
  static const String actionCategoryUpdate = 'category_update';
  static const String actionCategoryDelete = 'category_delete';
  static const String actionUserCreate = 'user_create';
  static const String actionUserUpdate = 'user_update';
  static const String actionUserDelete = 'user_delete';
  static const String actionUserRoleChange = 'user_role_change';

  // Target type constants
  static const String targetEquipment = 'equipment';
  static const String targetBorrowRequest = 'borrow_request';
  static const String targetCategory = 'category';
  static const String targetUser = 'user';

  AuditLog({
    required this.id,
    required this.userId,
    required this.actionType,
    this.targetType,
    this.targetId,
    this.details,
    this.ipAddress,
    required this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['log_id'] as String,
      userId: json['user_id'] as String,
      actionType: json['action_type'] as String,
      targetType: json['target_type'] as String?,
      targetId: json['target_id'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': id,
      'user_id': userId,
      'action_type': actionType,
      'target_type': targetType,
      'target_id': targetId,
      'details': details,
      'ip_address': ipAddress,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Helper method to get action display name
  String getActionDisplayName() {
    switch (actionType) {
      case actionLogin:
        return 'Logged In';
      case actionLogout:
        return 'Logged Out';
      case actionEquipmentCreate:
        return 'Created Equipment';
      case actionEquipmentUpdate:
        return 'Updated Equipment';
      case actionEquipmentDelete:
        return 'Deleted Equipment';
      case actionEquipmentStatusChange:
        return 'Changed Equipment Status';
      case actionBorrowCreate:
        return 'Created Borrow Request';
      case actionBorrowUpdate:
        return 'Updated Borrow Request';
      case actionBorrowReturn:
        return 'Returned Equipment';
      case actionCategoryCreate:
        return 'Created Category';
      case actionCategoryUpdate:
        return 'Updated Category';
      case actionCategoryDelete:
        return 'Deleted Category';
      case actionUserCreate:
        return 'Created User';
      case actionUserUpdate:
        return 'Updated User';
      case actionUserDelete:
        return 'Deleted User';
      case actionUserRoleChange:
        return 'Changed User Role';
      default:
        return actionType;
    }
  }

  // Helper method to get action category for filtering
  String getActionCategory() {
    if (actionType.contains('equipment')) return 'Equipment';
    if (actionType.contains('borrow')) return 'Borrow Request';
    if (actionType.contains('category')) return 'Category';
    if (actionType.contains('user')) return 'User';
    if (actionType == actionLogin || actionType == actionLogout) return 'Authentication';
    return 'Other';
  }

  @override
  String toString() {
    return 'AuditLog(id: $id, userId: $userId, actionType: $actionType, targetType: $targetType, targetId: $targetId, timestamp: $timestamp)';
  }
}
