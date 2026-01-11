import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../services/metadata_service.dart';
import '../../services/data_service.dart';
import '../../models/category.dart';
import '../../l10n/app_localizations.dart';

class CategoryManagementScreen extends StatefulWidget {
  static const String routeName = '/category-management';

  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final MetadataService _metadataService = MetadataService();
  final DataService _dataService = DataService();
  final TextEditingController _searchController = TextEditingController();

  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];
  Map<int, int> _equipmentCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _metadataService.getCategories(
        forceRefresh: true,
      );

      // Load equipment counts for each category
      final counts = <int, int>{};
      for (var category in categories) {
        final equipment = await _dataService.getEquipment(
          category: category.name,
        );
        counts[category.id] = equipment.length;
      }

      setState(() {
        _allCategories = categories;
        _equipmentCounts = counts;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredCategories = _allCategories);
    } else {
      setState(() {
        _filteredCategories = _allCategories
            .where(
              (c) =>
                  c.name.toLowerCase().contains(query) ||
                  (c.description?.toLowerCase().contains(query) ?? false),
            )
            .toList();
      });
    }
  }

  List<Category> _getParentCategories() {
    return _filteredCategories
        .where((c) => c.parentCategoryId == null)
        .toList();
  }

  List<Category> _getChildCategories(int parentId) {
    return _filteredCategories
        .where((c) => c.parentCategoryId == parentId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.categoryManagement,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            color: AppColors.backgroundWhite,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchCategories,
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
          ),

          // Categories List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCategories.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadCategories,
                    child: ListView(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      children: _buildCategoryTree(),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addCategory),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            AppLocalizations.of(context)!.noCategoriesFound,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            AppLocalizations.of(context)!.addCategory,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryTree() {
    final parentCategories = _getParentCategories();
    final widgets = <Widget>[];

    for (var parent in parentCategories) {
      final children = _getChildCategories(parent.id);

      if (children.isEmpty) {
        // Parent with no children - show as card
        widgets.add(_buildCategoryCard(parent));
      } else {
        // Parent with children - show as expansion tile
        widgets.add(_buildParentCategorySection(parent, children));
      }
    }

    return widgets;
  }

  Widget _buildParentCategorySection(Category parent, List<Category> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlue.withAlpha((0.2 * 255).round()),
          child: Icon(Icons.folder, color: AppColors.primaryBlue, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                parent.name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.softTeal.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${children.length} subcategories',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.softTeal,
                ),
              ),
            ),
          ],
        ),
        subtitle: parent.description != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  parent.description!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEquipmentBadge(parent.id),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showCategoryDialog(category: parent),
              color: AppColors.primaryBlue,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outlined, size: 20),
              onPressed: () => _confirmDeleteCategory(parent),
              color: AppColors.errorRed,
            ),
          ],
        ),
        children: children
            .map((child) => _buildChildCategoryCard(child))
            .toList(),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.warningYellow.withAlpha(
                (0.2 * 255).round(),
              ),
              child: Icon(
                Icons.label,
                color: AppColors.warningYellow,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.getLocalizedName(context),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      category.description!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            _buildEquipmentBadge(category.id),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showCategoryDialog(category: category),
              color: AppColors.primaryBlue,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outlined, size: 20),
              onPressed: () => _confirmDeleteCategory(category),
              color: AppColors.errorRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCategoryCard(Category category) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Icon(
            Icons.subdirectory_arrow_right,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.getLocalizedName(context),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    category.description!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          _buildEquipmentBadge(category.id),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => _showCategoryDialog(category: category),
            color: AppColors.primaryBlue,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outlined, size: 18),
            onPressed: () => _confirmDeleteCategory(category),
            color: AppColors.errorRed,
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentBadge(int categoryId) {
    final count = _equipmentCounts[categoryId] ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: count > 0
            ? AppColors.successGreen.withAlpha((0.2 * 255).round())
            : AppColors.grayNeutral600.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 14,
            color: count > 0
                ? AppColors.successGreen
                : AppColors.grayNeutral600,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: count > 0
                  ? AppColors.successGreen
                  : AppColors.grayNeutral600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    int? selectedParentId = category?.parentCategoryId;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? AppLocalizations.of(context)!.editCategory : AppLocalizations.of(context)!.addCategory,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.categoryNameRequired,
                        hintText: AppLocalizations.of(context)!.enterCategoryName,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusSmall,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        hintText: AppLocalizations.of(context)!.enterDescriptionOptional,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusSmall,
                          ),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedParentId,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.parentCategory,
                        hintText: AppLocalizations.of(context)!.selectParentCategoryOptional,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusSmall,
                          ),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(AppLocalizations.of(context)!.noParentCategory),
                        ),
                        ..._allCategories
                            .where(
                              (c) =>
                                  c.parentCategoryId == null &&
                                  (category == null || c.id != category.id),
                            )
                            .map(
                              (c) => DropdownMenuItem<int?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedParentId = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.categoryNameRequired,
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: Text(
                    isEdit
                        ? AppLocalizations.of(context)!.update
                        : AppLocalizations.of(context)!.add,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final name = nameController.text.trim();
      final description = descriptionController.text.trim();

      try {
        if (isEdit) {
          final updated = category.copyWith(
            name: name,
            description: description.isEmpty ? null : description,
            parentCategoryId: selectedParentId,
          );
          final success = await _metadataService.updateCategory(updated);
          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.editCategorySuccess)),
              );
            }
            await _loadCategories();
          }
        } else {
          final newCategory = await _metadataService.createCategory(
            name,
            description: description.isEmpty ? null : description,
            parentCategoryId: selectedParentId,
          );
          if (newCategory != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.addCategorySuccess)),
              );
            }
            await _loadCategories();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.saveCategoryFailed}: $e')),
          );
        }
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    // Check if category has equipment
    final equipmentCount = _equipmentCounts[category.id] ?? 0;

    // Check if category has children
    final children = _allCategories
        .where((c) => c.parentCategoryId == category.id)
        .toList();

    String message;
    if (equipmentCount > 0) {
      message =
          '${AppLocalizations.of(context)!.cannotDelete}.';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.cannotDelete,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.agree),
            ),
          ],
        ),
      );
      return;
    }

    if (children.isNotEmpty) {
      message =
          '${AppLocalizations.of(context)!.categoryHasSubcategories} ${children.length} ${AppLocalizations.of(context)!.subcategories}. ${AppLocalizations.of(context)!.deletingCategoryWillAlsoDeleteSubcategories} ${AppLocalizations.of(context)!.continueText}?';
    } else {
      message = '${AppLocalizations.of(context)!.areYouSureYouWantToDelete} "${category.name}"?';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            AppLocalizations.of(context)!.confirmDeleteCategory,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete children first
        for (var child in children) {
          await _metadataService.deleteCategory(child.id);
        }

        // Delete the category
        final success = await _metadataService.deleteCategory(category.id);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  children.isEmpty
                      ? AppLocalizations.of(context)!.categoryDeleted
                      : '${AppLocalizations.of(context)!.categoryAnd} ${children.length} ${AppLocalizations.of(context)!.subcategoriesDeleted}',
                ),
              ),
            );
          }
          await _loadCategories();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.deleteCategoryFailed}: $e')),
          );
        }
      }
    }
  }
}
