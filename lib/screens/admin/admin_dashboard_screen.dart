import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../services/statistics_service.dart';
import '../../l10n/app_localizations.dart';
import '../equipment/equipment_catalog_screen.dart';
import 'user_management_screen.dart';
import 'category_management_screen.dart';
import 'analytics_screen.dart';
import 'audit_logs_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final StatisticsService _statsService = StatisticsService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _statsService.getSystemStatistics();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: const BoxDecoration(
                color: AppColors.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.adminDashboardTitle,
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.systemOverviewSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 28),
                    onPressed: _loadStatistics,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics Overview
                          _buildStatisticsSection(),
                          
                          const SizedBox(height: AppConstants.paddingXLarge),
                          
                          // Admin Functions Grid
                          _buildAdminFunctionsSection(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final userStats = _stats['users'] as Map<String, dynamic>? ?? {};
    final equipmentStats = _stats['equipment'] as Map<String, dynamic>? ?? {};
    final borrowStats = _stats['borrowRequests'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.systemStatistics,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        
        // Statistics Cards Row 1
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: AppLocalizations.of(context)!.totalUsers,
                value: '${userStats['total'] ?? 0}',
                icon: Icons.people,
                color: AppColors.primaryBlue,
                subtitle: '${AppLocalizations.of(context)!.adminsLabel}: ${userStats['admins'] ?? 0} | ${AppLocalizations.of(context)!.managersLabel}: ${userStats['managers'] ?? 0}',
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildStatCard(
                title: AppLocalizations.of(context)!.totalEquipment,
                value: '${equipmentStats['totalItems'] ?? 0}',
                icon: Icons.inventory_2,
                color: AppColors.successGreen,
                subtitle: '${AppLocalizations.of(context)!.quantityLabel}: ${equipmentStats['totalQuantity'] ?? 0} | ${AppLocalizations.of(context)!.availableQuantity}: ${equipmentStats['availableQuantity'] ?? 0}',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppConstants.paddingMedium),
        
        // Statistics Cards Row 2
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: AppLocalizations.of(context)!.pendingRequests,
                value: '${borrowStats['pending'] ?? 0}',
                icon: Icons.pending_actions,
                color: AppColors.warningYellow,
                subtitle: '${AppLocalizations.of(context)!.approvedLabel}: ${borrowStats['approved'] ?? 0}',
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: _buildStatCard(
                title: AppLocalizations.of(context)!.returned,
                value: '${borrowStats['returned'] ?? 0}',
                icon: Icons.check_circle,
                color: AppColors.primaryBlue,
                subtitle: '${AppLocalizations.of(context)!.totalLabel}: ${borrowStats['total'] ?? 0}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminFunctionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.management,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive layout
            int crossAxisCount = 3;
            if (constraints.maxWidth < 600) {
              crossAxisCount = 2; // Mobile
            } else if (constraints.maxWidth < 900) {
              crossAxisCount = 3; // Tablet
            } else {
              crossAxisCount = 4; // Desktop
            }
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppConstants.paddingMedium,
              crossAxisSpacing: AppConstants.paddingMedium,
              childAspectRatio: 1.4,
              children: [
                _buildFunctionCard(
                  title: AppLocalizations.of(context)!.userManagement,
                  subtitle: AppLocalizations.of(context)!.userManagementSubtitle,
                  icon: Icons.people_outlined,
                  color: AppColors.primaryBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                  ),
                ),
                _buildFunctionCard(
                  title: AppLocalizations.of(context)!.equipment,
                  subtitle: AppLocalizations.of(context)!.equipmentManagementSubtitle,
                  icon: Icons.medical_services_outlined,
                  color: AppColors.successGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EquipmentCatalogScreen()),
                  ),
                ),
                _buildFunctionCard(
                  title: AppLocalizations.of(context)!.categories,
                  subtitle: AppLocalizations.of(context)!.categoryManagementSubtitle,
                  icon: Icons.category_outlined,
                  color: AppColors.warningYellow,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
                  ),
                ),
                _buildFunctionCard(
                  title: AppLocalizations.of(context)!.analytics,
                  subtitle: AppLocalizations.of(context)!.analyticsSubtitle,
                  icon: Icons.analytics_outlined,
                  color: AppColors.softTeal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                  ),
                ),
                _buildFunctionCard(
                  title: AppLocalizations.of(context)!.auditLogs,
                  subtitle: AppLocalizations.of(context)!.auditLogsSubtitle,
                  icon: Icons.history_outlined,
                  color: AppColors.grayNeutral600,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFunctionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}