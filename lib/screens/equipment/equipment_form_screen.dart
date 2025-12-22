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

class EquipmentFormScreen extends StatefulWidget {
  final Equipment? equipment; // Null for create, non-null for edit
  
  const EquipmentFormScreen({
    super.key, 
    this.equipment,
  });

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
  late TextEditingController _quantityController;  // Updated field name
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
  
  final List<String> _statuses = ['available', 'borrowed', 'maintenance', 'out_of_order'];
  
  @override
  void initState() {
    super.initState();
    _isEdit = widget.equipment != null;
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.equipment?.name ?? '');
    _descriptionController = TextEditingController(text: widget.equipment?.description ?? '');
    _categoryController = TextEditingController(text: widget.equipment?.category ?? '');
    _quantityController = TextEditingController(
      text: widget.equipment?.quantity.toString() ?? '0');
    _statusController = TextEditingController(text: widget.equipment?.status ?? 'available');
    
    // Load categories
    _loadCategories();
    _imageUrlController = TextEditingController(text: widget.equipment?.imageUrl ?? '');
    _qrCodeController = TextEditingController(text: widget.equipment?.qrCode ?? '');
    _serialNumberController = TextEditingController(text: widget.equipment?.serialNumber ?? '');
    _manufacturerController = TextEditingController(text: widget.equipment?.manufacturer ?? '');
    _modelController = TextEditingController(text: widget.equipment?.model ?? '');
    // Purchase and maintenance field controllers removed for simplification
    _notesController = TextEditingController(text: widget.equipment?.notes ?? '');
    
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
          if (widget.equipment != null && widget.equipment!.categoryId != null) {
            _selectedCategoryId = widget.equipment!.categoryId;
          } else if (widget.equipment != null && widget.equipment!.category?.isNotEmpty == true) {
            // Try to find a category by name for backward compatibility
            final matchingCategory = categoryList.firstWhere(
              (cat) => cat.name.toLowerCase() == widget.equipment!.category?.toLowerCase(),
              orElse: () => Category(id: -1, name: '', createdAt: DateTime.now()),
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
      Logger.error('Error loading categories: $e');
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
      final category = _categoryController.text; // Keep for display purposes only
      final quantity = int.parse(_quantityController.text);
      final status = _statusController.text;
      final imageUrl = _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null;
      final serialNumber = _serialNumberController.text.isNotEmpty ? _serialNumberController.text : null;
      final manufacturer = _manufacturerController.text.isNotEmpty ? _manufacturerController.text : null;
      final model = _modelController.text.isNotEmpty ? _modelController.text : null;
      
      // Purchase and maintenance date processing removed for simplification
      
      final notes = _notesController.text.isNotEmpty ? _notesController.text : null;
      
      if (_isEdit) {
        // Update existing equipment using the safer method to avoid schema mismatches
        // Get the equipment ID from the existing equipment object
        final equipmentId = widget.equipment!.id;
        
        // Add extra diagnostic logging
        Logger.debug('Equipment form - Edit mode - Equipment ID: "$equipmentId"');
        Logger.debug('Equipment form - Original equipment: ${widget.equipment.toString()}');
        
        if (equipmentId.isEmpty) {
          Logger.error('Equipment form - Empty equipment ID in edit mode');
          throw Exception('Equipment ID is missing or invalid');
        }
        
        // Verify the equipment exists in the database before updating
        final checkEquipment = await _dataService.getEquipmentById(equipmentId);
        if (checkEquipment == null) {
          Logger.error('Equipment form - Equipment not found in database: $equipmentId');
          throw Exception('Equipment not found in database with ID: $equipmentId');
        } else {
          Logger.debug('Equipment form - Verified equipment exists in database: ${checkEquipment.id}');
        }
        
        // Use the safe update method to avoid schema issues
        Logger.debug('Equipment form - Calling safeUpdateEquipment with ID: $equipmentId');
        await _dataService.safeUpdateEquipment(
          equipmentId: equipmentId,
          name: name,
          description: description,
          categoryId: _selectedCategoryId, // Use categoryId instead of category string
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
            const SnackBar(content: Text('Equipment updated successfully')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // Create new equipment - auto-generate serial number if not provided
        String finalSerialNumber = serialNumber ?? '';
        
        // Auto-generate serial number if empty and category is selected
        if (finalSerialNumber.isEmpty && _selectedCategoryId != null) {
          final categoryName = _categoryList.firstWhere(
            (cat) => cat.id == _selectedCategoryId,
            orElse: () => _categoryList.first,
          ).name;
          
          finalSerialNumber = SerialGenerator.generateSerialNumber(categoryName);
          
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
            const SnackBar(content: Text('Equipment created successfully')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      final errorMessage = 'Error saving equipment: $e';
      Logger.error(errorMessage);
      
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
        
        // Show a more user-friendly error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save equipment. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DETAILS',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: Text(errorMessage),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
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
        const SnackBar(content: Text('Please enter a serial number first')),
      );
      return;
    }

    try {
      // Generate QR code image
      final imageBytes = await _qrCodeService.generateQrCodeImage(serialNumber);
      
      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate QR code'),
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
          const SnackBar(
            content: Text('QR code downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading QR code: $e'),
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
        title: Text(_isEdit ? 'Edit Equipment' : 'Add New Equipment'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveEquipment,
            icon: const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save'),
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
                margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  border: Border.all(color: AppColors.errorRed.withAlpha((0.3 * 255).round())),
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
              title: 'Basic Information',
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Equipment Name *',
                    hintText: 'Enter the equipment name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Equipment name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Enter the equipment description',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                _buildCategoryDropdown(),
                const SizedBox(height: AppConstants.paddingMedium),
                
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity *',
                    hintText: 'Enter number of units',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Quantity is required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Must be a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                const SizedBox(height: AppConstants.paddingMedium),
                
                DropdownButtonFormField<String>(
                  initialValue: _statusController.text,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                  ),
                  items: _statuses.map((status) => DropdownMenuItem<String>(
                    value: status,
                    child: Text(status.replaceAll('_', ' ').toLowerCase()),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _statusController.text = value;
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Status is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            // Details Card
            _buildSectionCard(
              title: 'Additional Details',
              children: [
                TextFormField(
                  controller: _serialNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    hintText: 'Enter serial number (optional)',
                  ),
                  onChanged: (value) {
                    // Auto-sync QR code with serial number
                    _qrCodeController.text = value;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                TextFormField(
                  controller: _qrCodeController,
                  decoration: const InputDecoration(
                    labelText: 'QR/Barcode',
                    hintText: 'Same as Serial Number (auto-filled)',
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
                        icon: Icon(_showQrCode ? Icons.visibility_off : Icons.qr_code_2),
                        label: Text(_showQrCode ? 'Hide QR Code' : 'Show QR Code'),
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
                          label: const Text('Download PNG'),
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
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer',
                          hintText: 'Enter manufacturer name',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          hintText: 'Enter model number',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'Enter URL to equipment image',
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Enter any additional notes',
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
        decoration: const InputDecoration(
          labelText: 'Category *',
          hintText: 'Enter equipment category',
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Category is required';
          }
          return null;
        },
      );
    }
    
    // Use dropdown if we have existing categories
    return DropdownButtonFormField<int>(
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'Category *',
        hintText: _categoryNames.isEmpty ? 'Enter category' : 'Select or enter category',
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
        ..._categoryList.map((cat) => DropdownMenuItem<int>(
          value: cat.id,
          child: Text(cat.name),
        )),
        const DropdownMenuItem<int>(
          value: -1, // Special value for "Add new category"
          child: Text('+ Add new category'),
        ),
      ],
      onChanged: (value) {
        if (value == -1) {
          // Show dialog to enter new category
          _showAddNewDialog(
            context: context,
            title: 'Add New Category',
            label: 'Category Name',
            controller: _categoryController,
            onComplete: (String categoryName) async {
              // Create new category
              final newCategory = await _metadataService.createCategory(categoryName);
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
          final selectedCategory = _categoryList.firstWhere((cat) => cat.id == value);
          setState(() {
            _selectedCategoryId = value;
            _categoryController.text = selectedCategory.name;
          });
        }
      },
      validator: (value) {
        final text = _categoryController.text;
        if (text.isEmpty) {
          return 'Category is required';
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
            hintText: 'Enter new $label',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
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
            child: const Text('Add'),
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