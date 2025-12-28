import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:async';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../models/category.dart';
import '../../models/equipment.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/metadata_service.dart';
import 'equipment_form_screen.dart';
import 'equipment_import_preview_screen.dart';
import '../../l10n/app_localizations.dart';

class EquipmentCatalogScreen extends StatefulWidget {
  const EquipmentCatalogScreen({super.key});

  @override
  State<EquipmentCatalogScreen> createState() => _EquipmentCatalogScreenState();
}

class _EquipmentCatalogScreenState extends State<EquipmentCatalogScreen> {
  final _searchController = TextEditingController();
  final DataService _dataService = DataService();
  final AuthService _authService = AuthService();
  final MetadataService _metadataService = MetadataService();

  String _statusFilter = 'all';
  String _categoryFilter = 'all';
  bool _isGrid = true;
  bool _loading = true;
  String? _error;
  List<Equipment> _items = [];
  List<Category> _categories = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  void _addNewEquipment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EquipmentFormScreen()),
    ).then((_) {
      // Refresh the equipment list when returning from the form
      _load();
    });
  }

  void _editEquipment(Equipment equipment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EquipmentFormScreen(equipment: equipment),
      ),
    ).then((_) {
      // Refresh the equipment list when returning from the form
      _load();
    });
  }

  void _deleteEquipment(Equipment equipment) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteEquipment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            onPressed: () async {
              try {
                Navigator.pop(context);
                setState(() => _loading = true);
                await _dataService.deleteEquipment(equipment.id);
                setState(() {
                  _items.removeWhere((e) => e.id == equipment.id);
                  _loading = false;
                });
              } catch (e) {
                setState(() {
                  _error = 'Failed to delete: $e';
                  _loading = false;
                });
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromExcel() async {
    try {
      // Pick Excel file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return; // User canceled
      }

      final file = result.files.first;
      if (file.bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Could not read file'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Navigate to preview screen
      if (mounted) {
        final imported = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                EquipmentImportPreviewScreen(excelBytes: file.bytes!),
          ),
        );

        if (imported == true) {
          _load(); // Refresh the list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = _statusFilter == 'all' ? null : _statusFilter;
      // For category, pass the actual category name if selected
      final categoryName = _categoryFilter == 'all' ? null : _categoryFilter;

      // Get equipment with proper category filtering
      final results = await _dataService.getEquipment(
        searchQuery: _searchController.text.trim(),
        status: status,
        category: categoryName,
        limit: 200,
      );

      // Fetch categories if needed
      List<Category> cats = _categories;
      if (_categories.isEmpty) {
        cats = await _metadataService.getCategories();
      }

      setState(() {
        _items = results;
        _categories = cats;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(context),
          Expanded(child: _buildResults(context)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                  AppLocalizations.of(context)!.equipmentCatalogTitle,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.equipmentCatalogSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (_authService.canManageEquipment())
            Padding(
              padding: const EdgeInsets.only(right: AppConstants.paddingMedium),
              child: ElevatedButton.icon(
                onPressed: _importFromExcel,
                icon: const Icon(Icons.upload_file),
                label: Text(AppLocalizations.of(context)!.importExcel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: AppColors.textOnPrimary,
                ),
              ),
            ),
          if (_authService.canManageEquipment())
            Padding(
              padding: const EdgeInsets.only(right: AppConstants.paddingMedium),
              child: ElevatedButton.icon(
                onPressed: _addNewEquipment,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addEquipment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textOnPrimary,
                ),
              ),
            ),
          Icon(
            Icons.inventory_2_outlined,
            size: 32,
            color: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use responsive layout based on screen width
        final isNarrow = constraints.maxWidth < 1200;

        // For narrow screens, stack filters in two rows
        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingLarge,
              AppConstants.paddingMedium,
              AppConstants.paddingLarge,
              AppConstants.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              border: Border(
                bottom: BorderSide(color: AppColors.grayNeutral200, width: 1),
              ),
            ),
            child: Column(
              children: [
                // First row: Search and view toggle
                Row(
                  children: [
                    // Search field
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, serial, manufacturer...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium,
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    // Grid/List toggle
                    SizedBox(
                      height: 48, // Match height with TextField
                      child: Tooltip(
                        message: _isGrid
                            ? 'Switch to list view'
                            : 'Switch to grid view',
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _isGrid = !_isGrid),
                          icon: Icon(
                            _isGrid ? Icons.view_list : Icons.grid_view,
                          ),
                          label: Text(_isGrid ? 'List' : 'Grid'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                // Second row: Filters
                Row(
                  children: [
                    // Category filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _categoryFilter,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.category,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppConstants.borderRadiusMedium,
                            ),
                          ),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text(
                              AppLocalizations.of(context)!.allCategories,
                            ),
                          ),
                          ..._categories.map(
                            (c) => DropdownMenuItem(
                              value: c.name,
                              child: Text(c.getLocalizedName(context)),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _categoryFilter = v ?? 'all');
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    // Status filter
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context)!;
                          return DropdownButtonFormField<String>(
                            initialValue: _statusFilter,
                            decoration: InputDecoration(
                              labelText: l10n.status,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadiusMedium,
                                ),
                              ),
                              isDense: true,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(l10n.allStatuses),
                              ),
                              DropdownMenuItem(
                                value: 'available',
                                child: Text(l10n.available),
                              ),
                              DropdownMenuItem(
                                value: 'borrowed',
                                child: Text(l10n.borrowed),
                              ),
                              DropdownMenuItem(
                                value: 'maintenance',
                                child: Text(l10n.maintenance),
                              ),
                              DropdownMenuItem(
                                value: 'out_of_order',
                                child: Text(l10n.outOfOrder),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _statusFilter = v ?? 'all');
                              _load();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // For wider screens, show everything in one row
        return Container(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingLarge,
            AppConstants.paddingMedium,
            AppConstants.paddingLarge,
            AppConstants.paddingMedium,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            border: Border(
              bottom: BorderSide(color: AppColors.grayNeutral200, width: 1),
            ),
          ),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, serial, manufacturer...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadiusMedium,
                      ),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              // Category filter
              SizedBox(
                width: 180,
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return DropdownButtonFormField<String>(
                      initialValue: _categoryFilter,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                        ),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(l10n.allCategories),
                        ),
                        ..._categories.map(
                          (c) => DropdownMenuItem(
                            value: c.name,
                            child: Text(c.getLocalizedName(context)),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _categoryFilter = v ?? 'all');
                        _load();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              // Status filter
              SizedBox(
                width: 180,
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: InputDecoration(
                        labelText: l10n.status,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                        ),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(l10n.allStatuses),
                        ),
                        DropdownMenuItem(
                          value: 'available',
                          child: Text(l10n.available),
                        ),
                        DropdownMenuItem(
                          value: 'borrowed',
                          child: Text(l10n.borrowed),
                        ),
                        DropdownMenuItem(
                          value: 'maintenance',
                          child: Text(l10n.maintenance),
                        ),
                        DropdownMenuItem(
                          value: 'out_of_order',
                          child: Text(l10n.outOfOrder),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _statusFilter = v ?? 'all');
                        _load();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              // Grid/List toggle
              Tooltip(
                message: _isGrid
                    ? 'Switch to list view'
                    : 'Switch to grid view',
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isGrid = !_isGrid),
                  icon: Icon(_isGrid ? Icons.view_list : Icons.grid_view),
                  label: Text(_isGrid ? 'List' : 'Grid'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResults(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: GoogleFonts.inter(color: AppColors.errorRed),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              'No equipment found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or filters',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fixed layout to consistently display 3 items per row in grid view
        final screenWidth = constraints.maxWidth;
        int crossAxisCount;
        double childAspect;

        if (_isGrid) {
          // Always use 3 cards per row as requested
          crossAxisCount = 3;

          // Adjust aspect ratio based on available width for better responsiveness
          if (screenWidth > 1500) {
            childAspect = 1.2; // Wider aspect for very large screens
          } else if (screenWidth > 1200) {
            childAspect = 1.0; // Square-ish aspect for large screens
          } else {
            childAspect = 0.9; // Taller aspect for medium screens
          }
        } else {
          // List view always has 1 column
          crossAxisCount = 1;
          childAspect = screenWidth > 1000 ? 5.0 : 4.0;
        }

        return Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: GridView.builder(
            // Apply padding to the GridView to give more breathing room
            padding: const EdgeInsets.all(4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              // More space between items
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspect,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final e = _items[index];
              return _EquipmentCard(
                item: e,
                grid: _isGrid,
                onEdit: _editEquipment,
                onDelete: _deleteEquipment,
              );
            },
          ),
        );
      },
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final Equipment item;
  final bool grid;
  final Function(Equipment) onEdit;
  final Function(Equipment) onDelete;

  const _EquipmentCard({
    required this.item,
    required this.grid,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor() {
    switch (item.status) {
      case 'available':
        return AppColors.successGreen;
      case 'borrowed':
        return AppColors.primaryBlue.withAlpha((0.9 * 255).round());
      case 'maintenance':
        return AppColors.warningYellow;
      case 'out_of_order':
        return AppColors.errorRed;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildDetailsDialog(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 900, // Wider dialog
        constraints: const BoxConstraints(maxHeight: 600),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side - Full image
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: AppColors.grayNeutral100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.medical_services,
                              size: 120,
                              color: Colors.grey,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(
                          Icons.medical_services,
                          size: 120,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // Right side - Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with title and close button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor().withAlpha(
                                (0.1 * 255).round(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _statusColor()),
                            ),
                            child: Text(
                              item.status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Details
                          _detailRow(
                            'Danh mục:',
                            item.categoryName ?? item.category ?? 'General',
                          ),
                          _detailRow('Số lượng:', item.quantity.toString()),
                          _detailRow('Có sẵn:', item.availableQty.toString()),
                          if (item.serialNumber != null)
                            _detailRow('Số Serial:', item.serialNumber!),
                          if (item.manufacturer != null)
                            _detailRow('Nhà sản xuất:', item.manufacturer!),
                          if (item.model != null)
                            _detailRow('Model:', item.model!),
                          const SizedBox(height: 16),
                          Text(
                            'Mô tả:',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Ghi chú:',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.notes!,
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (AuthService().canManageEquipment()) ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Sửa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onEdit(item);
                            },
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Xóa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.errorRed,
                              side: const BorderSide(color: AppColors.errorRed),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDelete(item);
                            },
                          ),
                          const SizedBox(width: 12),
                        ],
                        TextButton(
                          child: const Text('Đóng'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use different layouts for grid and list view for better clarity
    return InkWell(
      onTap: () {
        // Show detailed view of the equipment
        showDialog(
          context: context,
          builder: (context) => _buildDetailsDialog(context),
        );
      },
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: item.isLowStock
                ? AppColors.warningYellow.withAlpha((0.3 * 255).round())
                : item.isOutOfStock
                ? AppColors.errorRed.withAlpha((0.3 * 255).round())
                : AppColors.shadowLight,
            width: 1,
          ),
        ),
        // Use smaller padding and make sure height is properly constrained
        padding: grid
            ? const EdgeInsets.all(12) // Smaller padding for grid view
            : const EdgeInsets.all(AppConstants.paddingLarge),
        // Use SizedBox.expand to ensure the child takes exactly the available space
        child: SizedBox.expand(
          child: grid ? _buildGridLayout() : _buildListLayout(),
        ),
      ),
    );
  }

  // List layout with horizontal arrangement
  Widget _buildListLayout() {
    return Row(
      children: [
        // Image / placeholder - larger for list view
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.grayNeutral100,
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image,
                      color: AppColors.textSecondary.withAlpha(
                        (0.6 * 255).round(),
                      ),
                      size: 40,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                )
              : Icon(
                  Icons.medical_services,
                  color: AppColors.textSecondary.withAlpha((0.6 * 255).round()),
                  size: 40,
                ),
        ),
        const SizedBox(width: AppConstants.paddingLarge),
        // Details - expanded layout for list view
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              // Description snippet
              Text(
                item.description.length > 100
                    ? '${item.description.substring(0, 97)}...'
                    : item.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              // Two rows of metadata
              Row(
                children: [
                  _buildInfoChip(
                    Icons.category_outlined,
                    item.categoryName ?? item.category ?? 'General',
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  if (item.serialNumber != null)
                    _buildInfoChip(Icons.qr_code, item.serialNumber!),
                ],
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Row(
                children: [
                  _buildQuantityIndicator(),
                  const Spacer(),
                  if (AuthService().canManageEquipment()) _buildActionButtons(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Grid layout with vertical arrangement - fixed layout to prevent overflow
  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image at the top - larger for better visibility
        Container(
          width: double.infinity,
          height: 240, // Large image for better visibility and detail
          decoration: BoxDecoration(
            color: AppColors.grayNeutral100,
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadiusMedium,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image,
                      color: AppColors.textSecondary.withAlpha(
                        (0.6 * 255).round(),
                      ),
                      size: 40,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                )
              : Icon(
                  Icons.medical_services,
                  color: AppColors.textSecondary.withAlpha((0.6 * 255).round()),
                  size: 40,
                ),
        ),
        const SizedBox(height: 8), // Reduced spacing
        // Title and status badge
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align to top for multi-line title
          children: [
            Expanded(
              child: Text(
                item.name,
                maxLines: 1, // Limit to single line to save space
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16, // Slightly smaller font
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 4), // Reduced spacing
        // Category info
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.categoryName ?? item.category ?? 'General',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Room info
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.qr_code, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.serialNumber ?? 'No serial',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Spacer(), // Flexible spacing
        // Quantity indicator
        _buildQuantityIndicator(),
        const SizedBox(height: 6),
        // Bottom row with actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (AuthService().canManageEquipment()) _buildActionButtons(),
          ],
        ),
      ],
    );
  }

  // Reusable components
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _statusColor().withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _statusColor().withAlpha((0.2 * 255).round()),
        ),
      ),
      child: Text(
        item.status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _statusColor(),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildQuantityIndicator() {
    final quantityColor = item.isOutOfStock
        ? AppColors.errorRed
        : item.isLowStock
        ? AppColors.warningYellow
        : AppColors.successGreen;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ), // Smaller padding
      decoration: BoxDecoration(
        color: quantityColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: quantityColor.withAlpha((0.3 * 255).round())),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 12, // Smaller icon
            color: quantityColor,
          ),
          const SizedBox(width: 4), // Less spacing
          Text(
            '${item.quantity}', // Using the single quantity field
            style: GoogleFonts.inter(
              fontSize: 12, // Smaller font
              fontWeight: FontWeight.w500,
              color: quantityColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          color: AppColors.primaryBlue,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onEdit(item),
          tooltip: 'Edit',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColors.errorRed,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onDelete(item),
          tooltip: 'Delete',
        ),
      ],
    );
  }
}
