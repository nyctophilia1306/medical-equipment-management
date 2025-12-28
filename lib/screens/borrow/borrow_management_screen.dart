import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../constants/constants.dart';
import '../../models/equipment.dart';
import '../../services/borrow_service.dart';
import '../../services/data_service.dart';
import '../../widgets/equipment_card.dart';
import '../../widgets/continuous_scan_popup.dart';
import 'borrow_list_tab.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BorrowManagementScreen extends StatefulWidget {
  const BorrowManagementScreen({super.key});

  @override
  State<BorrowManagementScreen> createState() => _BorrowManagementScreenState();
}

class _BorrowManagementScreenState extends State<BorrowManagementScreen>
    with TickerProviderStateMixin {
  final BorrowService _borrowService = BorrowService();
  final DataService _dataService = DataService();

  late final TabController _tabController;
  final _serialController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isNewUser = true;
  String? _selectedExistingUserName;
  String? _selectedExistingUserId;
  DateTime? _userDob;
  String? _selectedGender;
  DateTime? _borrowDate;
  DateTime? _returnDate;
  bool _loading = false;
  String? _message;

  final Map<String, Equipment> _scannedEquipment = <String, Equipment>{};
  final Map<String, int> _borrowQuantities = <String, int>{};
  
  bool _isContinuousScanning = false;
  String? _lastScannedSerial;
  DateTime? _lastScanTime;
  MobileScannerController? _scannerController;
  AnimationController? _scanLineController;
  Animation<double>? _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isBorrow) async {
    final now = DateTime.now();
    final initial = isBorrow ? (_borrowDate ?? now) : (_returnDate ?? now.add(const Duration(days: 7)));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        if (isBorrow) {
          _borrowDate = picked;
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  void _startContinuousScan() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    
    // Create scan line animation
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _scanLineAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController!, curve: Curves.easeInOut),
    );
    
    setState(() {
      _isContinuousScanning = true;
      _message = null;
    });
  }

  void _stopContinuousScan() {
    _scannerController?.dispose();
    _scannerController = null;
    _scanLineController?.dispose();
    _scanLineController = null;
    _scanLineAnimation = null;
    
    setState(() {
      _isContinuousScanning = false;
      _lastScannedSerial = null;
      _lastScanTime = null;
    });
  }

  Future<void> _handleContinuousScan(String scannedCode) async {
    // Prevent duplicate scans within 1 second
    final now = DateTime.now();
    if (_lastScannedSerial == scannedCode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 1) {
      return;
    }

    _lastScannedSerial = scannedCode;
    _lastScanTime = now;

    try {
      final equipment = await _dataService.getEquipmentByQrCode(scannedCode) ??
          await _dataService.getEquipmentBySerialNumber(scannedCode);

      if (equipment == null) {
        // Error haptic feedback
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('No equipment found: $scannedCode'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.4,
                left: 16,
                right: 16,
              ),
            ),
          );
        }
        return;
      }

      if (equipment.availableQty <= 0) {
        // Warning haptic feedback
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.block, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${equipment.name} is not available'),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.4,
                left: 16,
                right: 16,
              ),
            ),
          );
        }
        return;
      }

      // Haptic feedback for successful scan
      HapticFeedback.mediumImpact();
      
      setState(() {
        if (_scannedEquipment.containsKey(scannedCode)) {
          // Increment quantity for duplicate scan
          final currentQty = _borrowQuantities[scannedCode] ?? 1;
          final maxQty = equipment.availableQty;
          if (currentQty < maxQty) {
            _borrowQuantities[scannedCode] = currentQty + 1;
            
            // Show success snackbar for quantity increment
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('${equipment.name} quantity: $currentQty → ${currentQty + 1}'),
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 800),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.4,
                    left: 16,
                    right: 16,
                  ),
                ),
              );
            }
          } else {
            // Light haptic for max reached
            HapticFeedback.lightImpact();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Maximum quantity reached for ${equipment.name}'),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.4,
                    left: 16,
                    right: 16,
                  ),
                ),
              );
            }
          }
        } else {
          // Add new equipment
          _scannedEquipment[scannedCode] = equipment;
          _borrowQuantities[scannedCode] = 1;
          
          // Show success snackbar for new equipment
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('✓ ${equipment.name} added'),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 800),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.4,
                  left: 16,
                  right: 16,
                ),
              ),
            );
          }
        }
      });
    } catch (e) {
      // Error haptic feedback
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error scanning: $e'),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height * 0.4,
              left: 16,
              right: 16,
            ),
          ),
        );
      }
    }
  }

  Future<void> _addSerialFromInput() async {
    final s = _serialController.text.trim();
    if (s.isEmpty) {
      setState(() => _message = 'Please enter or scan a serial number');
      return;
    }

    setState(() => _loading = true);

    try {
      final equipment = await _dataService.getEquipmentByQrCode(s) ?? 
          await _dataService.getEquipmentBySerialNumber(s);

      setState(() => _loading = false);

      if (equipment == null) {
        setState(() => _message = 'No equipment found with QR code or serial number: $s');
        return;
      }

      if (equipment.availableQty <= 0) {
        setState(() => _message = 'Equipment ${equipment.name} is not available for borrowing');
        return;
      }

      setState(() {
        _scannedEquipment[s] = equipment;
        _borrowQuantities[s] = 1;
        _serialController.clear();
        _message = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _message = 'Error looking up equipment: $e';
      });
    }
  }

  Future<void> _saveRequest() async {
    if ((_isNewUser &&
            (_fullNameController.text.trim().isEmpty ||
                _userDob == null ||
                _selectedGender == null)) ||
        _scannedEquipment.isEmpty ||
        _borrowDate == null ||
        _returnDate == null) {
      setState(() => _message =
          'Please fill required info, dates and scan at least one equipment');
      return;
    }

    for (final entry in _scannedEquipment.entries) {
      final equipment = entry.value;
      final borrowQty = _borrowQuantities[entry.key] ?? 0;
      if (borrowQty <= 0 || borrowQty > equipment.availableQty) {
        setState(() => _message = 'Invalid borrow quantity for ${equipment.name}');
        return;
      }
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    late String userId;
    if (_isNewUser) {
      final newUserId = await _borrowService.createUser(
        userName: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        dob: _userDob!,
        gender: _selectedGender!,
      );
      if (newUserId == null) {
        setState(() {
          _loading = false;
          _message = 'Failed to create user';
        });
        return;
      }
      userId = newUserId;
    } else {
      if (_selectedExistingUserId == null) {
        setState(() {
          _loading = false;
          _message = 'Please select an existing user';
        });
        return;
      }
      userId = _selectedExistingUserId!;
    }

    // Use bulk create for all equipment (generates single request serial)
    // Extract equipment UUIDs (not serials) from the scanned equipment map
    final equipmentIds = _scannedEquipment.values.map((e) => e.id).toList();
    final quantities = _scannedEquipment.keys.map((serial) => _borrowQuantities[serial] ?? 1).toList();

    final requestSerial = await _borrowService.createBulkBorrowRequest(
      userId: userId,
      equipmentIds: equipmentIds,
      quantities: quantities,
      requestDate: _borrowDate!,
      returnDate: _returnDate!,
    );

    final success = requestSerial != null;

    setState(() {
      _loading = false;
      _message = success 
          ? 'Borrow request saved successfully! Request #$requestSerial' 
          : 'Failed to save borrow request';
    });

    if (success) {
      setState(() {
        _scannedEquipment.clear();
        _borrowQuantities.clear();
        _fullNameController.clear();
        _phoneController.clear();
        _borrowDate = null;
        _returnDate = null;
        _selectedExistingUserName = null;
        _selectedExistingUserId = null;
      });
    }
  }

  String _formatDate(DateTime? d) => d == null ? '-' : DateFormat.yMMMd().format(d);

  Widget _buildNewUserForm() {
    return Column(
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            hintText: 'Enter your full name',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            hintText: 'Enter phone number',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _userDob ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _userDob = picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date of Birth *',
              hintText: 'Select your date of birth',
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _userDob == null
                      ? 'Select date'
                      : DateFormat('yyyy-MM-dd').format(_userDob!),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender *',
            hintText: 'Select your gender',
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
      ],
    );
  }

  Widget _buildExistingUserForm() {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search user by name',
          ),
          onSubmitted: (q) async {
            final results = await _borrowService.findUsers(q);
            if (results.isNotEmpty) {
              final user = results.first;
              setState(() {
                _selectedExistingUserName = user['full_name'];
                _selectedExistingUserId = user['user_id'];
                _fullNameController.text = user['full_name'] ?? '';
                _phoneController.text = user['phone'] ?? '';
                if (user['dob'] != null) {
                  _userDob = DateTime.parse(user['dob']);
                }
                _selectedGender = user['gender'];
              });
            }
          },
        ),
        if (_selectedExistingUserName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Selected: $_selectedExistingUserName'),
          ),
      ],
    );
  }

  Widget _buildDatePickers() {
    return Row(
      children: [
        Expanded(
          child: Text('Borrow date: ${_formatDate(_borrowDate)}'),
        ),
        TextButton(
          onPressed: () => _pickDate(context, true),
          child: const Text('Pick'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Return date: ${_formatDate(_returnDate)}'),
        ),
        TextButton(
          onPressed: () => _pickDate(context, false),
          child: const Text('Pick'),
        ),
      ],
    );
  }

  Widget _buildScannedEquipment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scan and manual input row
        Row(
          children: [
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event.logicalKey.keyLabel == 'Enter') {
                    _addSerialFromInput();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _serialController,
                  decoration: const InputDecoration(
                    hintText: 'Enter serial number',
                    prefixIcon: Icon(Icons.edit),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (value.length > 8) {
                      Future.delayed(
                        const Duration(milliseconds: 100),
                        () {
                          if (_serialController.text == value) {
                            _addSerialFromInput();
                          }
                        },
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _startContinuousScan,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _addSerialFromInput,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('Thêm'),
              ),
            ),
          ],
        ),
        if (_scannedEquipment.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Chưa có thiết bị nào được quét'),
          ),
        const SizedBox(height: 16),
        _scannedEquipment.isNotEmpty
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: [
                      for (final entry in _scannedEquipment.entries)
                        SizedBox(
                          width: cardWidth,
                          child: EquipmentCard(
                            equipment: entry.value,
                            quantity: _borrowQuantities[entry.key] ?? 1,
                            onQuantityChanged: (value) {
                              setState(() {
                                _borrowQuantities[entry.key] = value;
                              });
                            },
                            onDelete: () {
                              setState(() {
                                _scannedEquipment.remove(entry.key);
                                _borrowQuantities.remove(entry.key);
                              });
                            },
                          ),
                        ),
                    ],
                  );
                },
              )
            : const SizedBox(),
      ],
    );
  }

  Widget _buildCreateRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Borrower',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: _isNewUser,
                onChanged: (v) => setState(() => _isNewUser = v),
              ),
              Text(_isNewUser ? 'New' : 'Existing'),
            ],
          ),
          const SizedBox(height: 8),
          if (_isNewUser) _buildNewUserForm() else _buildExistingUserForm(),
          const SizedBox(height: 16),
          _buildDatePickers(),
          const Divider(),
          Text(
            'Scanned equipment (by QR/serial)',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildScannedEquipment(),
          const SizedBox(height: 16),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _message!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Row(
            children: [
              ElevatedButton(
                onPressed: _loading ? null : _saveRequest,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Save Request'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => setState(() {
                  _scannedEquipment.clear();
                  _borrowQuantities.clear();
                  _message = null;
                }),
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousScanOverlay() {
    return GestureDetector(
      onTap: () {}, // Prevent taps from going through
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Column(
          children: [
            // QR Scanner (top 65%)
            Expanded(
              flex: 65,
              child: Stack(
                children: [
                  if (_scannerController != null)
                    MobileScanner(
                      controller: _scannerController!,
                      onDetect: (capture) {
                        final barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final code = barcodes.first.rawValue;
                          if (code != null && code.isNotEmpty) {
                            _handleContinuousScan(code);
                          }
                        }
                      },
                    ),
                  // Scan frame overlay with animated scan line
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Corner indicators
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white, width: 4),
                                  left: BorderSide(color: Colors.white, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.white, width: 4),
                                  right: BorderSide(color: Colors.white, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white, width: 4),
                                  left: BorderSide(color: Colors.white, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.white, width: 4),
                                  right: BorderSide(color: Colors.white, width: 4),
                                ),
                              ),
                            ),
                          ),
                          // Animated scan line
                          if (_scanLineAnimation != null)
                            AnimatedBuilder(
                              animation: _scanLineAnimation!,
                              builder: (context, child) {
                                return Positioned(
                                  top: _scanLineAnimation!.value * 230,
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.green.withValues(alpha: 0.8),
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          // Center text
                          const Center(
                            child: Text(
                              'Position QR code here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Top instruction bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        children: [
                          Text(
                            'Continuous Scan Mode',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan multiple equipment - stops when you click Stop',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Flashlight toggle button
                  Positioned(
                    top: 100,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                      onPressed: () {
                        _scannerController?.toggleTorch();
                      },
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Equipment popup (bottom 35%)
            Expanded(
              flex: 35,
              child: ContinuousScanPopup(
                scannedEquipment: _scannedEquipment,
                quantities: _borrowQuantities,
                onStop: _stopContinuousScan,
                onRemove: (serial) {
                  setState(() {
                    _scannedEquipment.remove(serial);
                    _borrowQuantities.remove(serial);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                height: 60,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Create Request',),
                    Tab(text: 'Manage Requests',),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCreateRequestTab(),
                    const BorrowListTab(),
                  ],
                ),
              ),
            ],
          ),
          // Continuous scan overlay
          if (_isContinuousScanning)
            _buildContinuousScanOverlay(),
        ],
      ),
    );
  }
}