import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/constants.dart';
import '../../models/equipment.dart';
import '../../models/category.dart';
import '../../services/data_service.dart';
import '../../services/metadata_service.dart';
import '../../services/qr_code_service.dart';
import '../../utils/logger.dart';
import '../../utils/serial_generator.dart';
import '../../l10n/app_localizations.dart';

class EquipmentFormScreen extends StatefulWidget {
  final Equipment? equipment; // Null for create, non-null for edit

  const EquipmentFormScreen({super.key, this.equipment});

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DataService _dataService = DataService();
  final MetadataService _metadataService = MetadataService();
  final QrCodeService _qrCodeService = QrCodeService();

  bool _isLoading = false;
  bool _isEdit = false;
  String _errorMessage = '';
  bool _showQrCode = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _quantityController; // Updated field name
  late TextEditingController _statusController;
  late TextEditingController _imageUrlController;
  late TextEditingController _qrCodeController;
  late TextEditingController _serialNumberController;
  late TextEditingController _manufacturerController;
  late TextEditingController _modelController;
  // Purchase and maintenance fields removed for simplification
  late TextEditingController _notesController;

  List<Category> _categoryList = [];
  List<String> _categoryNames = [];
  int? _selectedCategoryId;

  final List<String> _statuses = [
    'available',
    'borrowed',
    'maintenance',
    'out_of_order',
  ];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.equipment != null;

    // Initialize controllers
    _nameController = TextEditingController(text: widget.equipment?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.equipment?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.equipment?.category ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.equipment?.quantity.toString() ?? '0',
    );
    _statusController = TextEditingController(
      text: widget.equipment?.status ?? 'available',
    );

    // Load categories
    _loadCategories();
    _imageUrlController = TextEditingController(
      text: widget.equipment?.imageUrl ?? '',
    );
    _qrCodeController = TextEditingController(
      text: widget.equipment?.qrCode ?? '',
    );
    _serialNumberController = TextEditingController(
      text: widget.equipment?.serialNumber ?? '',
    );
    _manufacturerController = TextEditingController(
      text: widget.equipment?.manufacturer ?? '',
    );
    _modelController = TextEditingController(
      text: widget.equipment?.model ?? '',
    );
    // Purchase and maintenance field controllers removed for simplification
    _notesController = TextEditingController(
      text: widget.equipment?.notes ?? '',
    );

    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _statusController.dispose();
    _imageUrlController.dispose();
    _qrCodeController.dispose();
    _serialNumberController.dispose();
    _manufacturerController.dispose();
    _modelController.dispose();
    // Purchase and maintenance controller disposal removed
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      // Load categories from MetadataService instead of DataService
      final categoryList = await _metadataService.getCategories();

      if (mounted) {
        setState(() {
          _categoryList = categoryList;
          _categoryNames = categoryList.map((cat) => cat.name).toList();

          // If editing an existing equipment, set the selected category ID
          if (widget.equipment != null &&
              widget.equipment!.categoryId != null) {
            _selectedCategoryId = widget.equipment!.categoryId;
          } else if (widget.equipment != null &&
              widget.equipment!.category?.isNotEmpty == true) {
            // Try to find a category by name for backward compatibility
            final matchingCategory = categoryList.firstWhere(
              (cat) =>
                  cat.name.toLowerCase() ==
                  widget.equipment!.category?.toLowerCase(),
              orElse: () =>
                  Category(id: -1, name: '', createdAt: DateTime.now()),
            );

            if (matchingCategory.id > 0) {
              _selectedCategoryId = matchingCategory.id;
              _categoryController.text = matchingCategory.name;
            }
          }
        });
      }
    } catch (e) {
      // Ignore errors, form will use text input if lists are empty
      Logger.error(
        '${AppLocalizations.of(context)!.errorLoadingCategories}: $e',
      );
    }
  }

  // Date selection method removed

  Future<void> _saveEquipment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Parse form data
      final name = _nameController.text;
      final description = _descriptionController.text;
      final category =
          _categoryController.text; // Keep for display purposes only
      final quantity = int.parse(_quantityController.text);
      final status = _statusController.text;
      final imageUrl = _imageUrlController.text.isNotEmpty
          ? _imageUrlController.text
          : null;
      final serialNumber = _serialNumberController.text.isNotEmpty
          ? _serialNumberController.text
          : null;
      final manufacturer = _manufacturerController.text.isNotEmpty
          ? _manufacturerController.text
          : null;
      final model = _modelController.text.isNotEmpty
          ? _modelController.text
          : null;

      // Purchase and maintenance date processing removed for simplification

      final notes = _notesController.text.isNotEmpty
          ? _notesController.text
          : null;

      if (_isEdit) {
        // Update existing equipment using the safer method to avoid schema mismatches
        // Get the equipment ID from the existing equipment object
        final equipmentId = widget.equipment!.id;

        // Add extra diagnostic logging
        Logger.debug(
          '${AppLocalizations.of(context)!.equipmentForm} - ${AppLocalizations.of(context)!.editMode} - ${AppLocalizations.of(context)!.equipmentId}: "$equipmentId"',
        );
        Logger.debug(
          '${AppLocalizations.of(context)!.equipmentForm} - ${AppLocalizations.of(context)!.originalEquipment}: ${widget.equipment.toString()}',
        );

        if (equipmentId.isEmpty) {
          Logger.error(
            '${AppLocalizations.of(context)!.equipmentForm} - ${AppLocalizations.of(context)!.missingOrInvalidEquipmentId}',
          );
          throw Exception(
            '${AppLocalizations.of(context)!.equipmentForm} - ${AppLocalizations.of(context)!.missingOrInvalidEquipmentId}',
          );
        }

        // Verify the equipment exists in the database before updating
        final checkEquipment = await _dataService.getEquipmentById(equipmentId);
        if (checkEquipment == null) {
          Logger.error(
            '${AppLocalizations.of(context)!.equipmentForm} - ${AppLocalizations.of(context)!.equipmentNotFoundInDatabase} ID: $equipmentId',
          );
          throw Exception(
            '${AppLocalizations.of(context)!.equipmentForm} - ${AppLocalizations.of(context)!.equipmentNotFoundInDatabase} ID: $equipmentId',
          );
        } else {
          Logger.debug(
            '${AppLocalizations.of(context)!.equipmentForm} - ${AppLocalizations.of(context)!.confirmedEquipmentExistsInDatabase}: ${checkEquipment.id}',
          );
        }

        // Use the safe update method to avoid schema issues
        Logger.debug(
          '${AppLocalizations.of(context)!.equipmentForm} - ${AppLocalizations.of(context)!.callingSafeUpdateEquipment} ID: $equipmentId',
        );
        await _dataService.safeUpdateEquipment(
          equipmentId: equipmentId,
          name: name,
          description: description,
          categoryId:
              _selectedCategoryId, // Use categoryId instead of category string
          quantity: quantity,
          status: status,
          imageUrl: imageUrl,
          notes: notes,
          manufacturer: manufacturer,
          model: model,
          serialNumber: serialNumber,
        );

        // Note: The maintenance dates are temporarily excluded as they may not exist in the DB
        // We can add them back later after confirming the schema

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.equipmentUpdatedSuccessfully,
              ),
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Create new equipment - auto-generate serial number if not provided
        String finalSerialNumber = serialNumber ?? '';

        // Auto-generate serial number if empty and category is selected
        if (finalSerialNumber.isEmpty && _selectedCategoryId != null) {
          finalSerialNumber = SerialGenerator.generateSerialNumber(
            _selectedCategoryId,
          );

          // Update the UI to show the generated serial number
          setState(() {
            _serialNumberController.text = finalSerialNumber;
            _qrCodeController.text = finalSerialNumber;
          });
        }

        // Create new equipment - simplified version without purchase/maintenance fields
        final newEquipment = Equipment(
          id: '', // Will be generated by Supabase
          name: name,
          description: description,
          category: category, // Keep for display compatibility
          quantity: quantity,
          status: status,
          imageUrl: imageUrl,
          qrCode: finalSerialNumber, // QR code = serial number
          serialNumber: finalSerialNumber,
          manufacturer: manufacturer,
          model: model,
          notes: notes,
          createdAt: DateTime.now(),
          categoryId: _selectedCategoryId, // Include categoryId
          categoryName: category, // Include category name for display
        );

        await _dataService.createEquipment(newEquipment);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.newEquipmentCreatedSuccessfully,
              ),
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      final errorMessage =
          '${AppLocalizations.of(context)!.errorSavingEquipment}: $e';
      Logger.error(errorMessage);

      if (mounted) {
        setState(() {
          _errorMessage =
              '${AppLocalizations.of(context)!.error}: ${e.toString()}';
        });

        // Show a more user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSavingEquipment),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.errorDetails,
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.errorDetails),
                    content: SingleChildScrollView(child: Text(errorMessage)),
                    actions: [
                      TextButton(
                        child: Text(AppLocalizations.of(context)!.agree),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadQrCode() async {
    final serialNumber = _serialNumberController.text.trim();
    if (serialNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pleaseEnterSerialNumberFirst,
          ),
        ),
      );
      return;
    }

    try {
      // Generate QR code image
      final imageBytes = await _qrCodeService.generateQrCodeImage(serialNumber);

      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.cannotGenerateQRCode),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Download the image
      await _qrCodeService.downloadQrCode(imageBytes, 'QR_$serialNumber');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.qrCodeDownloadedSuccessfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.errorDownloadingQRCode(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? AppLocalizations.of(context)!.editEquipment
              : AppLocalizations.of(context)!.addNewEquipment,
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveEquipment,
            icon: const Icon(Icons.save),
            label: Text(
              _isLoading
                  ? AppLocalizations.of(context)!.saving
                  : AppLocalizations.of(context)!.save,
            ),
          ),
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    if (_isLoading && !_isEdit) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                margin: const EdgeInsets.only(
                  bottom: AppConstants.paddingMedium,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadiusMedium,
                  ),
                  border: Border.all(
                    color: AppColors.errorRed.withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorRed),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.inter(color: AppColors.errorRed),
                      ),
                    ),
                  ],
                ),
              ),

            // Basic Information Card
            _buildSectionCard(
              title: AppLocalizations.of(context)!.basicInformation,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText:
                        '${AppLocalizations.of(context)!.equipmentName} *',
                    hintText: AppLocalizations.of(context)!.enterEquipmentName,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${AppLocalizations.of(context)!.equipmentName} ${AppLocalizations.of(context)!.isRequired}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: '${AppLocalizations.of(context)!.description} *',
                    hintText: AppLocalizations.of(context)!.enterDescription,
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${AppLocalizations.of(context)!.description} ${AppLocalizations.of(context)!.isRequired}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                _buildCategoryDropdown(),
                const SizedBox(height: AppConstants.paddingMedium),

                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: '${AppLocalizations.of(context)!.quantity} *',
                    hintText: AppLocalizations.of(context)!.enterQuantity,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${AppLocalizations.of(context)!.quantity} ${AppLocalizations.of(context)!.isRequired}';
                    }
                    if (int.tryParse(value) == null) {
                      return AppLocalizations.of(context)!.mustBeValidNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                const SizedBox(height: AppConstants.paddingMedium),

                DropdownButtonFormField<String>(
                  initialValue: _statusController.text,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context)!.status} *',
                  ),
                  items: _statuses
                      .map(
                        (status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status.replaceAll('_', ' ').toLowerCase(),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _statusController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${AppLocalizations.of(context)!.status} ${AppLocalizations.of(context)!.isRequired}';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Details Card
            _buildSectionCard(
              title: AppLocalizations.of(context)!.additionalInformation,
              children: [
                TextFormField(
                  controller: _serialNumberController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: AppLocalizations.of(context)!.serialNumber,
                    hintText: AppLocalizations.of(context)!.enterSerialNumber,
                  ),
                  onChanged: (value) {
                    // Auto-sync QR code with serial number
                    _qrCodeController.text = value;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                TextFormField(
                  controller: _qrCodeController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: AppLocalizations.of(context)!.qrCode,
                    hintText: AppLocalizations.of(context)!.qrCodeHint,
                    enabled: false,
                  ),
                  enabled: false,
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                // QR Code Preview and Download
                if (_serialNumberController.text.isNotEmpty) ...[
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showQrCode = !_showQrCode;
                          });
                        },
                        icon: Icon(
                          _showQrCode ? Icons.visibility_off : Icons.qr_code_2,
                        ),
                        label: Text(
                          _showQrCode
                              ? AppLocalizations.of(context)!.hideQRCode
                              : AppLocalizations.of(context)!.showQRCode,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      if (_showQrCode)
                        ElevatedButton.icon(
                          onPressed: _downloadQrCode,
                          icon: const Icon(Icons.download),
                          label: Text(
                            AppLocalizations.of(context)!.downloadPNG,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                        ),
                    ],
                  ),
                  if (_showQrCode) ...[
                    const SizedBox(height: AppConstants.paddingMedium),
                    Center(
                      child: _qrCodeService.buildQrCodeWidget(
                        _serialNumberController.text,
                        size: 200,
                        showData: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppConstants.paddingMedium),
                ],

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _manufacturerController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: AppLocalizations.of(context)!.manufacturer,
                          hintText: AppLocalizations.of(
                            context,
                          )!.enterManufacturer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: AppLocalizations.of(context)!.model,
                          hintText: AppLocalizations.of(context)!.enterModel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: AppLocalizations.of(context)!.imageUrl,
                    hintText: AppLocalizations.of(context)!.enterImageUrl,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),

                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: AppLocalizations.of(context)!.notes,
                    hintText: AppLocalizations.of(
                      context,
                    )!.enterAdditionalNotes,
                  ),
                  maxLines: 3,
                ),
              ],
            ),

            // Purchase & Maintenance section removed for simplification
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    if (_categoryList.isEmpty) {
      return TextFormField(
        controller: _categoryController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: '${AppLocalizations.of(context)!.category} *',
          hintText: AppLocalizations.of(context)!.enterCategory,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.categoryNameRequired;
          }
          return null;
        },
      );
    }

    // Use dropdown if we have existing categories
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: '${AppLocalizations.of(context)!.category} *',
        hintText: _categoryNames.isEmpty
            ? AppLocalizations.of(context)!.enterCategory
            : AppLocalizations.of(context)!.selectOrEnterCategory,
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _categoryController.clear();
              _selectedCategoryId = null;
            });
          },
        ),
      ),
      items: [
        ..._categoryList.map(
          (cat) => DropdownMenuItem<int>(value: cat.id, child: Text(cat.name)),
        ),
        DropdownMenuItem<int>(
          value: -1, // Special value for "Add new category"
          child: Text(AppLocalizations.of(context)!.addNewCategory),
        ),
      ],
      onChanged: (value) {
        if (value == -1) {
          // Show dialog to enter new category
          _showAddNewDialog(
            context: context,
            title: AppLocalizations.of(context)!.addNewCategory,
            label: AppLocalizations.of(context)!.categoryName,
            controller: _categoryController,
            onComplete: (String categoryName) async {
              // Create new category
              final newCategory = await _metadataService.createCategory(
                categoryName,
              );
              if (newCategory != null) {
                setState(() {
                  _categoryList.add(newCategory);
                  _categoryNames.add(newCategory.name);
                  _selectedCategoryId = newCategory.id;
                  _categoryController.text = newCategory.name;
                });
              }
            },
          );
        } else if (value != null) {
          final selectedCategory = _categoryList.firstWhere(
            (cat) => cat.id == value,
          );
          setState(() {
            _selectedCategoryId = value;
            _categoryController.text = selectedCategory.name;
          });
        }
      },
      validator: (value) {
        final text = _categoryController.text;
        if (text.isEmpty) {
          return AppLocalizations.of(context)!.categoryNameRequired;
        }
        return null;
      },
    );
  }

  Future<void> _showAddNewDialog({
    required BuildContext context,
    required String title,
    required String label,
    required TextEditingController controller,
    Function(String value)? onComplete,
  }) async {
    final textController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            labelText: label,
            hintText: AppLocalizations.of(context)!.enterNewCategory,
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = textController.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  controller.text = value;
                });
                Navigator.of(dialogContext).pop();

                // Call onComplete callback if provided
                if (onComplete != null) {
                  onComplete(value);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
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
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
