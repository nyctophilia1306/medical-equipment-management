import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart' as app_user;
import '../equipment/equipment_catalog_screen.dart';
import '../borrow/borrow_management_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/sign_in_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  app_user.User? get currentUser => _authService.currentUser;

  @override
  void initState() {
    super.initState();
    // No redirect for guests; dashboard is publicly accessible for search.
  }

  @override
  Widget build(BuildContext context) {
    // Dashboard remains visible for guests; features adapt by role.

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Row(
        children: [
          // Sidebar Navigation
          _buildSidebar(),

          // Main Content
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildSidebarHeader(),

          // Navigation Items
          Expanded(child: _buildNavigationItems()),

          // User Profile & Sign Out
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
            ),
            child: const Icon(
              Icons.medical_services,
              color: AppColors.textOnPrimary,
              size: 24,
            ),
          ),

          const SizedBox(width: AppConstants.paddingMedium),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                Text(
                  'v${AppConstants.appVersion}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textOnPrimary.withAlpha(
                      (0.8 * 255).round(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems() {
    final navigationItems = _getNavigationItems();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
      itemCount: navigationItems.length,
      itemBuilder: (context, index) {
        final item = navigationItems[index];
        final isSelected = _selectedIndex == index;

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withAlpha((0.1 * 255).round())
                : null,
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
          ),
          child: ListTile(
            leading: Icon(
              item.icon,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
              size: 22,
            ),
            title: Text(
              item.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.textPrimary,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppConstants.borderRadiusMedium,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserProfile() {
    final isGuest = !_authService.isAuthenticated || currentUser == null;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.grayNeutral200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // User Info
          Row(
            children: [
              if (!isGuest)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryBlue,
                  backgroundImage: currentUser!.avatarUrl != null
                      ? NetworkImage(currentUser!.avatarUrl!)
                      : null,
                  child: currentUser!.avatarUrl == null
                      ? Text(
                          currentUser!.userName.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnPrimary,
                          ),
                        )
                      : null,
                ),
              if (isGuest)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.grayNeutral200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.textSecondary,
                  ),
                ),

              const SizedBox(width: AppConstants.paddingMedium),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGuest
                          ? AppLocalizations.of(context)!.guest
                          : currentUser!.userName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isGuest
                          ? 'Viewer (Public)'
                          : _getRoleDisplayName(currentUser!.roleId),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Language selector removed - Vietnamese only

          // Auth Actions
          if (!isGuest)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.errorRed),
                  foregroundColor: AppColors.errorRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.borderRadiusMedium,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 16),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      AppLocalizations.of(context)!.signOut,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                ),
                child: Text(AppLocalizations.of(context)!.signIn),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final screens = _getScreens();

    if (_selectedIndex >= screens.length) {
      return const Center(child: Text('Screen not found'));
    }
    final isGuest = !_authService.isAuthenticated || currentUser == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Identity chip for authenticated users
        if (!isGuest)
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLarge,
              AppConstants.paddingLarge,
              AppConstants.paddingLarge,
              AppConstants.paddingSmall,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha((0.08 * 255).round()),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primaryBlue.withAlpha((0.2 * 255).round()),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Đã đăng nhập với tên ${currentUser!.userName} · ${_getRoleDisplayName(currentUser!.roleId)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: screens[_selectedIndex]),
      ],
    );
  }

  List<NavigationItem> _getNavigationItems() {
    final l10n = AppLocalizations.of(context)!;
    final items = <NavigationItem>[];

    // Equipment Catalog (Available to all roles)
    items.add(
      NavigationItem(
        icon: Icons.inventory_2_outlined,
        title: l10n.equipmentCatalog,
      ),
    );

    // Manager and Admin features (only when authenticated)
    if (currentUser?.canCreateBorrowRequests == true) {
      items.add(
        NavigationItem(
          icon: Icons.assignment_outlined,
          title: l10n.borrowManagement,
        ),
      );
    }

    // Admin-only features (only when authenticated)
    if (currentUser?.canManageUsers == true) {
      items.add(
        NavigationItem(
          icon: Icons.dashboard_outlined,
          title: l10n.adminDashboard,
        ),
      );
    }

    return items;
  }

  List<Widget> _getScreens() {
    final screens = <Widget>[];

    // Equipment Catalog (Available to all roles)
    screens.add(const EquipmentCatalogScreen());

    // Manager and Admin features (only when authenticated)
    if (currentUser?.canCreateBorrowRequests == true) {
      screens.add(const BorrowManagementScreen());
    }

    // Admin-only features (only when authenticated)
    if (currentUser?.canManageUsers == true) {
      screens.add(const AdminDashboardScreen());
    }

    return screens;
  }

  String _getRoleDisplayName(int roleId) {
    switch (roleId) {
      case 2: // User role
        return 'User (Viewer)';
      case 1: // Manager role
        return 'Manager';
      case 0: // Admin role
        return 'Administrator';
      default:
        return 'Unknown Role ($roleId)';
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Đăng Xuất',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('Đăng Xuất'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainDashboard()),
        );
      }
    }
  }
}

class NavigationItem {
  final IconData icon;
  final String title;

  NavigationItem({required this.icon, required this.title});
}
