class User {
  final String id;
  final String userName;
  final String? email;
  final String? fullName;
  final DateTime? dob;
  final String? gender;
  final String? phone;
  final int roleId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.userName,
    this.email,
    this.fullName,
    this.dob,
    this.gender,
    this.phone,
    required this.roleId,
    required this.createdAt,
    this.updatedAt,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      dob: json['dob'] != null ? DateTime.parse(json['dob'].toString()) : null,
      gender: json['gender']?.toString(),
      phone: json['phone']?.toString(),
      roleId: json['role_id'] is int ? json['role_id'] : int.tryParse(json['role_id']?.toString() ?? '2') ?? 2,
      createdAt: json['created_at'] != null ? 
          DateTime.parse(json['created_at'].toString()) : 
          DateTime.now(),
      updatedAt: json['updated_at'] != null ? 
          DateTime.parse(json['updated_at'].toString()) : null,
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'user_id': id,
      'user_name': userName,
      'role_id': roleId,
      'created_at': createdAt.toIso8601String(),
    };
    
    // Add optional fields only if they have values
    if (email != null) data['email'] = email;
    if (fullName != null) data['full_name'] = fullName;
    if (dob != null) data['dob'] = dob!.toIso8601String();
    if (gender != null) data['gender'] = gender;
    if (phone != null) data['phone'] = phone;
    if (updatedAt != null) data['updated_at'] = updatedAt!.toIso8601String();
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    
    return data;
  }

  User copyWith({
    String? id,
    String? userName,
    String? email,
    String? fullName,
    DateTime? dob,
    String? gender,
    String? phone,
    int? roleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  // Role helpers based on roleId
  bool get isUser => roleId == 2;
  bool get isManager => roleId == 1;
  bool get isAdmin => roleId == 0;

  // Permission helpers
  bool get canViewEquipment => true;
  bool get canCreateBorrowRequests => isManager || isAdmin;
  bool get canManageEquipment => isAdmin;
  bool get canManageUsers => isAdmin;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, userName: $userName, roleId: $roleId)';
  }
}
