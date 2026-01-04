import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../services/user_service.dart';
import '../../models/user.dart' as app_user;

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  List<app_user.User> _allUsers = [];
  List<app_user.User> _filteredUsers = [];
  bool _isLoading = true;
  int? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Thất bại khi tải người dùng: $e')));
      }
    }
  }

  void _applyFilters() {
    var filtered = _allUsers;

    // Role filter
    if (_selectedRoleFilter != null) {
      filtered = filtered
          .where((u) => u.roleId == _selectedRoleFilter)
          .toList();
    }

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (u) =>
                u.userName.toLowerCase().contains(query) ||
                (u.fullName?.toLowerCase().contains(query) ?? false) ||
                (u.email?.toLowerCase().contains(query) ?? false) ||
                (u.phone?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    setState(() => _filteredUsers = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: Text(
          'Quản Lý Người Dùng',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: AppColors.backgroundWhite,
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên, email hoặc điện thoại...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingSmall),

                // Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất Cả', null),
                      _buildFilterChip('Quản Trị Viên', 0),
                      _buildFilterChip('Quản Lý', 1),
                      _buildFilterChip('Người Dùng', 2),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) =>
                        _buildUserCard(_filteredUsers[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm Người Dùng'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildFilterChip(String label, int? roleId) {
    final isSelected = _selectedRoleFilter == roleId;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedRoleFilter = selected ? roleId : null);
          _applyFilters();
        },
        selectedColor: AppColors.primaryBlue.withAlpha((0.2 * 255).round()),
        labelStyle: GoogleFonts.inter(
          color: isSelected ? AppColors.primaryBlue : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildUserCard(app_user.User user) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(
                    user.roleId,
                  ).withAlpha((0.2 * 255).round()),
                  child: Text(
                    user.userName.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(user.roleId),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.userName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (user.fullName != null)
                        Text(
                          user.fullName!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildRoleBadge(user.roleId),
              ],
            ),

            const SizedBox(height: AppConstants.paddingSmall),
            const Divider(),
            const SizedBox(height: AppConstants.paddingSmall),

            // User Details
            if (user.email != null)
              _buildDetailRow(Icons.email_outlined, user.email!),
            if (user.phone != null)
              _buildDetailRow(Icons.phone_outlined, user.phone!),
            if (user.dob != null)
              _buildDetailRow(
                Icons.cake_outlined,
                DateFormat('MMM dd, yyyy').format(user.dob!),
              ),
            if (user.gender != null)
              _buildDetailRow(Icons.person_outline, user.gender!),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Joined ${DateFormat('MMM dd, yyyy').format(user.createdAt)}',
            ),

            const SizedBox(height: AppConstants.paddingSmall),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showUserDialog(user: user),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Cập Nhật'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(user),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Xóa'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(int roleId) {
    final roleData = _getRoleData(roleId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: roleData['color'].withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: roleData['color'].withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Text(
        roleData['name'],
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: roleData['color'],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary.withAlpha((0.5 * 255).round()),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Không tìm thấy người dùng',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getRoleData(int roleId) {
    switch (roleId) {
      case 0:
        return {'name': 'Quản Trị Viên', 'color': AppColors.errorRed};
      case 1:
        return {'name': 'Quản Lý', 'color': AppColors.warningYellow};
      case 2:
      default:
        return {'name': 'Người Dùng', 'color': AppColors.successGreen};
    }
  }

  Color _getRoleColor(int roleId) => _getRoleData(roleId)['color'];

  Future<void> _showUserDialog({app_user.User? user}) async {
    final isEdit = user != null;
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController();
    final usernameController = TextEditingController(text: user?.userName);
    final fullNameController = TextEditingController(text: user?.fullName);
    final phoneController = TextEditingController(text: user?.phone);
    final genderController = TextEditingController(text: user?.gender);
    DateTime? selectedDob = user?.dob;
    int selectedRole = user?.roleId ?? 2;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEdit ? 'Cập Nhật Người Dùng' : 'Tạo Người Dùng Mới',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdit) ...[
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật Khẩu *',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên Đăng Nhập *',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ Và Tên',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số Điện Thoại',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: genderController,
                  decoration: const InputDecoration(
                    labelText: 'Giới Tính',
                    prefixIcon: Icon(Icons.wc),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.cake),
                  title: Text(
                    selectedDob == null
                        ? 'Chọn Ngày Sinh'
                        : DateFormat('MMM dd, yyyy').format(selectedDob!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDob ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDob = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Role Selection
                Text(
                  'Role *',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                // ignore: deprecated_member_use
                RadioTheme(
                  data: RadioThemeData(
                    fillColor: WidgetStateProperty.all(AppColors.primaryBlue),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        // ignore: deprecated_member_use
                        leading: Radio<int>(
                          value: 0,
                          // ignore: deprecated_member_use
                          groupValue: selectedRole,
                          // ignore: deprecated_member_use
                          onChanged: (val) => setDialogState(
                            () => selectedRole = val ?? 0,
                          ),
                          toggleable: false,
                        ),
                        title: const Text('Quản Trị Viên'),
                        onTap: () => setDialogState(() => selectedRole = 0),
                      ),
                      ListTile(
                        // ignore: deprecated_member_use
                        leading: Radio<int>(
                          value: 1,
                          // ignore: deprecated_member_use
                          groupValue: selectedRole,
                          // ignore: deprecated_member_use
                          onChanged: (val) => setDialogState(
                            () => selectedRole = val ?? 1,
                          ),
                          toggleable: false,
                        ),
                        title: const Text('Quản Lý'),
                        onTap: () => setDialogState(() => selectedRole = 1),
                      ),
                      ListTile(
                        // ignore: deprecated_member_use
                        leading: Radio<int>(
                          value: 2,
                          // ignore: deprecated_member_use
                          groupValue: selectedRole,
                          // ignore: deprecated_member_use
                          onChanged: (val) => setDialogState(
                            () => selectedRole = val ?? 2,
                          ),
                          toggleable: false,
                        ),
                        title: const Text('Người Dùng'),
                        onTap: () => setDialogState(() => selectedRole = 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isEdit) {
                  await _updateUser(
                    user.id,
                    usernameController.text,
                    fullNameController.text,
                    phoneController.text,
                    genderController.text,
                    selectedDob,
                    selectedRole,
                  );
                } else {
                  await _createUser(
                    emailController.text,
                    passwordController.text,
                    usernameController.text,
                    fullNameController.text,
                    phoneController.text,
                    genderController.text,
                    selectedDob,
                    selectedRole,
                  );
                }
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Cập Nhật' : 'Tạo Mới'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createUser(
    String email,
    String password,
    String username,
    String fullName,
    String phone,
    String gender,
    DateTime? dob,
    int roleId,
  ) async {
    try {
      await _userService.createUser(
        email: email,
        password: password,
        username: username,
        fullName: fullName.isNotEmpty ? fullName : null,
        phone: phone.isNotEmpty ? phone : null,
        gender: gender.isNotEmpty ? gender : null,
        dob: dob,
        roleId: roleId,
      );
      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo người dùng thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tạo người dùng: $e')));
    }
  }

  Future<void> _updateUser(
    String userId,
    String username,
    String fullName,
    String phone,
    String gender,
    DateTime? dob,
    int roleId,
  ) async {
    try {
      await _userService.updateUser(
        userId: userId,
        username: username.isNotEmpty ? username : null,
        fullName: fullName.isNotEmpty ? fullName : null,
        phone: phone.isNotEmpty ? phone : null,
        gender: gender.isNotEmpty ? gender : null,
        dob: dob,
        roleId: roleId,
      );
      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập Nhật Người Dùng Thành Công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể cập nhật người dùng: $e')));
    }
  }

  Future<void> _confirmDelete(app_user.User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Người Dùng'),
        content: Text('Bạn có chắc chắn muốn xóa ${user.userName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userService.deleteUser(user.id);
        await _loadUsers();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa người dùng thành công')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể xóa người dùng: $e')));
      }
    }
  }
}
