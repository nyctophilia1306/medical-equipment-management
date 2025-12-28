import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../models/audit_log.dart';
import '../../services/audit_log_service.dart';
import '../../services/user_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final AuditLogService _auditLogService = AuditLogService();
  final UserService _userService = UserService();
  
  List<AuditLog> _logs = [];
  final Map<String, String> _userNames = {}; // Cache user names
  bool _isLoading = true;
  String? _selectedCategory;
  int _currentPage = 0;
  final int _logsPerPage = 20;
  bool _hasMore = true;

  final List<String> _categories = [
    'Tất Cả',
    'Xác Thực',
    'Thiết Bị',
    'Yêu Cầu Mượn',
    'Danh Mục',
    'Người Dùng',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _currentPage++);
    } else {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _logs = [];
        _hasMore = true;
      });
    }

    try {
      List<AuditLog> newLogs;
      
      if (_selectedCategory == null || _selectedCategory == 'All') {
        newLogs = await _auditLogService.getSystemLogs(
          limit: _logsPerPage,
          offset: _currentPage * _logsPerPage,
        );
      } else {
        newLogs = await _auditLogService.getLogsByCategory(
          _selectedCategory!,
          limit: _logsPerPage,
        );
      }

      // Load user names for new logs
      for (var log in newLogs) {
        if (!_userNames.containsKey(log.userId)) {
          final user = await _userService.getUserById(log.userId);
          if (user != null) {
            _userNames[log.userId] = user.fullName ?? user.userName;
          }
        }
      }

      setState(() {
        if (loadMore) {
          _logs.addAll(newLogs);
        } else {
          _logs = newLogs;
        }
        _hasMore = newLogs.length == _logsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getActionColor(String actionType) {
    if (actionType == AuditLog.actionLogin || actionType == AuditLog.actionLogout) {
      return AppColors.primaryBlue;
    } else if (actionType.contains('create')) {
      return AppColors.successGreen;
    } else if (actionType.contains('update') || actionType.contains('change')) {
      return AppColors.warningYellow;
    } else if (actionType.contains('delete')) {
      return AppColors.errorRed;
    } else if (actionType == AuditLog.actionEquipmentStatusChange) {
      return const Color(0xFF9C27B0); // Purple
    }
    return AppColors.grayNeutral600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: AppColors.backgroundWhite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by Category',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = category == (_selectedCategory ?? 'All');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category == 'All' ? null : category;
                            });
                            _loadLogs();
                          },
                          backgroundColor: AppColors.backgroundWhite,
                          selectedColor: AppColors.primaryBlue.withAlpha((0.2 * 255).round()),
                          labelStyle: GoogleFonts.inter(
                            color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: _isLoading && _logs.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: AppColors.textSecondary.withAlpha((0.5 * 255).round()),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              'No audit logs found',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadLogs(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          itemCount: _logs.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _logs.length) {
                              // Load more button
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                                child: Center(
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton.icon(
                                          onPressed: () => _loadLogs(loadMore: true),
                                          icon: const Icon(Icons.arrow_downward),
                                          label: const Text('Load More'),
                                        ),
                                ),
                              );
                            }

                            final log = _logs[index];
                            return _buildLogCard(log);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AuditLog log) {
    final userName = _userNames[log.userId] ?? 'Unknown User';
    final actionColor = _getActionColor(log.actionType);

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: actionColor.withAlpha((0.2 * 255).round()),
          child: Icon(
            _getActionIcon(log.actionType),
            color: actionColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                log.getActionDisplayName(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: actionColor.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                log.getActionCategory(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: actionColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  userName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(log.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.borderRadiusMedium),
                bottomRight: Radius.circular(AppConstants.borderRadiusMedium),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.targetType != null) ...[
                  _buildDetailRow('Target Type', log.targetType!),
                  const SizedBox(height: 8),
                ],
                if (log.targetId != null) ...[
                  _buildDetailRow('Target ID', log.targetId!),
                  const SizedBox(height: 8),
                ],
                if (log.ipAddress != null) ...[
                  _buildDetailRow('IP Address', log.ipAddress!),
                  const SizedBox(height: 8),
                ],
                if (log.details != null && log.details!.isNotEmpty) ...[
                  Text(
                    'Details:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatDetails(log.details!),
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDetails(Map<String, dynamic> details) {
    final buffer = StringBuffer();
    details.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }

  IconData _getActionIcon(String actionType) {
    if (actionType == AuditLog.actionLogin) {
      return Icons.login;
    } else if (actionType == AuditLog.actionLogout) {
      return Icons.logout;
    } else if (actionType.contains('create')) {
      return Icons.add_circle_outline;
    } else if (actionType.contains('update') || actionType.contains('change')) {
      return Icons.edit_outlined;
    } else if (actionType.contains('delete')) {
      return Icons.delete_outline;
    } else if (actionType.contains('equipment')) {
      return Icons.medical_services_outlined;
    } else if (actionType.contains('borrow')) {
      return Icons.shopping_cart_outlined;
    } else if (actionType.contains('category')) {
      return Icons.category_outlined;
    } else if (actionType.contains('user')) {
      return Icons.person_outlined;
    }
    return Icons.info_outline;
  }
}
