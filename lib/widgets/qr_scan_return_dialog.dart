import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/borrow_request.dart';
import '../constants/app_colors.dart';

/// Dialog for returning equipment with QR code scanning
/// Supports continuous scan mode - keeps scanning until user clicks Done
class QRScanReturnDialog extends StatefulWidget {
  final String requestSerial;
  final List<BorrowRequest> requests;

  const QRScanReturnDialog({
    super.key,
    required this.requestSerial,
    required this.requests,
  });

  @override
  State<QRScanReturnDialog> createState() => _QRScanReturnDialogState();
}

class _QRScanReturnDialogState extends State<QRScanReturnDialog> {
  final Map<String, bool> _selectedEquipment = {};
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;
  String? _lastScannedSerial;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    // Initialize all equipment as not selected
    for (final request in widget.requests) {
      if (!request.isEquipmentReturned) {
        _selectedEquipment[request.id] = false;
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _toggleSelection(String requestId) {
    setState(() {
      _selectedEquipment[requestId] = !(_selectedEquipment[requestId] ?? false);
    });
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _lastScannedSerial = null;
    });
  }

  void _stopScanning() {
    setState(() {
      _isScanning = false;
    });
  }

  void _handleBarcodeScan(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final scannedSerial = barcodes.first.rawValue;
    if (scannedSerial == null || scannedSerial.isEmpty) return;

    // Prevent duplicate scans within 2 seconds
    final now = DateTime.now();
    if (_lastScannedSerial == scannedSerial &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 2) {
      return;
    }

    _lastScannedSerial = scannedSerial;
    _lastScanTime = now;

    // Find matching equipment
    bool found = false;
    for (final request in widget.requests) {
      if (request.isEquipmentReturned) continue;

      // Extract serial from QR (format: XXYYYY where XX is category, YYYY is number)
      final equipmentSerial = _extractSerialFromEquipment(request);
      
      if (equipmentSerial == scannedSerial) {
        setState(() {
          _selectedEquipment[request.id] = true;
        });
        found = true;
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${request.equipmentName} marked for return'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
      }
    }

    if (!found && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Equipment not found in this request: $scannedSerial'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _extractSerialFromEquipment(BorrowRequest request) {
    // Return the equipment serial number from the request
    // This matches the serial number on the equipment's QR code
    return request.equipmentSerialNumber ?? '';
  }

  int get _selectedCount => _selectedEquipment.values.where((v) => v).length;
  int get _totalCount => _selectedEquipment.length;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_return, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Return Equipment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Request #${widget.requestSerial}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Scanner Area (shown when scanning)
            if (_isScanning)
              Container(
                height: 250,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryBlue, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleBarcodeScan,
                    ),
                    // Scan overlay
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Stop Scanning Button
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: _stopScanning,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Scanning'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Equipment List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Selection Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedCount == _totalCount
                              ? Icons.check_circle
                              : _selectedCount > 0
                                  ? Icons.check_circle_outline
                                  : Icons.radio_button_unchecked,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Selected: $_selectedCount / $_totalCount equipment',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Equipment Items
                  ...widget.requests.map((request) => _buildEquipmentItem(request)),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Scan Button
                  if (!_isScanning)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _startScanning,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Confirm Return Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _selectedCount > 0
                              ? () {
                                  final selectedIds = _selectedEquipment.entries
                                      .where((e) => e.value)
                                      .map((e) => e.key)
                                      .toList();
                                  Navigator.of(context).pop(selectedIds);
                                }
                              : null,
                          icon: const Icon(Icons.check),
                          label: Text('Confirm Return ($_selectedCount)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentItem(BorrowRequest request) {
    if (request.isEquipmentReturned) {
      // Already returned - show as disabled
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.equipmentName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Qty: ${request.quantity} - Already Returned',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isSelected = _selectedEquipment[request.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => _toggleSelection(request.id),
        title: Text(
          request.equipmentName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Quantity: ${request.quantity}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medical_services,
            size: 20,
            color: isSelected ? AppColors.primaryBlue : Colors.grey,
          ),
        ),
        activeColor: AppColors.primaryBlue,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
